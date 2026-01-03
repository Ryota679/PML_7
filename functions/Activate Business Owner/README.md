# Activate Business Owner Function

This Appwrite Function activates a Business Owner account by setting the appropriate label.

## Configuration

This function requires the following environment variables:
- `APPWRITE_ENDPOINT`: Your Appwrite endpoint
- `APPWRITE_PROJECT_ID`: Your Appwrite project ID
- `APPWRITE_API_KEY`: Your Appwrite API key with `users.write` permission

## Usage

Send a POST request with the following JSON payload:

```json
{
  "userId": "user-id-to-activate"
}
```

## Response

Success:
```json
{
  "success": true,
  "message": "Business Owner berhasil diaktifkan!",
  "userId": "user-id"
}
```

Error:
```json
{
  "success": false,
  "message": "Error message"
}
```
