#!/usr/bin/env node

/**
 * Appwrite CLI Script: Auto-Fix Product Permissions
 * 
 * This script automatically fetches ALL products and updates their permissions.
 * NO MANUAL COPYING NEEDED!
 * 
 * Prerequisites:
 * 1. Install dependencies: npm install node-appwrite
 * 2. Install Appwrite CLI: npm install -g appwrite-cli
 * 3. Login to Appwrite: appwrite login
 * 4. Update CONFIG below with your project details
 * 
 * Usage:
 * node fix_product_permissions.js
 */

const sdk = require('node-appwrite');

// ===== CONFIGURATION =====
const CONFIG = {
    endpoint: 'https://cloud.appwrite.io/v1',
    projectId: 'perojek-pml',  // Fixed: was 'proyek-pml'
    databaseId: 'kantin-db',
    collectionId: 'products',

    // Get API key from Appwrite Console → Settings → API Keys
    // Create new key with scope: databases.read, databases.write
    apiKey: 'standard_58586fe0ba98bf5fade39ca6bc67d43a4215813e9dd7a9adaf9eda3e23dd25ba4c2ef7d31a55c6f4a1c385bc33a166643232cc3a0e22e6a1c5d2d527a8d4aa8595346bae2931f683059d484a2b5a26982d6d7670822a503883d0fe3c0aa0e5327c16e56539b720609918a5639ed03f36a881531f43ca840834e8583ed9f6bf9e',
};

// Permissions to set
const PERMISSIONS = [
    sdk.Permission.read(sdk.Role.any()),
    sdk.Permission.update(sdk.Role.users()),
    sdk.Permission.delete(sdk.Role.users()),
];

// ===== SCRIPT =====
async function fixProductPermissions() {
    console.log('🚀 Auto-Fix Product Permissions\n');

    // Validate configuration
    if (CONFIG.apiKey === 'YOUR_API_KEY_HERE') {
        console.log('❌ ERROR: Please set your API key in CONFIG');
        console.log('   1. Go to Appwrite Console → Settings → API Keys');
        console.log('   2. Create new API key with scopes: databases.read, databases.write');
        console.log('   3. Copy the key and paste it in CONFIG.apiKey\n');
        process.exit(1);
    }

    // Initialize Appwrite client
    const client = new sdk.Client()
        .setEndpoint(CONFIG.endpoint)
        .setProject(CONFIG.projectId)
        .setKey(CONFIG.apiKey);

    const databases = new sdk.Databases(client);

    try {
        // Step 1: Fetch all products
        console.log('📡 Fetching all products from database...');

        const response = await databases.listDocuments(
            CONFIG.databaseId,
            CONFIG.collectionId,
            [
                sdk.Query.limit(100),  // Adjust if you have more than 100 products
            ]
        );

        const products = response.documents;
        console.log(`✅ Found ${products.length} products\n`);

        if (products.length === 0) {
            console.log('⚠️  No products found. Exiting.');
            return;
        }

        // Step 2: Update each product
        console.log('🔧 Updating permissions...\n');

        let successCount = 0;
        let errorCount = 0;

        for (const product of products) {
            try {
                console.log(`📝 ${product.name} (${product.$id})`);

                await databases.updateDocument(
                    CONFIG.databaseId,
                    CONFIG.collectionId,
                    product.$id,
                    {}, // No data changes, just permissions
                    PERMISSIONS
                );

                console.log(`   ✅ Success\n`);
                successCount++;

            } catch (error) {
                console.error(`   ❌ Error: ${error.message}\n`);
                errorCount++;
            }
        }

        // Step 3: Summary
        console.log('═'.repeat(50));
        console.log('📊 Summary:');
        console.log(`   ✅ Success: ${successCount}`);
        console.log(`   ❌ Errors: ${errorCount}`);
        console.log(`   📦 Total: ${products.length}`);
        console.log('═'.repeat(50));

        if (successCount === products.length) {
            console.log('\n🎉 All products updated successfully!');
            console.log('✅ Auto-deactivation should now work without permission errors!');
        } else {
            console.log('\n⚠️  Some products failed. Check errors above.');
        }

    } catch (error) {
        console.error('\n❌ Fatal error:', error.message);
        process.exit(1);
    }
}

// Run the script
console.log('═'.repeat(50));
fixProductPermissions().catch(error => {
    console.error('❌ Fatal error:', error);
    process.exit(1);
});
