import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/item.dart';

class DashboardScreen extends StatelessWidget {
  static const route = '/dashboard';
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: StreamBuilder<List<Item>>(
        stream: FirestoreService.instance.itemsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final items = snap.data ?? [];

          final totalItems = items.length;
          final totalValue = items.fold<double>(0, (sum, it) => sum + (it.price * it.quantity));
          final outOfStock = items.where((it) => it.quantity <= 0).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatCard(title: 'Total Items', value: '$totalItems'),
              const SizedBox(height: 12),
              _StatCard(title: 'Total Value', value: '\$${totalValue.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Out of Stock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (outOfStock.isEmpty)
                        const Text('None 🎉')
                      else
                        ...outOfStock.map((it) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(it.name),
                              subtitle: Text(it.category),
                            )),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}