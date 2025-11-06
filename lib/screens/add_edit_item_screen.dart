import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/firestore_service.dart';

class AddEditItemScreen extends StatefulWidget {
  final Item? existing;
  const AddEditItemScreen({super.key, this.existing});

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _qty = TextEditingController();
  final _price = TextEditingController();
  String _category = 'General';

  final _cats = const ['General', 'Electronics', 'Clothes', 'Grocery'];

  @override
  void initState() {
    super.initState();
    final it = widget.existing;
    if (it != null) {
      _name.text = it.name;
      _qty.text = it.quantity.toString();
      _price.text = it.price.toStringAsFixed(2);
      _category = it.category;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    final svc = FirestoreService.instance;
    final now = DateTime.now();
    final qty = int.tryParse(_qty.text.trim()) ?? 0;
    final pr = double.tryParse(_price.text.trim()) ?? 0.0;

    if (widget.existing == null) {
      // create
      final item = Item(
        name: _name.text.trim(),
        quantity: qty,
        price: pr,
        category: _category,
        createdAt: now,
      );
      await svc.addItem(item);
    } else {
      // update
      final item = Item(
        id: widget.existing!.id,
        name: _name.text.trim(),
        quantity: qty,
        price: pr,
        category: _category,
        createdAt: widget.existing!.createdAt,
      );
      await svc.updateItem(item);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Item' : 'Add Item')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: ListView(
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
                      validator: (v) => (int.tryParse(v ?? '') == null) ? 'Number' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
                      validator: (v) => (double.tryParse(v ?? '') == null) ? 'Number' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                items: _cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v ?? 'General'),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}