# create-midtrans-payment

Appwrite Function to generate Midtrans Snap payment token.

## Environment Variables Required

```env
# Appwrite
APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=your-project-id
APPWRITE_API_KEY=your-api-key
DATABASE_ID=your-database-id
ORDERS_COLLECTION_ID=your-orders-collection-id

# Midtrans (Sandbox for testing)
MIDTRANS_IS_PRODUCTION=false
MIDTRANS_SERVER_KEY=SB-Mid-server-xxxxx
MIDTRANS_CLIENT_KEY=SB-Mid-client-xxxxx
```

## Request

```json
{
  "orderId": "694cd80fed8c89a8344e"
}
```

## Response (Success)

```json
{
  "success": true,
  "snapToken": "66e4fa55-fdac-4ef9-91b5-733b97d1b862",
  "redirectUrl": "https://app.sandbox.midtrans.com/snap/v3/redirection/66e4fa55...",
  "orderId": "694cd80fed8c89a8344e",
  "orderNumber": "ORD-20251225-143547-650"
}
```

## Response (Error)

```json
{
  "success": false,
  "error": "Order not found"
}
```
