import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/item.dart';
import '../services/firestore_service.dart';
import 'add_edit_item_screen.dart';
import 'stats_dashboard_screen.dart';

class InventoryHomePage extends StatefulWidget {
  final FirebaseAnalytics? analytics;
  const InventoryHomePage({super.key, this.analytics});

  @override
  State<InventoryHomePage> createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final _service = FirestoreService();
  final _searchCtrl = TextEditingController();

  static const List<String> _baseCats = [
    'All','Produce','Beverages','Bakery','Dairy',
    'Snacks','Electronics','Household','Clothing','Other'
  ];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    widget.analytics?.logScreenView(
      screenName: 'InventoryHomePage', screenClass: 'InventoryHomePage');
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _openAdd() async {
    final createdId = await Navigator.push<String?>(
      context, MaterialPageRoute(builder: (_) => const AddEditItemScreen()));
    if (!mounted) return;
    if (createdId != null) {
      widget.analytics?.logEvent(name: 'add_item', parameters: {'id': createdId});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added')));
    }
  }

  void _openEdit(Item it) async {
    widget.analytics?.logEvent(name: 'open_item', parameters: {'id': it.id ?? ''});
    final updated = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(builder: (_) => AddEditItemScreen(existing: it, analytics: widget.analytics)),
    );
    if (!mounted) return;
    if (updated == true) {
      widget.analytics?.logEvent(name: 'edit_item', parameters: {'id': it.id ?? ''});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated')));
    }
  }

  Future<void> _delete(Item it) async {
    await _service.deleteItem(it.id!);
    widget.analytics?.logEvent(name: 'delete_item', parameters: {'id': it.id ?? ''});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item deleted')));
  }

  void _openStats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StatsDashboardScreen(analytics: widget.analytics)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.25);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          // keep icon in app bar (existing behavior)
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: 'Analytics',
            onPressed: _openStats,
          ),
        ],
      ),
      body: Column(
        children: [
          // TOP ACTION ROW (Add Item + Analytics with words)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _openAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _openStats,
                  icon: const Icon(Icons.insights_outlined),
                  label: const Text('Analytics'),
                ),
                const Spacer(),
              ],
            ),
          ),

          // SEARCH
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (txt) {
                setState(() {});
                widget.analytics?.logEvent(name: 'search', parameters: {'q': txt});
              },
            ),
          ),

          // CATEGORY CHIPS
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: StreamBuilder<List<Item>>(
              stream: _service.itemsStream(),
              builder: (context, snap) {
                final all = snap.data ?? [];
                final dynamicCats = all
                    .map((e) => e.category.trim())
                    .where((c) => c.isNotEmpty && c.toLowerCase() != 'all')
                    .toSet();
                final cats = <String>{..._baseCats, ...dynamicCats}.toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: cats.map((cat) {
                      final selected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _selectedCategory = cat);
                            widget.analytics?.logEvent(
                              name: 'select_category', parameters: {'category': cat});
                          },
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          selectedColor: primary,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: primary.withOpacity(.25)),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),

          // LIST
          Expanded(
            child: StreamBuilder<List<Item>>(
              stream: _service.itemsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                final items = snap.data ?? [];

                final q = _searchCtrl.text.trim().toLowerCase();
                final bySearch = q.isEmpty
                    ? items
                    : items.where((e) => e.name.toLowerCase().contains(q)).toList();
                final filtered = (_selectedCategory == 'All')
                    ? bySearch
                    : bySearch.where((e) => e.category == _selectedCategory).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No items found'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final it = filtered[i];
                    return Dismissible(
                      key: ValueKey(it.id ?? '$i'),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: Colors.red.shade400,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete'),
                            content: Text('Delete "${it.name}"?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (ok == true) await _delete(it);
                        return ok ?? false;
                      },
                      child: Card(
                        color: Colors.white,
                        elevation: 1.25,
                        child: ListTile(
                          title: Text(it.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('Qty: ${it.quantity} • \$${it.price.toStringAsFixed(2)} • ${it.category}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openEdit(it),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Delete'),
                                      content: Text('Delete "${it.name}"?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                      ],
                                    ),
                                  );
                                  if (ok == true) await _delete(it);
                                },
                              ),
                            ],
                          ),
                          onTap: () => _openEdit(it),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _openAdd, child: const Icon(Icons.add)),
    );
  }
}