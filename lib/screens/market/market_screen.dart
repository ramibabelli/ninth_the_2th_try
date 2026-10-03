import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/product_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_retry.dart';
import '../../widgets/product_card.dart';
import '../../widgets/responsive_page.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProductService>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المتجر'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.storefront_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      body: ResponsivePage(
        child: Consumer<ProductService>(
          builder: (context, service, _) {
            if (service.isLoading && service.products.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (service.error != null && service.products.isEmpty) {
              return ErrorRetry(
                message: service.error!,
                onRetry: service.fetchProducts,
              );
            }
            if (service.products.isEmpty) {
              return RefreshIndicator(
                onRefresh: service.fetchProducts,
                child: const EmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'المتجر فارغ حاليًا',
                  subtitle: 'ستظهر منتجات الفرقة هنا قريبًا.',
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: service.fetchProducts,
              child: GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.72,
                ),
                itemCount: service.products.length,
                itemBuilder: (context, index) {
                  return ProductCard(product: service.products[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}