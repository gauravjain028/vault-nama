import 'package:flutter/material.dart';

import '../security/pin_service.dart';

/// Numeric PIN entry shared by the setup and lock screens.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.onSubmit,
    this.submitLabel = 'Continue',
  });

  /// Called with the entered PIN; return an error message to show, or null.
  final Future<String?> Function(String pin) onSubmit;
  final String submitLabel;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  Future<void> _submit() async {
    final pin = _controller.text;
    if (!PinService.isValidPin(pin)) {
      setState(
        () => _error =
            'Enter ${PinService.minLength}'
            '-${PinService.maxLength} digits',
      );
      return;
    }
    setState(() => _busy = true);
    final error = await widget.onSubmit(pin);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
      if (error != null) _controller.clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const Key('pin-field'),
          controller: _controller,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: PinService.maxLength,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, letterSpacing: 12),
          decoration: InputDecoration(errorText: _error, counterText: ''),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.submitLabel),
        ),
      ],
    );
  }
}
