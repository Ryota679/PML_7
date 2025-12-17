#!/usr/bin/env node

/**
 * Appwrite Script: Clear ALL Product Document Permissions
 * 
 * This script removes ALL document-level permissions from products.
 * With row security OFF, collection-level permissions will apply.
 * 
 * Prerequisites:
 * 1. npm install node-appwrite (already done)
 * 2. API key configured (already done)
 * 
 * Usage:
 * node clear_product_permissions.js
 */

const sdk = require('node-appwrite');

// ===== CONFIGURATION =====
const CONFIG = {
    endpoint: 'https://cloud.appwrite.io/v1',
    projectId: 'perojek-pml',
    databaseId: 'kantin-db',
    collectionId: 'products',
    apiKey: 'standard_58586fe0ba98bf5fade39ca6bc67d43a4215813e9dd7a9adaf9eda3e23dd25ba4c2ef7d31a55c6f4a1c385bc33a166643232cc3a0e22e6a1c5d2d527a8d4aa8595346bae2931f683059d484a2b5a26982d6d7670822a503883d0fe3c0aa0e5327c16e56539b720609918a5639ed03f36a881531f43ca840834e8583ed9f6bf9e',
};

// ===== SCRIPT =====
async function clearAllProductPermissions() {
    console.log('🚀 Clear ALL Product Document Permissions\n');
    console.log('📌 Strategy: Remove document permissions, rely on collection permissions\n');

    // Initialize Appwrite client
    const client = new sdk.Client()
        .setEndpoint(CONFIG.endpoint)
        .setProject(CONFIG.projectId)
        .setKey(CONFIG.apiKey);

    const databases = new sdk.Databases(client);

    try {
        // Step 1: Fetch all products
        console.log('📡 Fetching all products...');

        const response = await databases.listDocuments(
            CONFIG.databaseId,
            CONFIG.collectionId,
            [sdk.Query.limit(100)]
        );

        const products = response.documents;
        console.log(`✅ Found ${products.length} products\n`);

        if (products.length === 0) {
            console.log('⚠️  No products found. Exiting.');
            return;
        }

        // Step 2: Clear permissions for each product
        console.log('🧹 Clearing document permissions...\n');

        let successCount = 0;
        let errorCount = 0;

        for (const product of products) {
            try {
                console.log(`📝 ${product.name} (${product.$id})`);

                // Update with EMPTY permissions array = clear all document permissions
                await databases.updateDocument(
                    CONFIG.databaseId,
                    CONFIG.collectionId,
                    product.$id,
                    {}, // No data changes
                    [] // EMPTY permissions = rely on collection only
                );

                console.log(`   ✅ Permissions cleared\n`);
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
            console.log('\n🎉 All product permissions cleared!');
            console.log('✅ Collection permissions (Users role) will now apply!');
            console.log('✅ Auto-deactivation should work without 401 errors!');
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
clearAllProductPermissions().catch(error => {
    console.error('❌ Fatal error:', error);
    process.exit(1);
});
