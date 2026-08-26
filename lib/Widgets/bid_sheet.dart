// Crop Guardian - bidding sheet
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/marketplace/bid_service.dart';
import '../core/user/role_controller.dart';

class BidSheet extends StatefulWidget {
  final String listingId;
  final String cropName;
  final double askingPrice;
  final String sellerId;

  const BidSheet({
    super.key,
    required this.listingId,
    required this.cropName,
    required this.askingPrice,
    required this.sellerId,
  });

  static Future<void> show(
    BuildContext context, {
    required String listingId,
    required String cropName,
    required double askingPrice,
    required String sellerId,
  }) =>
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => BidSheet(
          listingId: listingId,
          cropName: cropName,
          askingPrice: askingPrice,
          sellerId: sellerId,
        ),
      );

  @override
  State<BidSheet> createState() => _BidSheetState();
}

class _BidSheetState extends State<BidSheet> {
  final _amount = TextEditingController();
  bool _placing = false;
  String _error = '';

  bool get _isOwnListing =>
      widget.sellerId == FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _placeBid() async {
    final value = double.tryParse(_amount.text.trim());
    if (value == null) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }

    setState(() { _placing = true; _error = ''; });

    final name = FirebaseAuth.instance.currentUser?.displayName ??
        FirebaseAuth.instance.currentUser?.email?.split('@').first ??
        'Buyer';

    final err = await BidService.instance.placeBid(
      listingId: widget.listingId,
      amount: value,
      bidderName: name,
      askingPrice: widget.askingPrice,
    );

    if (!mounted) return;
    setState(() { _placing = false; _error = err ?? ''; });
    if (err == null) _amount.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
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
            const SizedBox(height: 16),
            Text(widget.cropName,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            Text('Asking Rs ${widget.askingPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 16),
            if (!_isOwnListing && RoleController.instance.isBuyer) _bidInput(),
            if (_isOwnListing)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 17, color: Color(0xFF047857)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('This is your listing. Bids appear below.',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            if (!_isOwnListing && RoleController.instance.isFarmer)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 17, color: Colors.orange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          'Switch to Buyer in the menu to place a bid.',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            const Text('Bids',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Flexible(child: _bidList()),
          ],
        ),
      ),
    );
  }

  Widget _bidInput() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              prefixText: 'Rs ',
              hintText: 'Your bid',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_error,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12.5)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _placing ? null : _placeBid,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(_placing ? 'Placing...' : 'Place bid',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );

  Widget _bidList() => StreamBuilder<List<Bid>>(
        stream: BidService.instance.bidStream(widget.listingId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final bids = snap.data ?? [];
          if (bids.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: Text('No bids yet. Be the first.',
                    style: TextStyle(color: Colors.black54, fontSize: 13.5)),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            itemCount: bids.length,
            itemBuilder: (_, i) {
              final b = bids[i];
              final isTop = i == 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: isTop ? const Color(0xFFECFDF5) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isTop
                        ? const Color(0xFF34D399)
                        : Colors.grey.shade300,
                    width: isTop ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (isTop)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.emoji_events,
                            size: 17, color: Color(0xFF047857)),
                      ),
                    Expanded(
                      child: Text(
                        b.isMine ? '${b.bidderName} (you)' : b.bidderName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text('Rs ${b.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isTop
                              ? const Color(0xFF047857)
                              : Colors.black87,
                        )),
                  ],
                ),
              );
            },
          );
        },
      );
}