import 'package:appwrite/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartNotifier extends StateNotifier<List<Document>> {
  CartNotifier() : super([]);

  void add(Document product) {
    state = [...state, product];
  }

  void remove(Document product) {
    state = state.where((p) => p.$id != product.$id).toList();
  }

  void clear() {
    state = [];
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<Document>>((ref) {
  return CartNotifier();
});
