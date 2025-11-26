const sdk = require('node-appwrite');

/**
 * Create Tenant User Function
 * Creates user in Appwrite Auth and Database
 * 
 * @param {Object} req - Request object
 * @param {Object} res - Response object
 * @param {Function} log - Logging function
 * @param {Function} error - Error logging function
 */
module.exports = async ({ req, res, log, error }) => {
    try {
        // Parse request body
        const data = JSON.parse(req.body || '{}');
        const { email, password, fullName, username, tenantId, phone } = data;

        // Validate required fields
        if (!email || !password || !fullName || !username || !tenantId) {
            return res.json({
                success: false,
                error: 'Missing required fields: email, password, fullName, username, tenantId'
            }, 400);
        }

        log(`Creating tenant user: ${email}`);

        // Initialize Appwrite SDK with API key
        const client = new sdk.Client()
            .setEndpoint(process.env.APPWRITE_ENDPOINT || 'https://fra.cloud.appwrite.io/v1')
            .setProject(process.env.APPWRITE_PROJECT_ID || 'perojek-pml')
            .setKey(req.headers['x-appwrite-key'] || '');

        const users = new sdk.Users(client);
        const databases = new sdk.Databases(client);

        // Step 1: Create Auth user
        log('Step 1: Creating Auth account...');
        const authUser = await users.create(
            sdk.ID.unique(),
            email,
            phone,
            password,
            fullName
        );

        log(`Auth user created: ${authUser.$id}`);

        // Step 2: Create user document in database
        log('Step 2: Creating user document...');
        const userDoc = await databases.createDocument(
            process.env.DATABASE_ID || 'kantin-db',
            'users',
            authUser.$id, // Use same ID as Auth user
            {
                user_id: authUser.$id,
                role: 'tenant',
                full_name: fullName,
                username: username,
                email: email,
                phone: phone || '',
                tenant_id: tenantId,
                is_active: true,
            }
        );

        log(`User document created: ${userDoc.$id}`);

        // Return success response
        return res.json({
            success: true,
            userId: authUser.$id,
            message: `User ${fullName} created successfully`
        });

    } catch (err) {
        error(`Function error: ${err.message}`);

        return res.json({
            success: false,
            error: err.message,
            code: err.code || 'unknown_error'
        }, 500);
    }
};
