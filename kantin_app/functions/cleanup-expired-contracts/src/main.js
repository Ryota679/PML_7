import { Client, Databases, Users, Query } from 'node-appwrite';

/**
 * Appwrite Function: Cleanup Expired Contracts
 * 
 * Scheduled function that runs daily to auto-delete users with expired contracts.
 * Schedule: 0 0 * * * (daily at 00:00 UTC / 07:00 WIB)
 * 
 * Process:
 * 1. Query all users with contract_end_date < now()
 * 2. Filter by role: tenant, owner_business (exclude admin, staff, guest)
 * 3. For each expired user:
 *    - Check if has active orders (grace period)
 *    - Perform CASCADING DELETE (staff, products, orders)
 *    - Delete user from Database and Auth
 *    - Log result
 * 4. Generate summary report
 * 
 * CASCADING DELETE LOGIC:
 * - Tenant: Deletes all staff, products, orders for that tenant
 * - Business Owner: Deletes ALL tenants + their staff/products/orders
 * 
 * Required Environment Variables:
 * - APPWRITE_FUNCTION_ENDPOINT
 * - APPWRITE_FUNCTION_PROJECT_ID
 * - APPWRITE_FUNCTION_API_KEY
 * - DATABASE_ID
 * - USERS_COLLECTION_ID
 * - ORDERS_COLLECTION_ID
 * - PRODUCTS_COLLECTION_ID
 */

