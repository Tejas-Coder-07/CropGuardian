import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class StartedUpLoanScreen extends StatefulWidget {
  const StartedUpLoanScreen({super.key});

  @override
  State<StartedUpLoanScreen> createState() => _StartedUpLoanScreenState();
}

class _StartedUpLoanScreenState extends State<StartedUpLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  bool _isSubmitting = false;

  void _submitLoanApplication() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      await Future.delayed(const Duration(seconds: 1)); // Simulate API sync
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      Fluttertoast.showToast(
        msg: "StartedUp Credit Application Submitted Successfully!",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StartedUp Rural Credit'),
        backgroundColor: Colors.green.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Access Low-Interest Micro-Loans',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Powered by StartedUp Partner Network for smallholder farmers.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Requested Amount (₹)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter an amount' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _purposeController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Loan Purpose (e.g., Seeds, Equipment, Irrigation)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.agriculture),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please state your purpose' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitLoanApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Application', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}