// Crop Guardian - farm expense tracker
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// Fully offline. Writes to the on-device SQLite store so a farmer can record
// a purchase standing at the shop, with no network at all.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/data/local_database.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  static const categories = {
    'Seeds': Icons.grass,
    'Fertiliser': Icons.science_outlined,
    'Pesticide': Icons.pest_control_outlined,
    'Labour': Icons.groups_outlined,
    'Irrigation': Icons.water_drop_outlined,
    'Equipment': Icons.agriculture_outlined,
    'Transport': Icons.local_shipping_outlined,
    'Other': Icons.more_horiz,
  };

  final _db = LocalDatabase.instance;
  List<Map<String, dynamic>> _expenses = [];
  double _total = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _db.expenses();
    final total = await _db.totalSpend();
    if (!mounted) return;
    setState(() {
      _expenses = rows;
      _total = total;
      _loading = false;
    });
  }

  Map<String, double> get _byCategory {
    final map = <String, double>{};
    for (final e in _expenses) {
      final cat = e['category'] as String? ?? 'Other';
      map[cat] = (map[cat] ?? 0) + (e['amount'] as num).toDouble();
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  Future<void> _addExpense() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddExpenseSheet(),
    );
    if (result == null) return;

    await _db.insertExpense({
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'category': result['category'],
      'note': result['note'],
      'amount': result['amount'],
      'spentOn': result['spentOn'],
      'syncedToCloud': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF166534),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Column(
          children: [
            Text('Farm Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('खर्च रिकॉर्ड', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        backgroundColor: const Color(0xFF34D399),
        foregroundColor: const Color(0xFF022C22),
        icon: const Icon(Icons.add),
        label: const Text('Add expense', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                _totalCard(),
                const SizedBox(height: 16),
                if (_byCategory.isNotEmpty) ...[
                  _breakdownCard(),
                  const SizedBox(height: 16),
                ],
                if (_expenses.isEmpty)
                  _emptyState()
                else ...[
                  const Text('Recent',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  ..._expenses.map(_expenseTile),
                ],
              ],
            ),
    );
  }

  Widget _totalCard() => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF022C22),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TOTAL SPENT',
                style: TextStyle(
                    color: Color(0xFF34D399), fontSize: 11, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Text('₹${_total.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone_android, size: 13, color: Color(0xFFA7F3D0)),
                const SizedBox(width: 6),
                Text('${_expenses.length} entries, saved on this phone',
                    style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 12)),
              ],
            ),
          ],
        ),
      );

  Widget _breakdownCard() {
    final entries = _byCategory.entries.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Where the money went',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 14),
          ...entries.map((e) {
            final pct = _total == 0 ? 0.0 : e.value / _total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(categories[e.key] ?? Icons.more_horiz,
                          size: 16, color: const Color(0xFF047857)),
                      const SizedBox(width: 8),
                      Text(e.key, style: const TextStyle(fontSize: 13.5)),
                      const Spacer(),
                      Text('₹${e.value.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text('${(pct * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 12, color: Colors.black45)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFECFDF5),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF34D399)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _expenseTile(Map<String, dynamic> e) {
    final amount = (e['amount'] as num).toDouble();
    final cat = e['category'] as String? ?? 'Other';
    final note = e['note'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFECFDF5),
            child: Icon(categories[cat] ?? Icons.more_horiz,
                size: 18, color: const Color(0xFF047857)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (note.isNotEmpty)
                  Text(note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                Text(e['spentOn'].toString().split('T').first,
                    style: const TextStyle(fontSize: 11, color: Colors.black38)),
              ],
            ),
          ),
          Text('₹${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF022C22))),
        ],
      ),
    );
  }

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 46, color: Colors.green.shade200),
            const SizedBox(height: 14),
            const Text('No expenses recorded yet',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 6),
            const Text(
              'Track seeds, fertiliser, labour and more.\nWorks without internet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
            ),
          ],
        ),
      );
}

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet();

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _category = 'Seeds';
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_amount.text.trim());
    if (value == null || value <= 0) return;
    Navigator.pop(context, {
      'category': _category,
      'note': _note.text.trim(),
      'amount': value,
      'spentOn': _date.toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Add expense',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                hintText: '0',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Category', style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _ExpenseTrackerScreenState.categories.keys.map((c) {
                final active = c == _category;
                return ChoiceChip(
                  label: Text(c),
                  selected: active,
                  onSelected: (_) => setState(() => _category = c),
                  selectedColor: const Color(0xFF34D399),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Color(0xFF047857)),
                  const SizedBox(width: 10),
                  Text(_date.toIso8601String().split('T').first,
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF166534),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}