#!/usr/bin/env node

/**
 * Appwrite Script: Clear ALL Storage File Permissions
 * 
 * This script removes ALL file-level permissions from product-images bucket.
 * With bucket permissions configured, file-level will be ignored.
 */

const sdk = require('node-appwrite');

// ===== CONFIGURATION =====
const CONFIG = {
    endpoint: 'https://fra.cloud.appwrite.io/v1',
    projectId: 'perojek-pml',
    bucketId: 'product-images',
    apiKey: 'standard_58586fe0ba98bf5fade39ca6bc67d43a4215813e9dd7a9adaf9eda3e23dd25ba4c2ef7d31a55c6f4a1c385bc33a166643232cc3a0e22e6a1c5d2d527a8d4aa8595346bae2931f683059d484a2b5a26982d6d7670822a503883d0fe3c0aa0e5327c16e56539b720609918a5639ed03f36a881531f43ca840834e8583ed9f6bf9e',
};

// ===== SCRIPT =====
async function clearAllFilePermissions() {
    console.log('🚀 Clear ALL Storage File Permissions\n');

    // Initialize Appwrite client
    const client = new sdk.Client()
        .setEndpoint(CONFIG.endpoint)
        .setProject(CONFIG.projectId)
        .setKey(CONFIG.apiKey);

    const storage = new sdk.Storage(client);

    try {
        // Step 1: Fetch all files
        console.log('📡 Fetching all files...');

        const response = await storage.listFiles(
            CONFIG.bucketId,
            [sdk.Query.limit(100)]
        );

        const files = response.files;
        console.log(`✅ Found ${files.length} files\n`);

        if (files.length === 0) {
            console.log('⚠️  No files found. Exiting.');
            return;
        }

        // Step 2: Clear permissions for each file
        console.log('🧹 Clearing file permissions...\n');

        let successCount = 0;
        let errorCount = 0;

        for (const file of files) {
            try {
                console.log(`📝 ${file.name} (${file.$id})`);

                // Update with EMPTY permissions array
                await storage.updateFile(
                    CONFIG.bucketId,
                    file.$id,
                    undefined, // name unchanged
                    [] // EMPTY permissions = rely on bucket only
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
        console.log(`   📦 Total: ${files.length}`);
        console.log('═'.repeat(50));

        if (successCount === files.length) {
            console.log('\n🎉 All file permissions cleared!');
            console.log('✅ Bucket permissions will now apply!');
            console.log('✅ Upload should work without 401 errors!');
        } else {
            console.log('\n⚠️  Some files failed. Check errors above.');
        }

    } catch (error) {
        console.error('\n❌ Fatal error:', error.message);
        process.exit(1);
    }
}

// Run the script
console.log('═'.repeat(50));
clearAllFilePermissions().catch(error => {
    console.error('❌ Fatal error:', error);
    process.exit(1);
});
