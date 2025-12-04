import { Client, Databases, Query } from 'node-appwrite';

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
 *    - Check if has active orders
 *    - Call delete-user function internally
 *    - Log result
 * 4. Generate summary report
 * 
 * Required Environment Variables:
 * - APPWRITE_FUNCTION_ENDPOINT
 * - APPWRITE_FUNCTION_PROJECT_ID
 * - APPWRITE_FUNCTION_API_KEY
 * - DATABASE_ID
 * - USERS_COLLECTION_ID
 * - ORDERS_COLLECTION_ID
 */

export default async ({ req, res, log, error }) => {
    // Initialize Appwrite client
    const client = new Client()
        .setEndpoint(process.env.APPWRITE_FUNCTION_ENDPOINT || 'https://fra.cloud.appwrite.io/v1')
        .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID || '')
        .setKey(process.env.APPWRITE_FUNCTION_API_KEY || '');

    const databases = new Databases(client);

    // Configuration
    const databaseId = process.env.DATABASE_ID || 'kantin-db';
    const usersCollectionId = process.env.USERS_COLLECTION_ID || 'users';
    const ordersCollectionId = process.env.ORDERS_COLLECTION_ID || 'orders';

    const summary = {
        startTime: new Date().toISOString(),
        checked: 0,
        expired: 0,
        deleted: 0,
        skipped: 0,
        errors: 0,
        deletedUsers: [],
        skippedUsers: [],
        errorDetails: []
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
            const userRole = userDoc.role;
            const contractEndDate = userDoc.contract_end_date;
            const userInfo = `${userDoc.username || userDoc.email} (${userRole})`;

            log(`\n📋 Processing user: ${userInfo}`);
            log(`   Contract expired: ${contractEndDate}`);

            // Filter by role - only delete tenant and business owner
            if (userRole !== 'tenant' && userRole !== 'owner_bussines' && userRole !== 'owner_business') {
                log(`   ⏭️  Skipping - role '${userRole}' not eligible for auto-cleanup`);
                summary.skipped++;
                summary.skippedUsers.push({
                    userId: userId,
                    reason: `Invalid role: ${userRole}`
                });
                continue;
            }

            summary.expired++;

            // Check for active orders (grace period for pending transactions)
            try {
                if (userDoc.tenant_id) {
                    const ordersResponse = await databases.listDocuments(
                        databaseId,
                        ordersCollectionId,
                        [
                            Query.equal('tenant_id', userDoc.tenant_id),
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

            // Delete user via internal HTTP call to delete-user function
            try {
                log(`   🗑️  Deleting user...`);

                // Direct deletion via database API (simpler than calling another function)
                const deleteUserClient = new Client()
                    .setEndpoint(process.env.APPWRITE_FUNCTION_ENDPOINT || 'https://fra.cloud.appwrite.io/v1')
                    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID || '')
                    .setKey(process.env.APPWRITE_FUNCTION_API_KEY || '');

                const deleteDb = new Databases(deleteUserClient);

                // Delete user document
                await deleteDb.deleteDocument(
                    databaseId,
                    usersCollectionId,
                    userId
                );

                // Delete from Auth (if user_id exists)
                if (userDoc.user_id) {
                    const { Users } = await import('node-appwrite');
                    const deleteUsers = new Users(deleteUserClient);
                    try {
                        await deleteUsers.delete(userDoc.user_id);
                    } catch (authError) {
                        log(`   ⚠️  Auth deletion failed (user may not exist): ${authError.message}`);
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
