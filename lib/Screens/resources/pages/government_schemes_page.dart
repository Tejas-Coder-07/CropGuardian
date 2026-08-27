// Crop Guardian - government scheme assistant
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// Live search over official government portals. Scheme rules and deadlines
// change often enough that a hardcoded list is wrong within a season.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_client.dart';
import '../../../core/location/location_service.dart';

class GovernmentSchemesPage extends StatefulWidget {
  final String? searchQuery;
  const GovernmentSchemesPage({super.key, this.searchQuery});

  @override
  State<GovernmentSchemesPage> createState() => _GovernmentSchemesPageState();
}

class _GovernmentSchemesPageState extends State<GovernmentSchemesPage> {
  static const _suggestions = [
    'PM Kisan eligibility',
    'Crop insurance PMFBY',
    'Soil Health Card',
    'Kisan Credit Card loan',
    'Drip irrigation subsidy',
    'Free seeds scheme',
  ];

  final _controller = TextEditingController();
  SchemeAnswer? _answer;
  Map<String, dynamic>? _agentAnswer;
  String? _agentSession;
  bool _quickMode = true;
  String? _state;
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final farm = await LocationService.instance.load();
    if (mounted) setState(() => _state = farm?.state);
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = ''; _answer = null; _agentAnswer = null; });

    if (_quickMode) {
      final a = await ApiClient.instance.askAgent(q, sessionId: _agentSession);
      if (!mounted) return;
      setState(() {
        _agentAnswer = a;
        _agentSession = a?['session_id'] as String?;
        _loading = false;
        if (a == null) {
          _error = 'Could not reach the assistant. Try Official sources instead.';
        }
      });
      return;
    }

    final a = await ApiClient.instance.searchSchemes(query: q, state: _state);
    if (!mounted) return;
    setState(() {
      _answer = a;
      _loading = false;
      if (a == null) _error = 'Could not reach the scheme service. Check your connection.';
    });
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0FDF4),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _modeToggle(),
          const SizedBox(height: 12),
          _searchBox(),
          const SizedBox(height: 14),
          if (_answer == null && !_loading) _suggestionChips(),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 50),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error.isNotEmpty) _errorBox(),
          if (_agentAnswer != null) _agentCard(_agentAnswer!),
          if (_answer != null) ..._results(_answer!),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _modeToggle() => Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _quickMode = true;
                _answer = null;
                _error = '';
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _quickMode ? const Color(0xFF34D399) : Colors.white,
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(10)),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt,
                        size: 16,
                        color: _quickMode
                            ? const Color(0xFF022C22)
                            : Colors.black54),
                    const SizedBox(width: 6),
                    Text('Quick answer',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              _quickMode ? FontWeight.bold : FontWeight.normal,
                          color: _quickMode
                              ? const Color(0xFF022C22)
                              : Colors.black87,
                        )),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _quickMode = false;
                _agentAnswer = null;
                _error = '';
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: !_quickMode ? const Color(0xFF34D399) : Colors.white,
                  borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(10)),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_outlined,
                        size: 16,
                        color: !_quickMode
                            ? const Color(0xFF022C22)
                            : Colors.black54),
                    const SizedBox(width: 6),
                    Text('Official sources',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              !_quickMode ? FontWeight.bold : FontWeight.normal,
                          color: !_quickMode
                              ? const Color(0xFF022C22)
                              : Colors.black87,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  Widget _agentCard(Map<String, dynamic> a) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF022C22),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.support_agent, size: 16, color: Color(0xFF34D399)),
                SizedBox(width: 8),
                Text('KISAN ASSISTANT',
                    style: TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              (a['answer'] ?? '').toString().replaceAll('**', ''),
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, height: 1.55),
            ),
            const SizedBox(height: 14),
            Text(a['disclaimer'] ?? '',
                style: const TextStyle(
                    color: Color(0xFFA7F3D0), fontSize: 11.5, height: 1.4)),
          ],
        ),
      );

  Widget _searchBox() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search, color: Color(0xFF047857)),
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
                decoration: const InputDecoration(
                  hintText: 'Ask about any farmer scheme...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward, color: Color(0xFF166534)),
              onPressed: () => _search(_controller.text),
            ),
          ],
        ),
      );

  Widget _suggestionChips() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _state != null
                ? 'Common questions for farmers in $_state'
                : 'Common questions',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map((s) => ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 12.5)),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFA7F3D0)),
                      onPressed: () {
                        _controller.text = s;
                        _search(s);
                      },
                    ))
                .toList(),
          ),
        ],
      );

  List<Widget> _results(SchemeAnswer a) => [
        if (a.answer != null && a.answer!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF022C22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: Color(0xFF34D399)),
                    SizedBox(width: 8),
                    Text('ANSWER',
                        style: TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 11,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(a.answer!,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14.5, height: 1.5)),
              ],
            ),
          ),
        const SizedBox(height: 18),
        if (a.results.isNotEmpty)
          const Text('Official sources',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        ...a.results.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                title: Text(r.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14.5)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.summary.length > 160
                            ? '${r.summary.substring(0, 160)}...'
                            : r.summary,
                        style: const TextStyle(fontSize: 12.5, height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.verified,
                              size: 13, color: Color(0xFF047857)),
                          const SizedBox(width: 5),
                          Text(r.sourceName,
                              style: const TextStyle(
                                  fontSize: 11.5, color: Color(0xFF047857))),
                        ],
                      ),
                    ],
                  ),
                ),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _open(r.sourceUrl),
              ),
            )),
        const SizedBox(height: 8),
        Text(a.disclaimer,
            style: const TextStyle(
                fontSize: 11.5, color: Colors.black45, height: 1.4)),
      ];

  Widget _errorBox() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(child: Text(_error, style: const TextStyle(fontSize: 13.5))),
          ],
        ),
      );
}
