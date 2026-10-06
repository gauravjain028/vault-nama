import 'package:flutter/material.dart';

import 'data/asset_repository.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/pin_setup_screen.dart';
import 'security/biometrics.dart';
import 'security/pin_service.dart';

enum _LockState { loading, needsPin, locked, unlocked }

class VaultNamaApp extends StatefulWidget {
  const VaultNamaApp({
    super.key,
    required this.pinService,
    required this.biometrics,
    required this.openRepository,
  });

  final PinService pinService;
  final Biometrics biometrics;

  /// Opens the encrypted database; called only after the user unlocks.
  final Future<AssetRepository> Function() openRepository;

  @override
  State<VaultNamaApp> createState() => _VaultNamaAppState();
}

class _VaultNamaAppState extends State<VaultNamaApp>
    with WidgetsBindingObserver {
  _LockState _state = _LockState.loading;
  bool _biometricsAvailable = false;
  AssetRepository? _repository;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    final hasPin = await widget.pinService.hasPin();
    final biometrics = await widget.biometrics.isAvailable();
    setState(() {
      _biometricsAvailable = biometrics;
      _state = hasPin ? _LockState.locked : _LockState.needsPin;
    });
    if (hasPin && biometrics) _unlockWithBiometrics();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lock as soon as the app leaves the foreground.
    if (state == AppLifecycleState.paused && _state == _LockState.unlocked) {
      _lock();
    }
  }

  Future<void> _unlock() async {
    _repository ??= await widget.openRepository();
    setState(() => _state = _LockState.unlocked);
  }

  void _lock() => setState(() => _state = _LockState.locked);

  Future<void> _unlockWithBiometrics() async {
    if (await widget.biometrics.authenticate()) await _unlock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _repository?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vault Nama',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      home: switch (_state) {
        _LockState.loading => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        _LockState.needsPin => PinSetupScreen(
          onPinChosen: (pin) async {
            await widget.pinService.setPin(pin);
            await _unlock();
          },
        ),
        _LockState.locked => LockScreen(
          onPinEntered: (pin) async {
            final ok = await widget.pinService.verifyPin(pin);
            if (ok) await _unlock();
            return ok;
          },
          onBiometric: _biometricsAvailable ? _unlockWithBiometrics : null,
        ),
        _LockState.unlocked => HomeScreen(
          repository: _repository!,
          onLock: _lock,
        ),
      },
    );
  }
}
