import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/item.dart';
import '../services/firestore_service.dart';

class AddEditItemScreen extends StatefulWidget {
  final Item? existing;
  final FirebaseAnalytics? analytics;
  const AddEditItemScreen({super.key, this.existing, this.analytics});

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _qty = TextEditingController();
  final _price = TextEditingController();
  final _category = TextEditingController();
  final _service = FirestoreService();

  static const _presetCats = [
    'Produce','Beverages','Bakery','Dairy','Snacks',
    'Electronics','Household','Clothing','Other'
  ];
  String _catPick = 'Produce';

  @override
  void initState() {
    super.initState();
    final it = widget.existing;
    if (it != null) {
      _name.text = it.name;
      _qty.text = it.quantity.toString();
      _price.text = it.price.toStringAsFixed(2);
      _category.text = it.category;
      _catPick = _presetCats.contains(it.category) ? it.category : 'Other';
    }
  }

  @override
  void dispose() {
    _name.dispose(); _qty.dispose(); _price.dispose(); _category.dispose();
    super.dispose();
  }

  String _finalCategory() {
    if (_catPick == 'Other') {
      final v = _category.text.trim();
      return v.isEmpty ? 'Other' : v;
    }
    return _catPick;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final item = Item(
      id: widget.existing?.id,
      name: _name.text.trim(),
      quantity: int.parse(_qty.text),
      price: double.parse(_price.text),
      category: _finalCategory(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    if (widget.existing == null) {
      final id = await _service.addItem(item);
      widget.analytics?.logEvent(name: 'add_item', parameters: {'id': id});
      if (!mounted) return;
      Navigator.pop<String?>(context, id);
    } else {
      await _service.updateItem(item);
      widget.analytics?.logEvent(name: 'edit_item', parameters: {'id': item.id ?? ''});
      if (!mounted) return;
      Navigator.pop<bool>(context, true);
    }
  }

  Future<void> _delete() async {
    if (widget.existing?.id == null) return;
    await _service.deleteItem(widget.existing!.id!);
    widget.analytics?.logEvent(name: 'delete_item', parameters: {'id': widget.existing!.id!});
    if (!mounted) return;
    Navigator.pop<bool>(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Item' : 'Add Item'),
        actions: [
          if (isEdit)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete'),
                    content: Text('Delete "${_name.text}"?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (ok == true) await _delete();
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qty,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _catPick,
              items: _presetCats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _catPick = v ?? 'Produce'),
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            if (_catPick == 'Other')
              TextFormField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Custom Category', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a category' : null,
              ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(isEdit ? 'Save Changes' : 'Add Item', style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}