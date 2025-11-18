import { Client, Users, Databases, ID, Permission, Role } from 'node-appwrite';

export default async ({ req, res, log, error }) => {
  const client = new Client();
  client
    .setEndpoint(process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

  const users = new Users(client);
  const databases = new Databases(client);

  try {
    // --- LANGKAH DIAGNOSTIK: LOG SEMUANYA ---
    log('--- MEMULAI DIAGNOSTIK PERMINTAAN ---');
    log('Tipe req.body:', typeof req.body, 'Isi:', JSON.stringify(req.body ?? null));
    log('Tipe req.data:', typeof req.data, 'Isi:', JSON.stringify(req.data ?? null));
    log('Tipe req.payload:', typeof req.payload, 'Isi:', JSON.stringify(req.payload ?? null));
    log('Tipe req.bodyRaw:', typeof req.bodyRaw, 'Isi:', req.bodyRaw);
    log('--- AKHIR DIAGNOSTIK ---');
    // ------------------------------------------

    let payload;
    let rawData = req.bodyRaw || req.payload || req.data || '{}';

    // Jika rawData sudah berupa object (bukan string), langsung gunakan.
    if (typeof rawData === 'object' && rawData !== null) {
      payload = rawData;
    } else {
      // Jika masih string, parse.
      payload = JSON.parse(rawData);
    }
    
    const { tenantName, tenantEmail, tenantPassword } = payload;
    
    log('Payload yang berhasil di-parse:', payload);

    if (!tenantName || !tenantEmail || !tenantPassword) {
      error('Payload tidak lengkap setelah di-parse.', payload);
      return res.json({ success: false, message: 'Data yang dikirim tidak lengkap.'}, 400);
    }

    const businessOwnerId = req.headers['x-appwrite-user-id'];
    if (!businessOwnerId) {
      error('Tidak ada otorisasi dari Business Owner.');
      return res.json({ success: false, message: 'Akses tidak diizinkan.' }, 401);
    }

    // Bagian ini sudah benar dan tidak perlu diubah
    const newTenantUser = await users.create(ID.unique(), tenantEmail, null, tenantPassword, tenantName);
    log(`User '${tenantName}' berhasil dibuat.`);
    
    await users.updateLabels(newTenantUser.$id, ['tenant']);
    await users.updateVerification(newTenantUser.$id, true);
    log(`User '${tenantName}' berhasil diverifikasi.`);

    // Data tenant disesuaikan dengan skema di data.md
    // Schema membutuhkan: name (required), owner_user_id (required)
    // owner_user_id = ID Business Owner yang membuat tenant ini (untuk query tenant milik business owner)
    // userId = ID user tenant yang baru dibuat (untuk menghubungkan dengan user tenant)
    const tenantData = {
      name: tenantName,
      logoUrl: 'https://img.ly/30', // Placeholder URL short (opsional, bisa diupdate tenant)
      owner_user_id: businessOwnerId, // ID Business Owner yang membuat tenant (REQUIRED untuk query)
      userId: newTenantUser.$id, // ID user tenant yang baru dibuat (opsional, untuk referensi)
    };
    
    log('Data tenant yang akan dibuat:', JSON.stringify(tenantData));
    log('Database ID:', process.env.APPWRITE_DATABASE_ID);
    log('Collection ID: tenants');

    try {
      // Buat dokumen dengan data esensial dan izin yang benar
      const tenantDocument = await databases.createDocument(
        process.env.APPWRITE_DATABASE_ID, 
        'tenants', 
        ID.unique(), 
        tenantData,
        [
          Permission.read(Role.user(businessOwnerId)),
          Permission.update(Role.user(businessOwnerId)),
          Permission.delete(Role.user(businessOwnerId)),
          Permission.read(Role.user(newTenantUser.$id)),
          Permission.update(Role.user(newTenantUser.$id)),
        ]
      );
      log(`Dokumen tenant '${tenantName}' berhasil dibuat dengan ID: ${tenantDocument.$id}`);

      return res.json({ 
        success: true, 
        message: `Tenant ${tenantName} berhasil dibuat!`, 
        data: tenantDocument 
      });
    } catch (docError) {
      error('Error saat membuat dokumen tenant:', docError);
      // Jika gagal membuat dokumen, hapus user yang sudah dibuat untuk menjaga konsistensi
      try {
        await users.delete(newTenantUser.$id);
        log('User yang sudah dibuat dihapus karena gagal membuat dokumen tenant');
      } catch (deleteError) {
        error('Gagal menghapus user setelah error:', deleteError);
      }
      throw docError; // Re-throw untuk ditangani di catch utama
    }

  } catch (e) {
    error('Terjadi error fatal:', e);
    error('Stack trace:', e.stack);
    return res.json({ 
      success: false, 
      message: e.message || 'Terjadi kesalahan saat membuat tenant',
      error: e.toString(),
    }, 500);
  }
}