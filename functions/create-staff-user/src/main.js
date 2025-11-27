const sdk = require("node-appwrite");

module.exports = async ({ req, res, log, error }) => {
  try {
    log("Function started");
    log("Raw payload:" + req.body);

    const client = new sdk.Client()
      .setEndpoint(process.env.APPWRITE_FUNCTION_API_ENDPOINT)
      .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
      .setKey(process.env.APPWRITE_FUNCTION_API_KEY);

    const databases = new sdk.Databases(client);
    const users = new sdk.Users(client);

    const data = typeof req.body === "string" ? JSON.parse(req.body) : req.body;
    log("Parsed data: " + JSON.stringify(data));

    let { email, password, full_name, username, phone, tenant_id, created_by, labels } = data;

    // Normalize phone: convert 08xxx to +628xxx
    if (phone && phone.startsWith("0")) {
      phone = "+62" + phone.substring(1);
      log("Normalized phone: " + phone);
    }

    if (!email || !password || !full_name || !username || !tenant_id || !created_by) {
      log("Missing fields");
      return res.json({
        success: false,
        error: "Missing required fields"
      }, 400);
    }

    const userLabels = labels && Array.isArray(labels) && labels.length > 0 ? labels : ["tenant"];

    if (username.length < 3) {
      return res.json({ success: false, error: "Username too short" }, 400);
    }

    if (password.length < 8) {
      return res.json({ success: false, error: "Password too short" }, 400);
    }

    log("Creating staff user: " + username);

    try {
      const existingUsers = await databases.listDocuments(
        process.env.DATABASE_ID,
        process.env.USERS_COLLECTION_ID,
        [sdk.Query.equal("username", username)]
      );

      if (existingUsers.total > 0) {
        return res.json({ success: false, error: "Username exists" }, 409);
      }
    } catch (err) {
      error("Error checking username: " + err.message);
    }

    let authUser;
    try {
      authUser = await users.create(
        sdk.ID.unique(),
        email,
        phone || undefined,
        password,
        full_name
      );
      log("Auth user created: " + authUser.$id);
    } catch (err) {
      error("Error creating auth user: " + err.message);
      return res.json({ success: false, error: "Failed to create auth user: " + err.message }, 500);
    }

    try {
      await users.updateLabels(authUser.$id, userLabels);
      log("Labels added");
    } catch (err) {
      error("Error adding labels: " + err.message);
    }

    try {
      const userDoc = await databases.createDocument(
        process.env.DATABASE_ID,
        process.env.USERS_COLLECTION_ID,
        sdk.ID.unique(),
        {
          user_id: authUser.$id,
          role: "tenant",
          sub_role: "staff",
          created_by: created_by,
          username: username,
          full_name: full_name,
          email: email,
          phone: phone || null,
          tenant_id: tenant_id,
          contract_end_date: null,
          is_active: true
        }
      );

      log("User document created: " + userDoc.$id);

      return res.json({
        success: true,
        user_id: authUser.$id,
        document_id: userDoc.$id,
        message: "Staff user created successfully"
      }, 201);

    } catch (err) {
      error("Error creating document: " + err.message);

      try {
        await users.delete(authUser.$id);
        log("Rolled back");
      } catch (rollbackError) {
        error("Failed to rollback: " + rollbackError.message);
      }

      return res.json({ success: false, error: "Failed to create document: " + err.message }, 500);
    }

  } catch (err) {
    error("Unexpected error: " + err.message);
    return res.json({ success: false, error: err.message || "Internal error" }, 500);
  }
};