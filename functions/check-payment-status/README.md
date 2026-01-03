# check-payment-status

Check Midtrans payment status and update order status in Appwrite database.

## Purpose

This function queries the Midtrans Transaction Status API to check the current status of a payment and updates the corresponding order in the Appwrite database. This is an alternative to webhook-based status updates that gives the Flutter app more control.

## Environment Variables

Required environment variables (same as create-midtrans-payment):

```bash
APPWRITE_ENDPOINT=https://fra.cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=your_project_id
APPWRITE_API_KEY=your_api_key
DATABASE_ID=your_database_id
ORDERS_COLLECTION_ID=your_orders_collection_id
MIDTRANS_IS_PRODUCTION=false
MIDTRANS_SERVER_KEY=your_server_key
MIDTRANS_CLIENT_KEY=your_client_key
```

## Request

**Method:** POST

**Body:**
```json
{
  "orderId": "694e9ff90008d656c1d7"
}
```

## Response

**Success (200):**
```json
{
  "success": true,
  "orderId": "694e9ff90008d656c1d7",
  "invoiceNumber": "INV-20251226-P3QAYVO",
  "transactionStatus": "settlement",
  "orderStatus": "confirmed",
  "paymentType": "credit_card",
  "grossAmount": "125000.00",
  "updatedAt": "2025-12-27T12:00:00.000Z"
}
```

**Error (400/404/500):**
```json
{
  "error": "Error type",
  "message": "Error description"
}
```

## Status Mapping

| Midtrans Status | Order Status |
|----------------|--------------|
| `settlement` | `confirmed` |
| `capture` (fraud_status: accept) | `confirmed` |
| `capture` (fraud_status: challenge/deny) | `pending_payment` |
| `pending` | `pending_payment` |
| `deny`, `cancel`, `expire` | `cancelled` |

## Usage in Flutter App

After user completes payment in Snap, call this function to check status and update order:

```dart
final result = await functions.createExecution(
  functionId: 'check-payment-status-function-id',
  body: jsonEncode({'orderId': orderId}),
);

final response = jsonDecode(result.responseBody);
if (response['orderStatus'] == 'confirmed') {
  // Show success UI
}
```

## Benefits

- ✅ No webhook 401 errors
- ✅ Immediate feedback after payment
- ✅ Can retry if network fails
- ✅ Full control from Flutter app
