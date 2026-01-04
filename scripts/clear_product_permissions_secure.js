#!/usr/bin/env node

/**
 * Appwrite Script: Clear ALL Product Document Permissions (SECURE VERSION)
 * 
 * This script removes ALL document-level permissions from products.
 * With row security OFF, collection-level permissions will apply.
 * 
 * Prerequisites:
 * 1. npm install node-appwrite dotenv
 * 2. Copy .env.example to .env
 * 3. Add your API key to .env file
 * 
 * Usage:
 * node clear_product_permissions_secure.js
 */

require('dotenv').config();
const sdk = require('node-appwrite');

// ===== CONFIGURATION =====
const CONFIG = {
    endpoint: process.env.APPWRITE_ENDPOINT || 'https://fra.cloud.appwrite.io/v1',
    projectId: process.env.APPWRITE_PROJECT_ID || 'perojek-pml',
    databaseId: process.env.APPWRITE_DATABASE_ID || 'kantin-db',
    collectionId: 'products',
    apiKey: process.env.APPWRITE_API_KEY,
};

// Validate API key
if (!CONFIG.apiKey || CONFIG.apiKey === 'your_api_key_here') {
    console.error('❌ ERROR: API key not found!');
    console.error('');
    console.error('Please follow these steps:');
    console.error('1. Copy .env.example to .env');
    console.error('2. Edit .env and add your API key from Appwrite Console');
    console.error('3. Run this script again');
    console.error('');
    process.exit(1);
}

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
