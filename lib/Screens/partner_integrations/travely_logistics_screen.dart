import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class TravelyLogisticsScreen extends StatefulWidget {
  const TravelyLogisticsScreen({super.key});

  @override
  State<TravelyLogisticsScreen> createState() => _TravelyLogisticsScreenState();
}

class _TravelyLogisticsScreenState extends State<TravelyLogisticsScreen> {
  String _selectedVehicle = 'Mini Truck (1 Ton)';
  final TextEditingController _destinationController = TextEditingController();
  bool _isBooking = false;

  final List<String> _vehicles = ['Mini Truck (1 Ton)', 'Medium Carrier (3 Tons)', 'Heavy Transport (5+ Tons)'];

  void _bookTransport() async {
    if (_destinationController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Please enter delivery destination", backgroundColor: Colors.red);
      return;
    }

    setState(() => _isBooking = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate Travely API dispatch
    if (!mounted) return;
    setState(() => _isBooking = false);

    Fluttertoast.showToast(
      msg: "Travely Transport Dispatched Successfully!",
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travely Agri-Logistics'),
        backgroundColor: Colors.teal.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Book Verified Farm Transport',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Integrated with Travely Logistics for direct-to-market crop delivery.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _selectedVehicle,
              items: _vehicles.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (val) => setState(() => _selectedVehicle = val!),
              decoration: const InputDecoration(
                labelText: 'Select Vehicle Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_shipping),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Delivery Destination Mandi / Buyer Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isBooking ? null : _bookTransport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isBooking
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Dispatch Travely Truck', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}