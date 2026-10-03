import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

class ProductService extends ChangeNotifier {
  final SupabaseClient _client;

  List<Product> _products = const [];
  bool _isLoading = false;
  String? _error;

  ProductService(this._client);

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _client
          .from('products')
          .select()
          .order('created_at', ascending: false);
      _products = data
          .map((row) =>
              Product.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (error) {
      _error = error.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => fetchProducts();
}