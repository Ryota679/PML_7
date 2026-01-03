import { Client, Users } from 'node-appwrite';

export default async ({ req, res, log, error }) => {
  const client = new Client();
  client
    .setEndpoint(process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

  const users = new Users(client);

  try {
    let payload;
    const rawData = req.bodyRaw || req.payload || req.data || '{}';

    if (typeof rawData === 'object' && rawData !== null) {
      payload = rawData;
    } else {
      payload = JSON.parse(rawData);
    }

    const { userId } = payload;

    if (!userId) {
      error('User ID tidak diberikan');
      return res.json({ success: false, message: 'User ID diperlukan' }, 400);
    }

    log(`Mengaktifkan Business Owner untuk user: ${userId}`);

    // Update label user menjadi 'business_owner'
    await users.updateLabels(userId, ['business_owner']);
    log(`User ${userId} berhasil mendapat label 'business_owner'`);

    // Verifikasi user
    await users.updateVerification(userId, true);
    log(`User ${userId} berhasil diverifikasi`);

    return res.json({
      success: true,
      message: 'Business Owner berhasil diaktifkan!',
      userId: userId,
    });

  } catch (e) {
    error('Terjadi error:', e);
    return res.json({
      success: false,
      message: e.message || 'Terjadi kesalahan saat aktivasi Business Owner',
      error: e.toString(),
    }, 500);
  }
};
