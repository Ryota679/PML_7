# midtrans-webhook-handler

Appwrite Function to handle payment notification webhooks from Midtrans.

## Security Features

- ✅ SHA512 signature verification
- ✅ Amount validation (prevent manipulation)
- ✅ Prevents replay attacks
- ✅ HTTPS only (enforced by Midtrans)

## Environment Variables Required

```env
# Appwrite
APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=your-project-id
APPWRITE_API_KEY=your-api-key
DATABASE_ID=your-database-id
ORDERS_COLLECTION_ID=your-orders-collection-id

# Midtrans
MIDTRANS_SERVER_KEY=SB-Mid-server-xxxxx
```

## Webhook Payload (from Midtrans)

```json
{
  "transaction_time": "2024-12-26 10:30:00",
  "transaction_status": "settlement",
  "transaction_id": "abc123-def456",
  "status_code": "200",
  "signature_key": "abc...",
  "payment_type": "gopay",
  "order_id": "ORD-20251225-143547-650",
  "merchant_id": "G558052335",
  "gross_amount": "6000.00",
  "fraud_status": "accept",
  "currency": "IDR"
}
```

## Response

```json
{
  "success": true,
  "status": "confirmed",
  "message": "Webhook processed successfully"
}
```

## Transaction Status Mapping

| Midtrans Status | Order Status | Notify Tenant? |
|-----------------|--------------|----------------|
| `settlement` | `confirmed` | ✅ Yes |
| `capture` + `accept` | `confirmed` | ✅ Yes |
| `capture` + `challenge` | `pending_payment` | ❌ No |
| `pending` | `pending_payment` | ❌ No |
| `deny` | `cancelled` | ❌ No |
| `expire` | `cancelled` | ❌ No |
| `cancel` | `cancelled` | ❌ No |
| `refund` | `cancelled` | ❌ No |
