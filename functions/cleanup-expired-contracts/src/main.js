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
    const tenantsCollectionId = process.env.TENANTS_COLLECTION_ID || 'tenants';
    const invitationCodesCollectionId = process.env.INVITATION_CODES_COLLECTION_ID || 'invitation_codes';

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
        },
        invitationCodes: {
            checked: 0,
            expired: 0
        },
        trials: {
            checked: 0,
            downgraded: 0,
            autoSelected: 0
        },
        swapDeadlines: {
            checked: 0,
            finalized: 0
        },
        tenants: {
            deactivated: 0
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
                Query.notEqual('role', 'owner_business'),  // Business owners use subscription_expires_at
                Query.notEqual('role', 'owner_bussines'),  // Legacy typo variant
                Query.isNotNull('contract_end_date')
            ]
        );

        summary.checked = usersResponse.documents.length;
        log(`📊 Found ${summary.checked} users with expired contracts`);

        // CHANGED: No early return! Continue to other cleanup tasks even if no expired contracts
        // Product limits, trial downgrades, etc. still need to run

        // Step 2: Process each expired user (with 3-month grace period)
        const threeMonthsAgo = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
        log(`📅 Grace period threshold: ${threeMonthsAgo.toISOString()} (3 months ago)`);

        for (const userDoc of usersResponse.documents) {
            const userId = userDoc.$id;
            const authUserId = userDoc.user_id;
            const userRole = userDoc.role;
            const userSubRole = userDoc.sub_role;
            const tenantId = userDoc.tenant_id;
            const contractEndDate = new Date(userDoc.contract_end_date);
            const userInfo = `${userDoc.username || userDoc.email} (${userRole})`;

            log(`\n📋 Processing user: ${userInfo}`);
            log(`   Contract expired: ${userDoc.contract_end_date}`);

            // NEW: Check if grace period (3 months) has passed
            if (contractEndDate > threeMonthsAgo) {
                const daysRemaining = Math.ceil((contractEndDate.getTime() - threeMonthsAgo.getTime()) / (1000 * 60 * 60 * 24));
                log(`   ⏳ Grace period active: ${daysRemaining} days remaining before deletion`);
                summary.skipped++;
                summary.skippedUsers.push({
                    userId: userId,
                    username: userDoc.username,
                    reason: `Grace period - ${daysRemaining} days remaining`
                });
                continue; // Skip deletion, grace period not over yet
            }

            log(`   🔴 Grace period expired (3+ months) - proceeding with deletion`);

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


        // ========== CLEANUP EXPIRED INVITATION CODES ==========
        log('\n  Cleaning up expired invitation codes...');
        try {
            // Check codes older than 5 hours
            const fiveHoursAgo = new Date(now.getTime() - 5 * 60 * 60 * 1000);

            const invitationCodesResponse = await databases.listDocuments(
                databaseId,
                invitationCodesCollectionId,
                [
                    Query.equal('status', 'active'),
                    Query.lessThan('$createdAt', new Date(now.getTime() - 5 * 60 * 60 * 1000).toISOString())
                ]
            );

            summary.invitationCodes.checked = invitationCodesResponse.documents.length;
            log(`   Found ${summary.invitationCodes.checked} expired invitation codes`);

            for (const code of invitationCodesResponse.documents) {
                try {
                    await databases.updateDocument(
                        databaseId,
                        invitationCodesCollectionId,
                        code.$id,
                        { status: 'expired' }
                    );
                    summary.invitationCodes.expired++;
                } catch (e) {
                    error(`   Failed to expire invitation code ${code.code}: ${e.message}`);
                }
            }

            log(`    Expired ${summary.invitationCodes.expired} invitation codes`);
        } catch (e) {
            error(`    Failed to cleanup invitation codes: ${e.message}`);
        }

        // ========== DOWNGRADE EXPIRED TRIAL SUBSCRIPTIONS ==========
        log('\n Downgrading expired trial subscriptions...');
        try {
            const expiredTrialsResponse = await databases.listDocuments(
                databaseId,
                usersCollectionId,
                [
                    Query.equal('payment_status', 'trial'),
                    Query.lessThan('subscription_expires_at', now.toISOString())
                ]
            );

            summary.trials.checked = expiredTrialsResponse.documents.length;
            log(`   Found ${summary.trials.checked} expired trial users`);

            for (const user of expiredTrialsResponse.documents) {
                try {
                    await databases.updateDocument(
                        databaseId,
                        usersCollectionId,
                        user.$id,
                        {
                            payment_status: 'free'
                            // Removed fields: swap_available_until, selection_finalized (not in schema)
                        }
                    );

                    // Auto-select 2 newest tenants if user hasn't manually selected
                    if (!user.manual_tenant_selection) {
                        const tenants = await databases.listDocuments(
                            databaseId,
                            tenantsCollectionId,
                            [Query.equal('user_id', user.$id)]
                        );

                        if (tenants.total > 2) {
                            const sortedTenants = tenants.documents
                                .sort((a, b) => new Date(b.$createdAt) - new Date(a.$createdAt));

                            for (let i = 0; i < sortedTenants.length; i++) {
                                await databases.updateDocument(
                                    databaseId,
                                    tenantsCollectionId,
                                    sortedTenants[i].$id,
                                    {
                                        selected_for_free_tier: i < 2,
                                        is_active: true
                                    }
                                );
                            }

                            summary.trials.autoSelected++;
                        }
                    }

                    summary.trials.downgraded++;
                    log(`    Downgraded user: ${user.username || user.email} (trial expired)`);
                } catch (e) {
                    error(`   Failed to downgrade user ${user.username}: ${e.message}`);
                    summary.errors++;
                }
            }

            log(`    Downgraded ${summary.trials.downgraded} trial users to FREE tier`);
        } catch (e) {
            error(`    Failed to downgrade trial users: ${e.message}`);
        }

        // ========== FINALIZE TENANT SELECTION (SWAP DEADLINE) ==========
        // COMMENTED OUT: Fields swap_available_until and selection_finalized don't exist in schema
        // Implement later when these fields are added
        /*
        log('\nFinalizing tenant selections (swap deadline passed)...');
        try {
            const swapDeadlinePassed = await databases.listDocuments(
                databaseId,
                usersCollectionId,
                [
                    Query.lessThan('swap_available_until', now.toISOString()),
                    Query.equal('selection_finalized', false),
                    Query.equal('payment_status', 'free')
                ]
            );

            summary.swapDeadlines.checked = swapDeadlinePassed.documents.length;
            log(`   Found ${summary.swapDeadlines.checked} users with swap deadline passed`);

            for (const user of swapDeadlinePassed.documents) {
                try {
                    const tenants = await databases.listDocuments(
                        databaseId,
                        tenantsCollectionId,
                        [Query.equal('user_id', user.$id)]
                    );

                    for (const tenant of tenants.documents) {
                        if (!tenant.selected_for_free_tier && tenant.is_active) {
                            await databases.updateDocument(
                                databaseId,
                                tenantsCollectionId,
                                tenant.$id,
                                {
                                    is_active: false,
                                    deactivated_at: now.toISOString(),
                                    deactivation_reason: user.swap_used ? 'swap_deadline' : 'trial_auto'
                                }
                            );

                            summary.tenants.deactivated++;
                            log(`       Deactivated tenant: ${tenant.name}`);
                        }
                    }

                    await databases.updateDocument(
                        databaseId,
                        usersCollectionId,
                        user.$id,
                        { selection_finalized: true }
                    );

                    summary.swapDeadlines.finalized++;
                } catch (e) {
                    error(`   Failed to finalize user ${user.username}: ${e.message}`);
                    summary.errors++;
                }
            }

            log(`   Finalized ${summary.swapDeadlines.finalized} user selections`);
        } catch (e) {
            error(`   Failed swap finalization: ${e.message}`);
        }
        */
        log('\n⏭️  Swap finalization: Skipped (feature not implemented in schema yet)');
        summary.swapDeadlines = { checked: 0, finalized: 0 };

        // ========== AUTO-DEACTIVATE EXCESS PRODUCTS (D-0 ENFORCEMENT) ==========
        log('\n📦 Checking product limits for free tier users...');
        try {
            const freeTierUsers = await databases.listDocuments(
                databaseId,
                usersCollectionId,
                [
                    Query.equal('payment_status', ['free', 'expired']),
                    Query.equal('role', ['owner_business', 'owner_bussines'])
                ]
            );

            summary.productLimits = { checked: 0, deactivated: 0, tenantsProcessed: 0 };

            log(`   Found ${freeTierUsers.documents.length} free tier users`);

            for (const user of freeTierUsers.documents) {
                const PRODUCT_LIMIT = 15; // Free tier limit

                // Get user's selected tenants
                const selectedTenantIds = user.selected_tenant_ids || [];

                if (selectedTenantIds.length === 0) {
                    continue; // Skip if no tenants
                }

                for (const tenantId of selectedTenantIds) {
                    try {
                        // Get all AVAILABLE products for this tenant (user-visible)
                        const productsResponse = await databases.listDocuments(
                            databaseId,
                            productsCollectionId,
                            [
                                Query.equal('tenant_id', tenantId),
                                Query.equal('is_available', true),  // ✅ FIXED: Check is_available, not is_active
                                Query.limit(100) // Safety limit
                            ]
                        );

                        const activeCount = productsResponse.documents.length;
                        summary.productLimits.checked++;

                        // ✅ FIXED: Skip if already at or under limit
                        if (activeCount <= PRODUCT_LIMIT) {
                            log(`   ✅ Tenant ${tenantId}: ${activeCount}/${PRODUCT_LIMIT} products (OK)`);
                            continue; // Skip to next tenant
                        }

                        // Only deactivate if OVER limit
                        const excessCount = activeCount - PRODUCT_LIMIT;
                        log(`\n   ⚠️  Tenant ${tenantId}: ${activeCount}/${PRODUCT_LIMIT} products (excess: ${excessCount})`);
                        log(`   🎲 Random-selecting ${excessCount} products to deactivate...`);

                        // RANDOM SELECTION (user requested)
                        // Shuffle array for random selection
                        const shuffledProducts = productsResponse.documents
                            .sort(() => Math.random() - 0.5);

                        // Deactivate random products
                        for (let i = 0; i < excessCount; i++) {
                            const product = shuffledProducts[i];

                            try {
                                await databases.updateDocument(
                                    databaseId,
                                    productsCollectionId,
                                    product.$id,
                                    {
                                        is_available: false  // Use existing field only
                                        // Removed: deactivated_at (doesn't exist)
                                        // Removed: deactivation_reason (doesn't exist)
                                    }
                                );

                                summary.productLimits.deactivated++;
                                log(`     ✅ Deactivated: ${product.name} (set is_available=false)`);
                            } catch (e) {
                                error(`     ❌ Failed to deactivate ${product.name}: ${e.message}`);
                                summary.errors++;
                            }
                        }

                        summary.productLimits.tenantsProcessed++;

                    } catch (e) {
                        error(`   ❌ Failed to process tenant ${tenantId}: ${e.message}`);
                        summary.errors++;
                    }
                }
            }

            log(`\n   📊 Product Limit Summary:`);
            log(`     Tenants checked: ${summary.productLimits.checked}`);
            log(`     Tenants processed: ${summary.productLimits.tenantsProcessed}`);
            log(`     Products deactivated: ${summary.productLimits.deactivated}`);

        } catch (e) {
            error(`   ❌ Failed product limit check: ${e.message}`);
        }

        // ========== AUTO-DEACTIVATE EXCESS STAFF (FREE TIER) ==========
        log('\n👥 Checking staff limits for free tier tenants...');
        try {
            const staffCollectionId = process.env.STAFF_COLLECTION_ID || 'staff';
            const freeTierUsers = await databases.listDocuments(
                databaseId,
                usersCollectionId,
                [
                    Query.equal('payment_status', ['free', 'expired']),
                    Query.equal('role', ['owner_business', 'owner_bussines'])
                ]
            );

            summary.staffLimits = { checked: 0, deactivated: 0, tenantsProcessed: 0 };

            log(`   Found ${freeTierUsers.documents.length} free tier business owners`);

            for (const user of freeTierUsers.documents) {
                const STAFF_LIMIT = 1; // Free tier limit per tenant

                // Get ALL tenants owned by this BO
                const tenantsResponse = await databases.listDocuments(
                    databaseId,
                    tenantsCollectionId,
                    [Query.equal('owner_id', user.$id)]
                );

                if (tenantsResponse.documents.length === 0) {
                    continue; // Skip if no tenants
                }

                for (const tenant of tenantsResponse.documents) {
                    const tenantId = tenant.$id;
                    try {
                        // Get all ACTIVE staff for this tenant (excluding owner)
                        const staffResponse = await databases.listDocuments(
                            databaseId,
                            usersCollectionId,
                            [
                                Query.equal('tenant_id', tenantId),
                                Query.equal('sub_role', 'staff'),
                                Query.equal('is_active', true),
                                Query.limit(100) // Safety limit
                            ]
                        );

                        const activeCount = staffResponse.documents.length;
                        summary.staffLimits.checked++;

                        // ✅ FIXED: Skip if already at or under limit
                        if (activeCount <= STAFF_LIMIT) {
                            log(`   ✅ Tenant ${tenantId}: ${activeCount}/${STAFF_LIMIT} staff (OK)`);
                            continue; // Skip to next tenant
                        }

                        // Only deactivate if OVER limit
                        const excessCount = activeCount - STAFF_LIMIT;
                        log(`\n   ⚠️  Tenant ${tenantId}: ${activeCount}/${STAFF_LIMIT} staff (excess: ${excessCount})`);
                        log(`   🎲 Random-selecting ${excessCount} staff to deactivate...`);

                        // RANDOM SELECTION (similar to products)
                        const shuffledStaff = staffResponse.documents
                            .sort(() => Math.random() - 0.5);

                        // Deactivate random staff
                        for (let i = 0; i < excessCount; i++) {
                            const staff = shuffledStaff[i];

                            try {
                                await databases.updateDocument(
                                    databaseId,
                                    usersCollectionId,
                                    staff.$id,
                                    {
                                        is_active: false,
                                        disabled_reason: 'auto_staff_limit_exceeded'
                                    }
                                );

                                summary.staffLimits.deactivated++;
                                log(`     ✅ Deactivated: ${staff.username || staff.email} (role: ${staff.sub_role})`);
                            } catch (e) {
                                error(`     ❌ Failed to deactivate ${staff.username}: ${e.message}`);
                                summary.errors++;
                            }
                        }

                        summary.staffLimits.tenantsProcessed++;


                    } catch (e) {
                        error(`   ❌ Failed to process tenant ${tenantId}: ${e.message}`);
                        summary.errors++;
                    }
                }
            }

            log(`\n   📊 Staff Limit Summary:`);
            log(`     Tenants checked: ${summary.staffLimits.checked}`);
            log(`     Tenants processed: ${summary.staffLimits.tenantsProcessed}`);
            log(`     Staff deactivated: ${summary.staffLimits.deactivated}`);

        } catch (e) {
            error(`   ❌ Failed staff limit check: ${e.message}`);
        }

        // ========== AUTO-DEACTIVATE EXCESS TENANT USERS (FREE TIER) ==========
        log('\n👤 Checking tenant user limits for free tier business owners...');
        try {
            const freeTierUsers = await databases.listDocuments(
                databaseId,
                usersCollectionId,
                [
                    Query.equal('payment_status', ['free', 'expired']),
                    Query.equal('role', ['owner_business', 'owner_bussines'])
                ]
            );

            summary.tenantUserLimits = { checked: 0, deactivated: 0, tenantsProcessed: 0 };

            log(`   Found ${freeTierUsers.documents.length} free tier business owners`);

            for (const user of freeTierUsers.documents) {
                const TENANT_USER_LIMIT = 1; // Free tier: 1 active user per tenant

                // Get ALL tenants owned by this BO
                const tenantsResponse = await databases.listDocuments(
                    databaseId,
                    tenantsCollectionId,
                    [Query.equal('owner_id', user.$id)]
                );

                if (tenantsResponse.documents.length === 0) {
                    continue; // Skip if no tenants
                }

                for (const tenant of tenantsResponse.documents) {
                    const tenantId = tenant.$id;
                    try {
                        // Get all ACTIVE tenant users for this tenant (NOT staff!)
                        const tenantUsersResponse = await databases.listDocuments(
                            databaseId,
                            usersCollectionId,
                            [
                                Query.equal('tenant_id', tenantId),
                                Query.equal('role', 'tenant'),
                                Query.or([
                                    Query.isNull('sub_role'),
                                    Query.equal('sub_role', '')
                                ]), // Only users WITHOUT staff sub_role
                                Query.equal('is_active', true),
                                Query.limit(100) // Safety limit
                            ]
                        );

                        const activeCount = tenantUsersResponse.documents.length;
                        summary.tenantUserLimits.checked++;

                        // ✅ FIXED: Skip if already at or under limit
                        if (activeCount <= TENANT_USER_LIMIT) {
                            log(`   ✅ Tenant ${tenantId}: ${activeCount}/${TENANT_USER_LIMIT} tenant users (OK)`);
                            continue; // Skip to next tenant
                        }

                        // Only deactivate if OVER limit
                        const excessCount = activeCount - TENANT_USER_LIMIT;
                        log(`\n   ⚠️  Tenant ${tenantId}: ${activeCount}/${TENANT_USER_LIMIT} tenant users (excess: ${excessCount})`);
                        log(`   🎲 Random-selecting ${excessCount} users to deactivate...`);

                        // RANDOM SELECTION (same algorithm as products/staff)
                        const shuffledUsers = tenantUsersResponse.documents
                            .sort(() => Math.random() - 0.5);

                        // Deactivate random users
                        for (let i = 0; i < excessCount; i++) {
                            const tenantUser = shuffledUsers[i];

                            try {
                                await databases.updateDocument(
                                    databaseId,
                                    usersCollectionId,
                                    tenantUser.$id,
                                    {
                                        is_active: false,
                                        disabled_reason: 'auto_tenant_user_limit_exceeded'
                                    }
                                );

                                summary.tenantUserLimits.deactivated++;
                                log(`     ✅ Deactivated: ${tenantUser.username || tenantUser.email}`);
                            } catch (e) {
                                error(`     ❌ Failed to deactivate ${tenantUser.username}: ${e.message}`);
                                summary.errors++;
                            }
                        }

                        summary.tenantUserLimits.tenantsProcessed++;


                    } catch (e) {
                        error(`   ❌ Failed to process tenant ${tenantId}: ${e.message}`);
                        summary.errors++;
                    }
                }
            }

            log(`\n   📊 Tenant User Limit Summary:`);
            log(`     Tenants checked: ${summary.tenantUserLimits.checked}`);
            log(`     Tenants processed: ${summary.tenantUserLimits.tenantsProcessed}`);
            log(`     Users deactivated: ${summary.tenantUserLimits.deactivated}`);

        } catch (e) {
            error(`   ❌ Failed tenant user limit check: ${e.message}`);
        }


        // Final summary
        summary.endTime = new Date().toISOString();
        const duration = (new Date(summary.endTime) - new Date(summary.startTime)) / 1000;

        log('\n📊 Cleanup Summary:');
        log(`   ⏱️  Duration: ${duration}s`);
        log(`   📋 Total checked: ${summary.checked}`);
        log(`   ⏰ Expired: ${summary.expired}`);
        log(`   ⏳ In grace period: ${summary.skipped} (3-month grace active)`);
        log(`   ✅ Deleted: ${summary.deleted}`);
        log(`   ❌ Errors: ${summary.errors}`);
        log('\n📦 Cascaded Data Deleted:');
        log(`   🏪 Tenants: ${summary.cascadedData.tenants}`);
        log(`   👥 Staff: ${summary.cascadedData.staff}`);
        log(`   🍔 Products: ${summary.cascadedData.products}`);
        log(`   📝 Orders: ${summary.cascadedData.orders}`);
        log('\nInvitation Codes:');
        log(`   Checked: ${summary.invitationCodes.checked}`);
        log(`   Expired: ${summary.invitationCodes.expired}`);
        log('\nTrial Subscriptions:');
        log(`   Checked: ${summary.trials.checked}`);
        log(`   Downgraded: ${summary.trials.downgraded}`);
        log(`   Auto - selected: ${summary.trials.autoSelected}`);
        log('\nSwap Deadlines:');
        log(`   Checked: ${summary.swapDeadlines.checked}`);
        log(`   Finalized: ${summary.swapDeadlines.finalized}`);
        log('\nTenants:');
        log(`   Deactivated: ${summary.tenants.deactivated}`);
        log('\nProduct Limits (Free Tier):');
        log(`   Tenants checked: ${summary.productLimits?.checked || 0}`);
        log(`   Products deactivated: ${summary.productLimits?.deactivated || 0}`);
        log('\nStaff Limits (Free Tier):');
        log(`   Tenants checked: ${summary.staffLimits?.checked || 0}`);
        log(`   Staff deactivated: ${summary.staffLimits?.deactivated || 0}`);
        log('\nTenant User Limits (Free Tier):');
        log(`   Tenants checked: ${summary.tenantUserLimits?.checked || 0}`);
        log(`   Users deactivated: ${summary.tenantUserLimits?.deactivated || 0}`);

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
            message: `Cleanup completed.Deleted ${summary.deleted} expired users.`,
            summary: summary
        }, 200);

    } catch (err) {
        error(`❌ Function error: ${err.message} `);
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
