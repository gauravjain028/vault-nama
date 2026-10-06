import 'package:flutter/material.dart';

import '../data/asset.dart';
import '../data/asset_repository.dart';

/// Lists saved assets. Adding and editing assets comes in the next step.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository, required this.onLock});

  final AssetRepository repository;
  final VoidCallback onLock;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Asset>> _assets = widget.repository.all();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault Nama'),
        actions: [
          IconButton(
            tooltip: 'Lock',
            icon: const Icon(Icons.lock_outline),
            onPressed: widget.onLock,
          ),
        ],
      ),
      body: FutureBuilder<List<Asset>>(
        future: _assets,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final assets = snapshot.data!;
          if (assets.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No assets yet.\nYour policies, deposits, gold and '
                  'property will appear here.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _assets = widget.repository.all());
              await _assets;
            },
            child: ListView.builder(
              itemCount: assets.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(assets[i].name),
                subtitle: Text(assets[i].type.label),
              ),
            ),
          );
        },
      ),
    );
  }
}
