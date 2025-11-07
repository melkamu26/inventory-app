import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/item.dart';
import '../services/firestore_service.dart';

class StatsDashboardScreen extends StatelessWidget {
  final FirebaseAnalytics? analytics;
  StatsDashboardScreen({super.key, this.analytics});

  final _service = FirestoreService();

  @override
  Widget build(BuildContext context) {
    analytics?.logScreenView(screenName: 'StatsDashboardScreen', screenClass: 'StatsDashboardScreen');
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Analytics')),
      body: StreamBuilder<List<Item>>(
        stream: _service.itemsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final items = snap.data ?? [];

          final totalItems = items.length;
          final totalValue = items.fold<double>(0.0, (s, it) => s + (it.price * it.quantity));
          final outOfStock = items.where((it) => it.quantity <= 0).toList();

          final Map<String, int> catCounts = {};
          for (final it in items) {
            catCounts[it.category] = (catCounts[it.category] ?? 0) + 1;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 12, runSpacing: 12,
                children: [
                  _metric('Total Items', '$totalItems', Colors.indigo),
                  _metric('Total Value', '\$${totalValue.toStringAsFixed(2)}', Colors.teal),
                  _metric('Out of Stock', '${outOfStock.length}', Colors.red),
                ],
              ),
              const SizedBox(height: 24),
              Text('By Category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: catCounts.entries.map((e) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.key),
                      trailing: Text(e.value.toString()),
                    )).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Out of Stock', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (outOfStock.isEmpty)
                const Text('No items are out of stock.')
              else
                Card(
                  elevation: 1,
                  child: Column(
                    children: outOfStock.map((it) => ListTile(
                      title: Text(it.name),
                      subtitle: Text('${it.category} • \$${it.price.toStringAsFixed(2)}'),
                      trailing: const Text('Qty 0'),
                    )).toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return SizedBox(
      width: 180,
      child: Card(
        color: color.withOpacity(.08),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}