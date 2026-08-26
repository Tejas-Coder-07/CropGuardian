// Crop Guardian - admin panel
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// Moderation view for verifying listings and resolving reports. Gated by an
// isAdmin flag on the user document and enforced in Firestore rules, so a
// hidden route is not the only thing protecting it.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  late TabController _tabs;
  bool? _isAdmin;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _checkAdmin();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _checkAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isAdmin = false);
      return;
    }
    try {
      final doc = await _db.collection('users').doc(uid).get();
      setState(() => _isAdmin = doc.data()?['isAdmin'] == true);
    } catch (_) {
      setState(() => _isAdmin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdmin == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isAdmin == false) return _noAccess();

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF022C22),
        foregroundColor: Colors.white,
        title: const Text('Admin Panel',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFF34D399),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Listings'),
            Tab(text: 'Reports'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_listingsTab(), _reportsTab(), _statsTab()],
      ),
    );
  }

  Widget _noAccess() => Scaffold(
        backgroundColor: const Color(0xFFF0FDF4),
        appBar: AppBar(
          backgroundColor: const Color(0xFF166534),
          foregroundColor: Colors.white,
          title: const Text('Admin Panel'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 48, color: Colors.green.shade200),
                const SizedBox(height: 16),
                const Text('Admin access only',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text(
                  'This area is for verified moderators who review listings\n'
                  'and resolve disputes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _listingsTab() => StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('market_listings')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) return _empty('No listings yet');

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final d = doc.data() as Map<String, dynamic>;
              final verified = d['verified'] == true;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        verified ? const Color(0xFFECFDF5) : Colors.orange.shade50,
                    child: Icon(
                      verified ? Icons.verified : Icons.pending_outlined,
                      color: verified
                          ? const Color(0xFF047857)
                          : Colors.orange.shade700,
                      size: 20,
                    ),
                  ),
                  title: Text(d['productName'] ?? 'Unnamed',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      'Rs ${d['price'] ?? 0}  -  ${d['category'] ?? 'Uncategorised'}',
                      style: const TextStyle(fontSize: 12.5)),
                  trailing: TextButton(
                    onPressed: () => doc.reference.set(
                      {'verified': !verified},
                      SetOptions(merge: true),
                    ),
                    child: Text(verified ? 'Unverify' : 'Verify'),
                  ),
                ),
              );
            },
          );
        },
      );

  Widget _reportsTab() => StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('reports')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) return _empty('No open reports');

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final d = doc.data() as Map<String, dynamic>;
              final resolved = d['resolved'] == true;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(
                    resolved ? Icons.check_circle : Icons.flag_outlined,
                    color: resolved ? const Color(0xFF047857) : Colors.red,
                  ),
                  title: Text(d['reason'] ?? 'Report',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(d['details'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5)),
                  trailing: TextButton(
                    onPressed: () => doc.reference.set(
                      {'resolved': !resolved},
                      SetOptions(merge: true),
                    ),
                    child: Text(resolved ? 'Reopen' : 'Resolve'),
                  ),
                ),
              );
            },
          );
        },
      );

  Widget _statsTab() => FutureBuilder<List<int>>(
        future: _counts(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final c = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _statCard('Registered farmers', c[0], Icons.people_alt_outlined),
              _statCard('Diagnoses run', c[1], Icons.troubleshoot),
              _statCard('Active listings', c[2], Icons.storefront_outlined),
              _statCard('Community posts', c[3], Icons.forum_outlined),
            ],
          );
        },
      );

  Future<List<int>> _counts() async {
    Future<int> count(String c) async =>
        (await _db.collection(c).count().get()).count ?? 0;
    return [
      await count('users'),
      await count('diagnoses'),
      await count('market_listings'),
      await count('community_posts'),
    ];
  }

  Widget _statCard(String label, int value, IconData icon) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFECFDF5),
              child: Icon(icon, color: const Color(0xFF047857), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            Text('$value',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF022C22))),
          ],
        ),
      );

  Widget _empty(String text) => Center(
        child: Text(text,
            style: const TextStyle(color: Colors.black54, fontSize: 14)),
      );
}