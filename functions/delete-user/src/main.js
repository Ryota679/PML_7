import { Client, Databases, Users, Query } from 'node-appwrite';

/**
 * Appwrite Function: Delete User (Enhanced with Multi-Level Cascading)
 * 
 * This function handles complete user deletion with comprehensive cascading cleanup.
 * 
 * Authorization:
 *   - Business Owner can delete Tenant
 *   - Tenant can delete Staff (sub_role=staff)
 *   - Admin can delete anyone
 */

export default async ({ req, res, log, error }) => {
    const client = new Client()
        .setEndpoint(process.env.APPWRITE_FUNCTION_ENDPOINT || 'https://fra.cloud.appwrite.io/v1')
        .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID || '')
        .setKey(process.env.APPWRITE_FUNCTION_API_KEY || '');

    const databases = new Databases(client);
    const users = new Users(client);

    const databaseId = process.env.DATABASE_ID || 'kantin-db';
    const usersCollectionId = process.env.USERS_COLLECTION_ID || 'users';
    const productsCollectionId = process.env.PRODUCTS_COLLECTION_ID || 'products';
    const ordersCollectionId = process.env.ORDERS_COLLECTION_ID || 'orders';

    try {
        const body = JSON.parse(req.body || '{}');
        const { userId, force = false, deletedBy } = body;

        if (!userId) {
            return res.json({
                success: false,
                error: 'Missing required field: userId'
            }, 400);
        }

        log(`🔵 Starting user deletion for userId: ${userId}`);
        if (deletedBy) {
            log(`👤 Deletion requested by: ${deletedBy}`);
        }

        // Get user document
        let userDoc;
        try {
            userDoc = await databases.getDocument(databaseId, usersCollectionId, userId);
        } catch (err) {
            return res.json({
                success: false,
                error: 'User not found in database',
                code: 'USER_NOT_FOUND'
            }, 404);
        }

        const authUserId = userDoc.user_id;
        const userRole = userDoc.role;
        const userSubRole = userDoc.sub_role;
        const tenantId = userDoc.tenant_id;

        log(`📋 User info: role=${userRole}, sub_role=${userSubRole || 'null'}, auth_user_id=${authUserId}, tenant_id=${tenantId || 'null'}`);

        // Authorization check (skip for cleanup function)
        if (deletedBy) {
            log('🔒 Checking authorization...');

            const deletedByResponse = await databases.listDocuments(
                databaseId,
                usersCollectionId,
                [Query.equal('user_id', deletedBy)]
            );

            if (deletedByResponse.documents.length === 0) {
                error('DeletedBy user not found');
                return res.json({
                    success: false,
                    error: 'Unauthorized: User performing deletion not found'
                }, 403);
            }

            const deletedByDoc = deletedByResponse.documents[0];
            const deletedByRole = deletedByDoc.role;
            const deletedByTenantId = deletedByDoc.tenant_id;

            log(`👤 DeletedBy info: role=${deletedByRole}, tenant_id=${deletedByTenantId || 'null'}`);

            let authorized = false;

            // Check if user is staff (sub_role=staff)
            if (userSubRole === 'staff') {
                // Staff can be deleted by their tenant manager
                if (deletedByRole === 'tenant' && deletedByTenantId === tenantId) {
                    authorized = true;
                    log('✅ Authorization: Tenant can delete their staff');
                } else if (deletedByRole === 'adminsystem') {
                    authorized = true;
                    log('✅ Authorization: Admin can delete anyone');
                } else {
                    log('❌ Authorization failed: Only owning tenant can delete staff');
                }
            } else {
                // Original logic for other roles
                switch (userRole) {
                    case 'tenant':
                        if (deletedByRole === 'owner_bussines' || deletedByRole === 'owner_business' || deletedByRole === 'adminsystem') {
                            authorized = true;
                            log('✅ Authorization: Business owner/admin can delete tenant');
                        } else {
                            log('❌ Authorization failed: Only business owner can delete tenant');
                        }
                        break;
                    case 'customer':
                        if ((deletedByRole === 'tenant' && deletedByTenantId === tenantId) || deletedByRole === 'adminsystem') {
                            authorized = true;
                            log('✅ Authorization: Tenant/admin can delete customer');
                        } else {
                            log('❌ Authorization failed: Only owning tenant can delete customer');
                        }
                        break;
                    case 'owner_bussines':
                    case 'owner_business':
                        if (deletedByRole === 'adminsystem') {
                            authorized = true;
                            log('✅ Authorization: Admin can delete business owner');
                        } else {
                            log('❌ Authorization failed: Only admin can delete business owner');
                        }
                        break;
                    case 'adminsystem':
                        error('Cannot delete admin');
                        return res.json({
                            success: false,
                            error: 'Cannot delete system administrator'
                        }, 403);
                    default:
                        log('⚠️ Unknown role');
                        authorized = false;
                }
            }

            if (!authorized) {
                error('Unauthorized delete attempt');
                return res.json({
                    success: false,
                    error: 'Unauthorized: You do not have permission to delete this user'
                }, 403);
            }
        }

        // Cascading delete
        const deletedData = {
            products: 0,
            orders: 0,
            tenants: 0,
            staff: 0
        };

        // TENANT DELETION (only for actual tenant managers, not staff)
        if (userRole === 'tenant' && tenantId && userSubRole !== 'staff') {
            log('🗑️  TENANT deletion - cascading delete all related data...');

            // Delete all STAFF
            try {
                const staffResponse = await databases.listDocuments(
                    databaseId,
                    usersCollectionId,
                    [
                        Query.equal('tenant_id', tenantId),
                        Query.notEqual('$id', userId) // Exclude self from staff list to avoid double deletion
                    ]
                );

                for (const staffUser of staffResponse.documents) {
                    try {
                        if (staffUser.user_id) {
                            try {
                                await users.delete(staffUser.user_id);
                            } catch (e) {
                                if (!(e.code === 404 || e.message?.includes('could not be found'))) {
                                    throw e;
                                }
                            }
                        }
                        await databases.deleteDocument(databaseId, usersCollectionId, staffUser.$id);
                        deletedData.staff++;
                    } catch (e) {
                        error(`Failed to delete staff: ${e.message}`);
                    }
                }
                log(`  ✅ Deleted ${deletedData.staff} staff`);
            } catch (e) {
                error(`Failed to delete staff: ${e.message}`);
            }

            // Delete PRODUCTS
            try {
                const productsResponse = await databases.listDocuments(
                    databaseId,
                    productsCollectionId,
                    [Query.equal('tenant_id', tenantId)]
                );

                for (const product of productsResponse.documents) {
                    await databases.deleteDocument(databaseId, productsCollectionId, product.$id);
                    deletedData.products++;
                }
                log(`  ✅ Deleted ${deletedData.products} products`);
            } catch (e) {
                error(`Failed to delete products: ${e.message}`);
            }

            // Delete ORDERS
            try {
                const ordersResponse = await databases.listDocuments(
                    databaseId,
                    ordersCollectionId,
                    [Query.equal('tenant_id', tenantId)]
                );

                for (const order of ordersResponse.documents) {
                    await databases.deleteDocument(databaseId, ordersCollectionId, order.$id);
                    deletedData.orders++;
                }
                log(`  ✅ Deleted ${deletedData.orders} orders`);
            } catch (e) {
                error(`Failed to delete orders: ${e.message}`);
            }
        }

        // BUSINESS OWNER DELETION
        if (userRole === 'owner_bussines' || userRole === 'owner_business') {
            log('🏢 BUSINESS OWNER deletion - cascading delete ALL tenants and their data...');

            try {
                const tenantsResponse = await databases.listDocuments(
                    databaseId,
                    usersCollectionId,
                    [
                        Query.equal('role', 'tenant'),
                        Query.equal('created_by', authUserId)
                    ]
                );

                if (tenantsResponse.documents.length > 0 && !force && deletedBy) {
                    return res.json({
                        success: false,
                        error: 'Cannot delete business owner with active tenants (use force=true)',
                        code: 'HAS_ACTIVE_TENANTS',
                        data: { tenantCount: tenantsResponse.documents.length }
                    }, 400);
                }

                log(`  Found ${tenantsResponse.documents.length} tenants to delete`);

                for (const tenant of tenantsResponse.documents) {
                    const tId = tenant.tenant_id;
                    const tAuthId = tenant.user_id;

                    log(`\n  📦 Deleting tenant: ${tenant.username}`);

                    // Delete tenant's STAFF
                    try {
                        const staffResponse = await databases.listDocuments(
                            databaseId,
                            usersCollectionId,
                            [Query.equal('tenant_id', tId)]
                        );

                        for (const staffUser of staffResponse.documents) {
                            try {
                                if (staffUser.user_id) {
                                    try {
                                        await users.delete(staffUser.user_id);
                                    } catch (e) {
                                        if (!(e.code === 404 || e.message?.includes('could not be found'))) {
                                            throw e;
                                        }
                                    }
                                }
                                await databases.deleteDocument(databaseId, usersCollectionId, staffUser.$id);
                                deletedData.staff++;
                            } catch (e) { }
                        }
                        log(`    ✅ Deleted ${staffResponse.documents.length} staff`);
                    } catch (e) { }

                    // Delete tenant's PRODUCTS
                    try {
                        const productsResponse = await databases.listDocuments(
                            databaseId,
                            productsCollectionId,
                            [Query.equal('tenant_id', tId)]
                        );

                        for (const product of productsResponse.documents) {
                            await databases.deleteDocument(databaseId, productsCollectionId, product.$id);
                            deletedData.products++;
                        }
                        log(`    ✅ Deleted ${productsResponse.documents.length} products`);
                    } catch (e) { }

                    // Delete tenant's ORDERS
                    try {
                        const ordersResponse = await databases.listDocuments(
                            databaseId,
                            ordersCollectionId,
                            [Query.equal('tenant_id', tId)]
                        );

                        for (const order of ordersResponse.documents) {
                            await databases.deleteDocument(databaseId, ordersCollectionId, order.$id);
                            deletedData.orders++;
                        }
                        log(`    ✅ Deleted ${ordersResponse.documents.length} orders`);
                    } catch (e) { }

                    // Delete tenant AUTH
                    if (tAuthId) {
                        try {
                            await users.delete(tAuthId);
                        } catch (e) {
                            if (!(e.code === 404 || e.message?.includes('could not be found'))) {
                                error(`Failed to delete tenant Auth: ${e.message}`);
                            }
                        }
                    }

                    // Delete tenant DOCUMENT
                    await databases.deleteDocument(databaseId, usersCollectionId, tenant.$id);
                    deletedData.tenants++;
                }

                log(`\n  ✅ Deleted ${deletedData.tenants} tenants total`);
            } catch (e) {
                error(`Failed to delete business owner tenants: ${e.message}`);
            }
        }

        // Delete main user DOCUMENT
        log('🗑️  Deleting user document from database...');
        await databases.deleteDocument(databaseId, usersCollectionId, userId);
        log('✅ User document deleted');

        // Delete main user AUTH
        log('🗑️  Deleting user from Appwrite Auth...');
        let authDeleted = false;
        try {
            await users.delete(authUserId);
            authDeleted = true;
            log('✅ User deleted from Auth');
        } catch (err) {
            if (err.code === 404 || err.message?.includes('could not be found')) {
                log('⚠️  Auth user not found (orphaned record) - continuing');
                authDeleted = true;
            } else {
                // Rollback
                log('⚠️  Rollback - recreating user document...');
                try {
                    await databases.createDocument(databaseId, usersCollectionId, userId, userDoc);
                    log('✅ Rollback successful');
                } catch (e) {
                    error(`❌ Rollback failed: ${e.message}`);
                }
                throw err;
            }
        }

        log('✅ User deletion completed successfully');
        return res.json({
            success: true,
            message: 'User deleted successfully',
            data: {
                userId,
                authUserId,
                role: userRole,
                subRole: userSubRole,
                authDeleted,
                deletedData
            }
        }, 200);

    } catch (err) {
        error(`❌ Function error: ${err.message}`);
        error(err.stack);

        return res.json({
            success: false,
            error: err.message || 'Internal server error',
            code: err.code || 'UNKNOWN_ERROR'
        }, 500);
    }
};
