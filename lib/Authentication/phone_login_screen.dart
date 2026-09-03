// Crop Guardian - phone login
// Author: Tejas S <tejus.sgowda07@gmail.com>
// Team Maverick - Cambridge Institute of Engineering

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/auth/phone_auth_service.dart';
import '../core/errors/friendly_error.dart';
import '../Screens/dashboard/dashboard_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;
  String _error = '';

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final input = _phone.text.trim();
    if (!PhoneAuthService.instance.isValid(input)) {
      setState(() => _error = 'Enter a valid 10 digit mobile number.');
      return;
    }

    setState(() { _busy = true; _error = ''; });

    await PhoneAuthService.instance.sendCode(
      phoneNumber: input,
      onCodeSent: () {
        if (!mounted) return;
        setState(() { _busy = false; _codeSent = true; });
      },
      onAutoVerified: (_) {
        if (!mounted) return;
        Get.offAll(() => const DashboardScreen());
      },
      onError: (e) {
        if (!mounted) return;
        setState(() { _busy = false; _error = FriendlyError.from(e); });
      },
    );
  }

  Future<void> _verify() async {
    if (_code.text.trim().length < 6) {
      setState(() => _error = 'Enter the six digit code from the SMS.');
      return;
    }

    setState(() { _busy = true; _error = ''; });

    final err = await PhoneAuthService.instance
        .verifyCode(_code.text, _phone.text.trim());

    if (!mounted) return;
    if (err == null) {
      Get.offAll(() => const DashboardScreen());
    } else {
      setState(() { _busy = false; _error = FriendlyError.from(err); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF166534),
        foregroundColor: Colors.white,
        title: const Text('Login with phone'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Icon(Icons.phone_android, size: 48, color: Colors.green.shade700),
            const SizedBox(height: 20),
            Text(
              _codeSent ? 'Enter the code' : 'Your mobile number',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _codeSent
                  ? 'We sent a six digit code to ${_phone.text.trim()}.'
                  : 'No email needed. We will send a code by SMS.',
              style: const TextStyle(fontSize: 13.5, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 24),
            if (!_codeSent)
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixText: '+91  ',
                  hintText: '9876543210',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_error,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : (_codeSent ? _verify : _sendCode),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF166534),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _busy
                      ? 'Please wait...'
                      : (_codeSent ? 'Verify and continue' : 'Send code'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            if (_codeSent) ...[
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _codeSent = false;
                            _code.clear();
                            _error = '';
                          }),
                  child: const Text('Change number'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}