export default async ({ req, res, log, error }) => {
    // Initialize Appwrite client
    const client = new Client()
        .setEndpoint(process.env.APPWRITE_FUNCTION_ENDPOINT || 'https://fra.cloud.appwrite.io/v1')
        .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID || '')
        .setKey(process.env.APPWRITE_FUNCTION_API_KEY || '');

    const databases = new Databases(client);
    const users = new Users(client);

    // Configuration
    const databaseId = process.env.DATABASE_ID || 'kantin-db';
    const usersCollectionId = process.env.USERS_COLLECTION_ID || 'users';
    const ordersCollectionId = process.env.ORDERS_COLLECTION_ID || 'orders';
    const productsCollectionId = process.env.PRODUCTS_COLLECTION_ID || 'products';

    const summary = {
        startTime: new Date().toISOString(),
        checked: 0,
        expired: 0,
        deleted: 0,
        skipped: 0,
        errors: 0,
        deletedUsers: [],
        skippedUsers: [],
        errorDetails: [],
        cascadedData: {
            tenants: 0,
            staff: 0,
            products: 0,
            orders: 0
        }
    };

    try {
        log('🔵 Starting cleanup expired contracts process...');
        const now = new Date();
        log(`📅 Current time: ${now.toISOString()}`);

        // Step 1: Query expired users
        log('🔍 Querying users with expired contracts...');

        const usersResponse = await databases.listDocuments(
            databaseId,
            usersCollectionId,
            [
                Query.lessThan('contract_end_date', now.toISOString()),
                Query.notEqual('role', 'adminsystem'),
                Query.notEqual('role', 'guest'),
                Query.isNotNull('contract_end_date')
            ]
        );

        summary.checked = usersResponse.documents.length;
        log(`📊 Found ${summary.checked} users with expired contracts`);

        if (summary.checked === 0) {
            log('✅ No expired contracts found. Cleanup complete.');
            return res.json({
                success: true,
                message: 'No expired contracts to cleanup',
                summary: summary
            }, 200);
        }

        // Step 2: Process each expired user
        for (const userDoc of usersResponse.documents) {
            const userId = userDoc.$id;
            const authUserId = userDoc.user_id;
            const userRole = userDoc.role;
            const userSubRole = userDoc.sub_role;
            const tenantId = userDoc.tenant_id;
            const contractEndDate = userDoc.contract_end_date;
            const userInfo = `${userDoc.username || userDoc.email} (${userRole})`;

            log(`\n📋 Processing user: ${userInfo}`);
            log(`   Contract expired: ${contractEndDate}`);

            // Filter by role - only delete tenant and business owner (not staff directly)
            if (userRole !== 'tenant' && userRole !== 'owner_bussines' && userRole !== 'owner_business') {
                log(`   ⏭️  Skipping - role '${userRole}' not eligible for auto-cleanup`);
                summary.skipped++;
                summary.skippedUsers.push({
                    userId: userId,
                    reason: `Invalid role: ${userRole}`
                });
                continue;
            }

            // Skip staff (they are deleted when their tenant is deleted)
            if (userSubRole === 'staff') {
                log(`   ⏭️  Skipping - staff will be deleted with their tenant`);
                summary.skipped++;
                summary.skippedUsers.push({
                    userId: userId,
                    reason: 'Staff - will be cascade deleted with tenant'
                });
                continue;
            }

            summary.expired++;

            // Check for active orders (grace period for pending transactions)
            try {
                if (tenantId) {
                    const ordersResponse = await databases.listDocuments(
                        databaseId,
                        ordersCollectionId,
                        [
                            Query.equal('tenant_id', tenantId),
                            Query.equal('status', ['pending', 'confirmed', 'preparing'])
                        ]
                    );

                    if (ordersResponse.documents.length > 0) {
                        log(`   ⏭️  Skipping - has ${ordersResponse.documents.length} active orders`);
                        summary.skipped++;
                        summary.skippedUsers.push({
                            userId: userId,
                            username: userDoc.username,
                            reason: `Has ${ordersResponse.documents.length} active orders`
                        });
                        continue;
                    }
                }
            } catch (orderCheckError) {
                log(`   ⚠️  Failed to check orders: ${orderCheckError.message}`);
            }

            // ========== CASCADING DELETE ==========
            try {
                log(`   🗑️  Starting cascading delete...`);

                // --- TENANT DELETION ---
                if (userRole === 'tenant' && tenantId) {
                    log(`   🏪 TENANT deletion - cascading delete staff, products, orders...`);

                    // Delete all STAFF for this tenant
                    try {
                        const staffResponse = await databases.listDocuments(
                            databaseId,
                            usersCollectionId,
                            [
                                Query.equal('tenant_id', tenantId),
                                Query.notEqual('$id', userId) // Exclude self
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
                                summary.cascadedData.staff++;
                            } catch (e) {
                                error(`     Failed to delete staff: ${e.message}`);
                            }
                        }
                        log(`     ✅ Deleted ${staffResponse.documents.length} staff`);
                    } catch (e) {
                        error(`     Failed to query staff: ${e.message}`);
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
                            summary.cascadedData.products++;
                        }
                        log(`     ✅ Deleted ${productsResponse.documents.length} products`);
                    } catch (e) {
                        error(`     Failed to delete products: ${e.message}`);
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
                            summary.cascadedData.orders++;
                        }
                        log(`     ✅ Deleted ${ordersResponse.documents.length} orders`);
                    } catch (e) {
                        error(`     Failed to delete orders: ${e.message}`);
                    }
                }

                // --- BUSINESS OWNER DELETION ---
                if (userRole === 'owner_bussines' || userRole === 'owner_business') {
                    log(`   🏢 BUSINESS OWNER deletion - cascading delete ALL tenants...`);

                    try {
                        const tenantsResponse = await databases.listDocuments(
                            databaseId,
                            usersCollectionId,
                            [
                                Query.equal('role', 'tenant'),
                                Query.equal('created_by', authUserId)
                            ]
                        );

                        log(`     Found ${tenantsResponse.documents.length} tenants to delete`);

                        for (const tenant of tenantsResponse.documents) {
                            const tId = tenant.tenant_id;
                            const tAuthId = tenant.user_id;

                            log(`\n     📦 Deleting tenant: ${tenant.username}`);

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
                                        summary.cascadedData.staff++;
                                    } catch (e) { }
                                }
                                log(`       ✅ Deleted ${staffResponse.documents.length} staff`);
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
                                    summary.cascadedData.products++;
                                }
                                log(`       ✅ Deleted ${productsResponse.documents.length} products`);
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
                                    summary.cascadedData.orders++;
                                }
                                log(`       ✅ Deleted ${ordersResponse.documents.length} orders`);
                            } catch (e) { }

                            // Delete tenant AUTH
                            if (tAuthId) {
                                try {
                                    await users.delete(tAuthId);
                                } catch (e) {
                                    if (!(e.code === 404 || e.message?.includes('could not be found'))) {
                                        error(`       Failed to delete tenant Auth: ${e.message}`);
                                    }
                                }
                            }

                            // Delete tenant DOCUMENT
                            await databases.deleteDocument(databaseId, usersCollectionId, tenant.$id);
                            summary.cascadedData.tenants++;
                        }

                        log(`\n     ✅ Deleted ${summary.cascadedData.tenants} tenants total`);
                    } catch (e) {
                        error(`     Failed to delete business owner tenants: ${e.message}`);
                    }
                }

                // ========== DELETE MAIN USER ==========
                // Delete user document
                await databases.deleteDocument(databaseId, usersCollectionId, userId);

                // Delete from Auth
                if (authUserId) {
                    try {
                        await users.delete(authUserId);
                    } catch (authError) {
                        if (!(authError.code === 404 || authError.message?.includes('could not be found'))) {
                            log(`   ⚠️  Auth deletion failed: ${authError.message}`);
                        }
                    }
                }

                log(`   ✅ User deleted successfully`);
                summary.deleted++;
                summary.deletedUsers.push({
                    userId: userId,
                    username: userDoc.username || userDoc.email,
                    role: userRole,
                    contractEndDate: contractEndDate
                });

            } catch (deleteError) {
                log(`   ❌ Failed to delete user: ${deleteError.message}`);
                summary.errors++;
                summary.errorDetails.push({
                    userId: userId,
                    username: userDoc.username,
                    error: deleteError.message
                });
            }
        }

        // Final summary
        summary.endTime = new Date().toISOString();
        const duration = (new Date(summary.endTime) - new Date(summary.startTime)) / 1000;

        log('\n📊 Cleanup Summary:');
        log(`   ⏱️  Duration: ${duration}s`);
        log(`   📋 Total checked: ${summary.checked}`);
        log(`   ⏰ Expired: ${summary.expired}`);
        log(`   ✅ Deleted: ${summary.deleted}`);
        log(`   ⏭️  Skipped: ${summary.skipped}`);
        log(`   ❌ Errors: ${summary.errors}`);
        log('\n📦 Cascaded Data Deleted:');
        log(`   🏪 Tenants: ${summary.cascadedData.tenants}`);
        log(`   👥 Staff: ${summary.cascadedData.staff}`);
        log(`   🍔 Products: ${summary.cascadedData.products}`);
        log(`   📝 Orders: ${summary.cascadedData.orders}`);

        if (summary.errors > 0) {
            log('\n⚠️  Partial success - some deletions failed');
            return res.json({
                success: false,
                message: `Cleanup completed with ${summary.errors} errors`,
                summary: summary
            }, 207); // 207 Multi-Status
        }

        log('\n✅ Cleanup completed successfully');
        return res.json({
            success: true,
            message: `Cleanup completed. Deleted ${summary.deleted} expired users.`,
            summary: summary
        }, 200);

    } catch (err) {
        error(`❌ Function error: ${err.message}`);
        error(err.stack);

        summary.endTime = new Date().toISOString();
        summary.errors++;
        summary.errorDetails.push({
            error: err.message,
            stack: err.stack
        });

        return res.json({
            success: false,
            error: err.message || 'Internal server error',
            code: err.code || 'UNKNOWN_ERROR',
            summary: summary
        }, 500);
    }
};
