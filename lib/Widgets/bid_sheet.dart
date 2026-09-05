// Crop Guardian - silent bid sheet
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// A buyer sees the countdown and their own bid, never anyone else's. The
// seller sees every bid, but only once the clock has run out.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/marketplace/bid_service.dart';

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
  bool _busy = false;
  String _error = '';
  String _success = '';

  bool get _isSeller =>
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

    setState(() { _busy = true; _error = ''; _success = ''; });

    final name = FirebaseAuth.instance.currentUser?.displayName ??
        FirebaseAuth.instance.currentUser?.email?.split('@').first ??
        'Buyer';

    final err = await BidService.instance.placeBid(
      listingId: widget.listingId,
      amount: value,
      bidderName: name,
    );

    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err ?? '';
      if (err == null) {
        _success = 'Bid placed. Nobody else can see your amount.';
        _amount.clear();
      }
    });
  }

  Future<void> _openAuction() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );
    if (time == null || !mounted) return;

    final closesAt = DateTime(
        picked.year, picked.month, picked.day, time.hour, time.minute);

    setState(() => _busy = true);
    final err = await BidService.instance.openAuction(
      listingId: widget.listingId,
      closesAt: closesAt,
    );
    if (!mounted) return;
    setState(() { _busy = false; _error = err ?? ''; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
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
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.bold)),
              Text('Asking Rs ${widget.askingPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 16),
              StreamBuilder<AuctionState>(
                stream: BidService.instance.auctionState(widget.listingId),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('Could not load bidding: ' + snap.error.toString(),
                          style: const TextStyle(fontSize: 12.5, color: Colors.red)),
                    );
                  }
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final st = snap.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statusBar(st),
                      const SizedBox(height: 16),
                      if (_isSeller) _sellerView(st) else _buyerView(st),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBar(AuctionState st) {
    final open = st.isOpen;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: open ? const Color(0xFFECFDF5) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: open ? const Color(0xFF34D399) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(open ? Icons.lock_clock : Icons.lock_outline,
              size: 18,
              color: open ? const Color(0xFF047857) : Colors.black45),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(st.countdownLabel,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                const Text('Sealed bidding - nobody sees other offers',
                    style: TextStyle(fontSize: 11.5, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buyerView(AuctionState st) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<Bid?>(
          stream: BidService.instance.myBid(widget.listingId),
          builder: (context, snap) {
            final mine = snap.data;
            if (mine == null) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF022C22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('YOUR BID',
                      style: TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 10.5,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Rs ${mine.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Only you and the seller can see this.',
                      style: TextStyle(
                          color: Color(0xFFA7F3D0), fontSize: 11.5)),
                ],
              ),
            );
          },
        ),
        if (st.isOpen) ...[
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              prefixText: 'Rs ',
              hintText: 'Your offer',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_error,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12.5)),
          ],
          if (_success.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_success,
                style: const TextStyle(
                    color: Color(0xFF047857), fontSize: 12.5)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _placeBid,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(_busy ? 'Placing...' : 'Place sealed bid',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'You may raise your bid any time before closing, but you cannot lower it.',
            style: TextStyle(fontSize: 11.5, color: Colors.black54, height: 1.4),
          ),
        ] else
          _closedNotice(),
      ],
    );
  }

  Widget _closedNotice() => FutureBuilder<Bid?>(
        future: BidService.instance.winner(widget.listingId),
        builder: (context, snap) {
          final w = snap.data;
          final iWon = w?.isMine ?? false;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iWon ? const Color(0xFFECFDF5) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              w == null
                  ? 'Bidding has closed. No winning bid was recorded.'
                  : iWon
                      ? 'You won with Rs ${w.amount.toStringAsFixed(0)}. The seller will contact you.'
                      : 'Bidding has closed. Another buyer placed a higher offer.',
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
          );
        },
      );

  Widget _sellerView(AuctionState st) {
    if (st.closesAt == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set a closing time to open sealed bidding. Buyers place offers without seeing each other, and the highest offer wins when time runs out.',
            style: TextStyle(fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _openAuction,
              icon: const Icon(Icons.schedule, size: 18),
              label: const Text('Set closing time'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_error,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12.5)),
          ],
        ],
      );
    }

    if (st.isOpen) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<List<Bid>>(
              stream: BidService.instance.allBids(widget.listingId),
              builder: (context, s) {
                final n = s.data?.length ?? 0;
                return Text('\ sealed bid\ so far',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold));
              },
            ),
            const SizedBox(height: 6),
            const Text(
              'Amounts stay hidden until bidding closes, so no buyer can be outbid at the last moment.',
              style: TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.4),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<Bid>>(
      stream: BidService.instance.allBids(widget.listingId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final bids = snap.data!;
        if (bids.isEmpty) {
          return const Text('Bidding closed with no offers.',
              style: TextStyle(fontSize: 13.5));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Final results',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            ...bids.asMap().entries.map((e) {
              final i = e.key;
              final b = e.value;
              final won = i == 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: won ? const Color(0xFFECFDF5) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: won
                        ? const Color(0xFF34D399)
                        : Colors.grey.shade300,
                    width: won ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (won)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.emoji_events,
                            size: 17, color: Color(0xFF047857)),
                      ),
                    Expanded(
                      child: Text(b.bidderName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                won ? FontWeight.bold : FontWeight.normal,
                          )),
                    ),
                    Text('Rs ${b.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: won
                              ? const Color(0xFF047857)
                              : Colors.black87,
                        )),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
