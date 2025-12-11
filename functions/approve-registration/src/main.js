import { Client, Databases, Users, ID, Query } from 'node-appwrite';

/**
 * Appwrite Function: Approve Registration & Auto-Create User
 * 
 * This function handles the complete user creation flow when admin approves a registration:
 * 1. Retrieves registration request with user's chosen password
 * 2. Creates user in Appwrite Auth using the password from registration
 * 3. Creates user document in 'users' collection
 * 4. Updates registration request status to approved
 * 
 * Required Environment Variables:
 * - APPWRITE_FUNCTION_ENDPOINT
 * - APPWRITE_FUNCTION_PROJECT_ID
 * - APPWRITE_FUNCTION_API_KEY (with users.write + documents.read + documents.write)
 * - DATABASE_ID
 * - USERS_COLLECTION_ID
 * - REGISTRATION_REQUESTS_COLLECTION_ID
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
    const registrationRequestsCollectionId = process.env.REGISTRATION_REQUESTS_COLLECTION_ID || 'registration_requests';

    try {
        // Parse request body
        const body = JSON.parse(req.body || '{}');

        const {
            requestId,
            adminUserId,
            notes
        } = body;

        // Validate required fields
        if (!requestId) {
            error('Missing required field: requestId');
            return res.json({
                success: false,
                error: 'Missing required field: requestId'
            }, 400);
        }

        log(`Processing registration approval for request: ${requestId}`);

        // Step 1: Get registration request data
        log('Fetching registration request...');
        const registrationDoc = await databases.getDocument(
            databaseId,
            registrationRequestsCollectionId,
            requestId
        );

        const registration = registrationDoc;
        log(`Found registration for: ${registration.email}`);

        // Use password from registration (user's chosen password)
        const userPassword = registration.password_hash;
        if (!userPassword) {
            error('Registration does not have password_hash');
            return res.json({
                success: false,
                error: 'Registration data incomplete: missing password'
            }, 400);
        }
        log('Using user registration password');

        // Step 2: Create user in Appwrite Auth
        log('Creating user in Appwrite Auth...');
        const userId = ID.unique();

        try {
            await users.create(
                userId,
                registration.email,
                undefined, // phone (optional)
                userPassword,
                registration.full_name
            );
            log(`User created in Auth with ID: ${userId}`);
        } catch (authError) {
            error(`Failed to create user in Auth: ${authError.message}`);

            // Check if user already exists
            if (authError.code === 409 || authError.message?.includes('already exists')) {
                return res.json({
                    success: false,
                    error: 'User with this email already exists in Auth',
                    code: 'USER_EXISTS'
                }, 409);
            }

            throw authError;
        }

        // Step 3: Create user document in users collection
        log('Creating user document in database...');

        // Generate username from email (part before @)
        const username = registration.email.split('@')[0];
        log(`Generated username: ${username}`);

        // Auto-grant 30 days contract on approval
        const contractEndDate = new Date();
        contractEndDate.setDate(contractEndDate.getDate() + 30);
        log(`Auto-granting 30 days contract until: ${contractEndDate.toISOString()}`);

        try {
            // CRITICAL FIX: Use Auth User ID as Document ID to prevent mismatch
            await databases.createDocument(
                databaseId,
                usersCollectionId,
                userId, // ✅ Use Auth ID (was: ID.unique())
                {
                    user_id: userId,
                    username: username,
                    role: 'owner_bussines', // Note: matches enum typo (should be 'business')
                    is_active: true,
                    contract_end_date: contractEndDate.toISOString(),
                    // tenant_id: null (optional, will use default)
                }
            );
            log('User document created successfully with 30-day contract');
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

        // Step 4: Update registration request status
        log('Updating registration request status...');
        await databases.updateDocument(
            databaseId,
            registrationRequestsCollectionId,
            requestId,
            {
                status: 'approved',
                reviewed_by: adminUserId || 'system',
                reviewed_at: new Date().toISOString(),
                admin_notes: notes || null,
            }
        );
        log('Registration request updated to approved');

        // Success response
        log('✅ Registration approval completed successfully');
        return res.json({
            success: true,
            message: 'User created successfully',
            data: {
                userId: userId,
                email: registration.email,
                fullName: registration.full_name,
                role: 'owner_business'
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
