import 'package:flutter/material.dart';

import 'pin_pad.dart';

/// First-launch screen: choose a PIN, then confirm it.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key, required this.onPinChosen});

  final Future<void> Function(String pin) onPinChosen;

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String? _firstPin;
  bool _mismatch = false;

  @override
  Widget build(BuildContext context) {
    final confirming = _firstPin != null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(Icons.lock_outline, size: 56),
                const SizedBox(height: 16),
                Text(
                  confirming ? 'Confirm your PIN' : 'Choose a PIN',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _mismatch
                      ? "PINs didn't match. Choose a PIN again."
                      : 'Your data stays on this phone, encrypted. '
                            'The PIN unlocks it.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                PinPad(
                  key: ValueKey(confirming),
                  submitLabel: confirming ? 'Set PIN' : 'Next',
                  onSubmit: (pin) async {
                    if (!confirming) {
                      setState(() {
                        _firstPin = pin;
                        _mismatch = false;
                      });
                      return null;
                    }
                    if (pin != _firstPin) {
                      setState(() {
                        _firstPin = null;
                        _mismatch = true;
                      });
                      return null;
                    }
                    await widget.onPinChosen(pin);
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
