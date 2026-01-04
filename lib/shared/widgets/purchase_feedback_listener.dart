import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kantin_app/core/utils/purchase_result_notifier.dart';
import 'package:kantin_app/main.dart'; // Import for scaffoldMessengerKey

/// Wrapper widget that listens to global purchase results and shows SnackBars
class PurchaseFeedbackListener extends StatefulWidget {
  final Widget child;
  
  const PurchaseFeedbackListener({
    super.key,
    required this.child,
  });

  @override
  State<PurchaseFeedbackListener> createState() => _PurchaseFeedbackListenerState();
}

class _PurchaseFeedbackListenerState extends State<PurchaseFeedbackListener> {
  StreamSubscription<PurchaseResult>? _subscription;

  @override
  void initState() {
    super.initState();
    
    // Listen to purchase results
    _subscription = PurchaseResultNotifier.stream.listen((result) {
      print('[UI] Purchase result received: ${result.type}');
      
      // Use global ScaffoldMessengerKey instead of context
      final messenger = scaffoldMessengerKey.currentState;
      
      if (messenger == null) {
        print('[UI] ScaffoldMessenger not available yet');
        return;
      }
      
      switch (result.type) {
        case PurchaseResultType.success:
          print('[UI] Showing success SnackBar for: ${result.productId}');
          messenger.showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '✅ Pembayaran berhasil! Subscription aktif.',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
          break;
          
        case PurchaseResultType.error:
          print('[UI] Showing error SnackBar: ${result.message}');
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '❌ Pembayaran gagal: ${result.message}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
          break;
          
        case PurchaseResultType.cancelled:
          print('[UI] Showing cancelled SnackBar');
          messenger.showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    '⚠️ Pembayaran dibatalkan',
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          break;
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
