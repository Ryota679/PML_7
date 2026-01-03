import { Client, Databases, Users, ID } from 'node-appwrite';

/**
 * Appwrite Function: Create Tenant User
 * 
 * This function creates a tenant user in both Appwrite Auth and the users collection.
 * It's called by Business Owners when they want to add a new tenant user.
 * 
 * Required Environment Variables:
 * - APPWRITE_FUNCTION_ENDPOINT
 * - APPWRITE_FUNCTION_PROJECT_ID
 * - APPWRITE_FUNCTION_API_KEY (with users.write + documents.write scopes)
 * - DATABASE_ID
 * - USERS_COLLECTION_ID
 */

export default async ({ req, res, log, error }) => {
    // Initialize Appwrite client with API key
    const client = new Client()
        .setEndpoint(process.env.APPWRITE_FUNCTION_ENDPOINT || 'https://fra.cloud.appwrite.io/v1')
        .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID || '')
        .setKey(process.env.APPWRITE_FUNCTION_API_KEY || '');

    const databases = new Databases(client);
    const users = new Users(client);

    // Configuration
    const databaseId = process.env.DATABASE_ID || 'kantin-db';
    const usersCollectionId = process.env.USERS_COLLECTION_ID || 'users';

    try {
        // Parse request body
        const body = JSON.parse(req.body || '{}');

        const {
            email,
            password,
            fullName,
            username,
            tenantId,
            contractEndDate,
            phone
        } = body;

        // Validate required fields
        if (!email || !password || !fullName || !username || !tenantId) {
            error('Missing required fields');
            return res.json({
                success: false,
                error: 'Missing required fields: email, password, fullName, username, tenantId'
            }, 400);
        }

        // Validate password length
        if (password.length < 8) {
            error('Password too short');
            return res.json({
                success: false,
                error: 'Password must be at least 8 characters'
            }, 400);
        }

        log(`Creating tenant user: ${email} for tenant: ${tenantId}`);

        // Step 1: Create user in Appwrite Auth
        log('Creating user in Appwrite Auth...');
        const userId = ID.unique();

        try {
            await users.create(
                userId,
                email,
                phone || undefined, // phone (optional)
                password,
                fullName
            );
            log(`User created in Auth with ID: ${userId}`);

            // Add label 'tenant' to the user
            await users.updateLabels(userId, ['tenant']);
            log('Added "tenant" label to user');

        } catch (authError) {
            error(`Failed to create user in Auth: ${authError.message}`);

            // Check if user already exists
            if (authError.code === 409 || authError.message?.includes('already exists')) {
                return res.json({
                    success: false,
                    error: 'User with this email already exists',
                    code: 'USER_EXISTS'
                }, 409);
            }

            throw authError;
        }

        // Step 2: Create user document in users collection
        log('Creating user document in database...');

        // Parse contract end date or set default (30 days from now)
        let contractEnd = contractEndDate;
        if (!contractEnd) {
            const defaultDate = new Date();
            defaultDate.setDate(defaultDate.getDate() + 30);
            contractEnd = defaultDate.toISOString();
        }

        try {
            // CRITICAL FIX: Use Auth User ID as Document ID to prevent mismatch
            await databases.createDocument(
                databaseId,
                usersCollectionId,
                userId, // ✅ Use Auth ID (was: ID.unique())
                {
                    user_id: userId,
                    username: username,
                    full_name: fullName,
                    email: email,
                    role: 'tenant',
                    tenant_id: tenantId,
                    is_active: true,
                    contract_end_date: contractEnd
                }
            );
            log('User document created successfully');
        } catch (dbError) {
            error(`Failed to create user document: ${dbError.message}`);

            // Rollback: Delete user from Auth if document creation fails
            log('Rolling back: Deleting user from Auth...');
            try {
                await users.delete(userId);
                log('Rollback successful');
            } catch (rollbackError) {
                error(`Rollback failed: ${rollbackError.message}`);
            }

            throw dbError;
        }

        // Success response
        log('✅ Tenant user created successfully');
        return res.json({
            success: true,
            message: 'Tenant user created successfully',
            data: {
                userId: userId,
                email: email,
                fullName: fullName,
                username: username,
                role: 'tenant',
                tenantId: tenantId
            }
        }, 200);

    } catch (err) {
        error(`Function error: ${err.message}`);
        error(err.stack);

        return res.json({
            success: false,
            error: err.message || 'Internal server error',
            code: err.code || 'UNKNOWN_ERROR'
        }, 500);
    }
};
