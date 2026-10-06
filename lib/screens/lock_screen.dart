import 'package:flutter/material.dart';

import 'pin_pad.dart';

/// Shown on launch and whenever the app returns from the background.
class LockScreen extends StatelessWidget {
  const LockScreen({super.key, required this.onPinEntered, this.onBiometric});

  /// Returns true when the PIN is correct.
  final Future<bool> Function(String pin) onPinEntered;

  /// Null when the device has no usable biometrics.
  final VoidCallback? onBiometric;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(Icons.lock, size: 56),
                const SizedBox(height: 16),
                Text(
                  'Vault Nama is locked',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                PinPad(
                  submitLabel: 'Unlock',
                  onSubmit: (pin) async =>
                      await onPinEntered(pin) ? null : 'Wrong PIN',
                ),
                if (onBiometric != null) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: onBiometric,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Use fingerprint or face'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
