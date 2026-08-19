// Crop Guardian - live market prices
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering
//
// Prices resolve to the farmer's nearest mandi, shown per kg because that is
// how a farmer thinks, with a sell-or-hold recommendation from the forecast.

import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/location/location_service.dart';

class MarketPricesPage extends StatefulWidget {
  final String? searchQuery;
  const MarketPricesPage({super.key, this.searchQuery});

  @override
  State<MarketPricesPage> createState() => _MarketPricesPageState();
}

class _MarketPricesPageState extends State<MarketPricesPage> {
  static const _crops = [
    'tomato', 'onion', 'potato', 'wheat', 'rice',
    'maize', 'cotton', 'sugarcane', 'ragi', 'groundnut',
  ];

  String _selected = 'tomato';
  MarketPrice? _price;
  FarmLocation? _farm;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _farm = await LocationService.instance.load();
    if (_farm == null) {
      setState(() {
        _loading = false;
        _error = 'location';
      });
      return;
    }
    await _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = ''; });

    final p = await ApiClient.instance.marketPrice(
      crop: _selected,
      lat: _farm!.latitude,
      lon: _farm!.longitude,
    );

    if (!mounted) return;
    setState(() {
      _price = p;
      _loading = false;
      if (p == null) _error = 'network';
    });
  }

  Future<void> _setLocation() async {
    setState(() => _loading = true);
    final loc = await LocationService.instance.detectFromGps();
    if (!mounted) return;
    if (loc == null) {
      setState(() { _loading = false; _error = 'permission'; });
      return;
    }
    _farm = loc;
    await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF166534),
        foregroundColor: Colors.white,
        title: const Column(
          children: [
            Text('Market Prices', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('मंडी भाव', style: TextStyle(fontSize: 13)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Update location',
            onPressed: _setLocation,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_farm != null) _locationBar(),
            const SizedBox(height: 14),
            _cropSelector(),
            const SizedBox(height: 18),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error.isNotEmpty)
              _errorCard()
            else if (_price != null)
              _priceCard(_price!),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _locationBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.storefront, size: 18, color: Color(0xFF047857)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _price != null
                    ? '${_price!.mandi} mandi, ${_price!.district}'
                    : _farm!.label,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
            if (_price?.distanceKm != null)
              Text('${_price!.distanceKm!.toStringAsFixed(0)} km',
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      );

  Widget _cropSelector() => SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _crops.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final crop = _crops[i];
            final active = crop == _selected;
            return ChoiceChip(
              label: Text(crop[0].toUpperCase() + crop.substring(1)),
              selected: active,
              onSelected: (_) {
                setState(() => _selected = crop);
                _fetch();
              },
              selectedColor: const Color(0xFF34D399),
              labelStyle: TextStyle(
                color: active ? const Color(0xFF022C22) : Colors.black87,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            );
          },
        ),
      );

  Widget _priceCard(MarketPrice p) {
    final rising = p.isRising;
    final trendColor = rising ? const Color(0xFF047857) : Colors.orange.shade800;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF34D399), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TODAY\u0027S PRICE',
                  style: TextStyle(fontSize: 11, letterSpacing: 0.8, color: Colors.black54)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('₹${p.currentPricePerKg.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 38, fontWeight: FontWeight.bold, color: Color(0xFF022C22))),
                  const SizedBox(width: 6),
                  const Text('/ kg', style: TextStyle(fontSize: 16, color: Colors.black54)),
                ],
              ),
              Text('₹${p.currentPrice.toStringAsFixed(0)} per quintal (100 kg)',
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
              const Divider(height: 26),
              Row(
                children: [
                  Icon(rising ? Icons.trending_up : Icons.trending_down,
                      color: trendColor, size: 20),
                  const SizedBox(width: 8),
                  Text('${rising ? "+" : ""}${p.changePct.toStringAsFixed(1)}% in 7 days',
                      style: TextStyle(fontWeight: FontWeight.bold, color: trendColor)),
                  const Spacer(),
                  Text('₹${p.forecast7dPerKg.toStringAsFixed(2)}/kg',
                      style: TextStyle(fontSize: 13, color: trendColor)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: rising ? const Color(0xFFECFDF5) : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(rising ? Icons.savings_outlined : Icons.schedule,
                  color: trendColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(p.recommendation,
                    style: const TextStyle(fontSize: 14, height: 1.4)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _historyCard(p),
        const SizedBox(height: 14),
        Text(p.disclaimer,
            style: const TextStyle(fontSize: 11.5, color: Colors.black45, height: 1.4)),
      ],
    );
  }

  Widget _historyCard(MarketPrice p) {
    final last = p.history.length > 7
        ? p.history.sublist(p.history.length - 7)
        : p.history;

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
          const Text('Last 7 days',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          ...last.map((h) {
            final price = (h['modal_price'] as num).toDouble();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Text(h['on_date'].toString().substring(5),
                      style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
                  const Spacer(),
                  Text('₹${(price / 100).toStringAsFixed(2)}/kg',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _errorCard() {
    final needsLocation = _error == 'location' || _error == 'permission';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(needsLocation ? Icons.location_off : Icons.wifi_off,
              size: 40, color: Colors.orange.shade700),
          const SizedBox(height: 14),
          Text(
            needsLocation
                ? 'Set your farm location to see prices from your nearest mandi.'
                : 'Could not reach the price service. Check your connection and pull down to retry.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: needsLocation ? _setLocation : _fetch,
            icon: Icon(needsLocation ? Icons.my_location : Icons.refresh),
            label: Text(needsLocation ? 'Use my location' : 'Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF166534),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}