import 'dart:async';

/// Global purchase result notifier for showing feedback across the app
/// Used to show SnackBars after purchase completion even after dialogs are closed
class PurchaseResultNotifier {
  static final _controller = StreamController<PurchaseResult>.broadcast();
  
  static Stream<PurchaseResult> get stream => _controller.stream;
  
  static void notifySuccess(String productId) {
    _controller.add(PurchaseResult.success(productId));
  }
  
  static void notifyError(String error) {
    _controller.add(PurchaseResult.error(error));
  }
  
  static void notifyCancelled() {
    _controller.add(PurchaseResult.cancelled());
  }
  
  static void dispose() {
    _controller.close();
  }
}

class PurchaseResult {
  final PurchaseResultType type;
  final String? message;
  final String? productId;
  
  PurchaseResult.success(this.productId) 
    : type = PurchaseResultType.success,
      message = null;
      
  PurchaseResult.error(this.message) 
    : type = PurchaseResultType.error,
      productId = null;
      
  PurchaseResult.cancelled() 
    : type = PurchaseResultType.cancelled,
      message = null,
      productId = null;
}

enum PurchaseResultType {
  success,
  error,
  cancelled,
}
