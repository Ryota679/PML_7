import { Client, Databases, Users, ID, Query } from 'node-appwrite';

/**
 * Appwrite Function: Create User (Unified)
 * 
 * This function creates both tenant and staff users in Appwrite Auth and users collection.
 * It replaces the separate createTenantUser and createStaffUser functions.
 * 
 * Required Environment Variables:
 * - APPWRITE_FUNCTION_ENDPOINT
 * - APPWRITE_FUNCTION_PROJECT_ID
 * - APPWRITE_FUNCTION_API_KEY (with users.write + documents.write scopes)
 * - DATABASE_ID
 * - USERS_COLLECTION_ID
 */

export default async ({ req, res, log, error }) => {
    // Debug: Log environment variables
    log('=== Environment Check ===');
    log(`API Key exists: ${!!process.env.APPWRITE_FUNCTION_API_KEY}`);
    log(`API Key prefix: ${process.env.APPWRITE_FUNCTION_API_KEY ? process.env.APPWRITE_FUNCTION_API_KEY.substring(0, 20) + '...' : 'MISSING'}`);
    log(`Database ID: ${process.env.DATABASE_ID}`);
    log(`Users Collection: ${process.env.USERS_COLLECTION_ID}`);

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
        log(`Raw req.body type: ${typeof req.body}`);
        log(`Raw req.body: ${req.body}`);

        let body = req.body;
        if (typeof body === 'string') {
            try {
                body = JSON.parse(body || '{}');
            } catch (e) {
                error(`JSON parse error: ${e.message}`);
                body = {};
            }
        }

        log(`Parsed body keys: ${Object.keys(body).join(', ')}`);
        log(`user_type value: ${body.user_type}`);
        log(`userType value: ${body.userType}`);

        const {
            user_type: userType,      // Map 'user_type' -> userType
            email,
            password,
            full_name: fullName,      // Map 'full_name' -> fullName
            username,
            tenant_id: tenantId,      // Map 'tenant_id' -> tenantId
            contract_end_date: contractEndDate, // Map 'contract_end_date' -> contractEndDate
            phone,
            created_by: createdBy     // Map 'created_by' -> createdBy
        } = body;

        // ========== NEW: OAuth Labels Handler ==========
        // Handle OAuth user label setting (for Google Sign-In users)
        if (body.action === 'set_oauth_labels') {
            log('=== OAuth Labels Request Detected ===');

            try {
                const { userId, role } = body;

                // Validate required fields
                if (!userId || !role) {
                    error('Missing userId or role for OAuth labels');
                    return res.json({
                        success: false,
                        error: 'Missing required fields: userId and role'
                    }, 400);
                }

                log(`Setting OAuth label for user: ${userId}, role: ${role}`);

                // Map role to label (match existing Appwrite labels)
                const labelMap = {
                    'owner_bussines': 'ownerbussines',  // Match existing permissions (dengan 'e')
                    'tenant': 'tenant',
                    'staff': 'staff'  // Staff gets dedicated label (not tenant)
                };

                const label = labelMap[role];
                if (!label) {
                    error(`Invalid role provided: ${role}`);
                    return res.json({
                        success: false,
                        error: `Invalid role: ${role}. Must be owner_business, tenant, or staff`
                    }, 400);
                }

                // Set label in Auth account
                await users.updateLabels(userId, [label]);

                log(`✅ OAuth label '${label}' successfully set for user ${userId} (role: ${role})`);

                return res.json({
                    success: true,
                    message: 'Label set successfully',
                    data: {
                        userId: userId,
                        role: role,
                        label: label
                    }
                }, 200);

            } catch (oauthError) {
                error(`OAuth labels error: ${oauthError.message}`);
                return res.json({
                    success: false,
                    error: `Failed to set OAuth labels: ${oauthError.message}`
                }, 500);
            }
        }
        // ========== End OAuth Handler ==========


        // ========== SECURITY: Validate Caller Role ==========
        log('=== Security Check: Validating caller role ===');

        // Get caller user ID from request headers
        const callerId = req.headers['x-appwrite-user-id'];

        if (!callerId) {
            error('Unauthorized: No user session found');
            return res.json({
                success: false,
                error: 'Unauthorized: You must be logged in to create users',
                code: 'UNAUTHENTICATED'
            }, 401);
        }

        log(`Caller ID: ${callerId}`);

        // Fetch caller's profile from database to check role
        try {
            const callerDocs = await databases.listDocuments(
                databaseId,
                usersCollectionId,
                [Query.equal('user_id', callerId)]
            );

            if (callerDocs.documents.length === 0) {
                error('Caller profile not found in database');
                return res.json({
                    success: false,
                    error: 'User profile not found',
                    code: 'PROFILE_NOT_FOUND'
                }, 404);
            }

            const callerProfile = callerDocs.documents[0];
            log(`Caller role: ${callerProfile.role}, sub_role: ${callerProfile.sub_role}`);

            // Authorization logic based on caller role and userType
            const isBusinessOwner = callerProfile.role === 'owner_bussines' || callerProfile.role === 'owner_business';
            const isTenantOwner = callerProfile.role === 'tenant' && (callerProfile.sub_role === null || callerProfile.sub_role === undefined);

            // Business owners can create anyone (tenant + staff)
            if (isBusinessOwner) {
                log('✅ Security check passed: Caller is Business Owner (can create tenant + staff)');
            }
            // Tenant owners can ONLY create staff users
            else if (isTenantOwner) {
                if (userType !== 'staff') {
                    error(`Forbidden: Tenant owners can only create staff users, not '${userType}'`);
                    return res.json({
                        success: false,
                        error: 'Forbidden: Tenant owners can only create staff users',
                        code: 'INSUFFICIENT_PERMISSIONS',
                        details: {
                            yourRole: 'tenant_owner',
                            attemptedAction: `create ${userType}`,
                            allowedActions: ['create staff']
                        }
                    }, 403);
                }
                log('✅ Security check passed: Caller is Tenant Owner (can create staff)');
            }
            // All other roles are rejected
            else {
                error(`Forbidden: User role '${callerProfile.role}' with sub_role '${callerProfile.sub_role}' not authorized`);
                return res.json({
                    success: false,
                    error: 'Forbidden: You do not have permission to create users',
                    code: 'INSUFFICIENT_PERMISSIONS',
                    details: {
                        yourRole: callerProfile.role,
                        yourSubRole: callerProfile.sub_role,
                        requiredRoles: ['owner_bussines', 'tenant_owner']
                    }
                }, 403);
            }

        } catch (securityError) {
            error(`Security check failed: ${securityError.message}`);
            return res.json({
                success: false,
                error: 'Failed to verify user permissions',
                details: securityError.message
            }, 500);
        }
        // ========== End Security Check ==========

        // Validate required fields
        if (!userType || !email || !password || !fullName || !username || !tenantId) {
            error('Missing required fields');
            return res.json({
                success: false,
                error: 'Missing required fields: userType, email, password, fullName, username, tenantId'
            }, 400);
        }

        // Validate userType
        if (userType !== 'staff' && userType !== 'tenant') {
            error('Invalid userType');
            return res.json({
                success: false,
                error: 'userType must be either "staff" or "tenant"'
            }, 400);
        }

        // Validate staff-specific fields
        if (userType === 'staff' && !createdBy) {
            error('Missing createdBy for staff user');
            return res.json({
                success: false,
                error: 'createdBy is required for staff users'
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

        // Validate username length
        if (username.length < 3) {
            error('Username too short');
            return res.json({
                success: false,
                error: 'Username must be at least 3 characters'
            }, 400);
        }

        log(`Creating ${userType} user: ${email} for tenant: ${tenantId}`);

        // Check if username already exists
        try {
            const existingUsers = await databases.listDocuments(
                databaseId,
                usersCollectionId,
                [Query.equal('username', username)]
            );

            if (existingUsers.total > 0) {
                error('Username already exists');
                return res.json({
                    success: false,
                    error: 'Username already exists',
                    code: 'USERNAME_EXISTS'
                }, 409);
            }
        } catch (checkError) {
            error(`Error checking username: ${checkError.message}`);
            // Continue anyway - will fail later if username truly exists
        }

        // Normalize phone: convert 08xxx to +628xxx
        let normalizedPhone = phone;
        if (phone && phone.startsWith('0')) {
            normalizedPhone = '+62' + phone.substring(1);
            log(`Normalized phone: ${normalizedPhone}`);
        }

        // Step 1: Create user in Appwrite Auth
        log('Creating user in Appwrite Auth...');
        const userId = ID.unique();

        try {
            await users.create(
                userId,
                email,
                normalizedPhone || undefined,
                password,
                fullName
            );
            log(`User created in Auth with ID: ${userId}`);

            // Set label based on userType
            const label = userType === 'staff' ? 'staff' : 'tenant';
            await users.updateLabels(userId, [label]);
            log(`Added "${label}" label to user (userType: ${userType})`);

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

        // Prepare document data based on userType
        const documentData = {
            user_id: userId,
            username: username,
            full_name: fullName,
            email: email,
            role: 'tenant',
            tenant_id: tenantId,
            is_active: true,
            phone: normalizedPhone || null
        };

        // Add type-specific fields
        if (userType === 'staff') {
            documentData.sub_role = 'staff';
            documentData.created_by = createdBy;
            documentData.contract_end_date = null; // Staff inherit from tenant owner
        } else {
            // Tenant user
            documentData.sub_role = null;

            // Parse contract end date or set default (30 days from now)
            let contractEnd = contractEndDate;
            if (!contractEnd) {
                const defaultDate = new Date();
                defaultDate.setDate(defaultDate.getDate() + 30);
                contractEnd = defaultDate.toISOString();
            }
            documentData.contract_end_date = contractEnd;
        }

        try {
            // CRITICAL FIX: Use Auth User ID as Document ID to prevent mismatch
            const userDoc = await databases.createDocument(
                databaseId,
                usersCollectionId,
                userId, // ✅ Use Auth ID (was: ID.unique())
                documentData
            );
            log(`User document created successfully with ID: ${userDoc.$id}`);
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
        log(`✅ ${userType} user created successfully`);
        return res.json({
            success: true,
            message: `${userType} user created successfully`,
            data: {
                userId: userId,
                email: email,
                fullName: fullName,
                username: username,
                role: 'tenant',
                subRole: userType === 'staff' ? 'staff' : null,
                tenantId: tenantId,
                userType: userType
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
