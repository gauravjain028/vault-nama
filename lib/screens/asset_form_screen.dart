import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/asset.dart';
import '../data/asset_fields.dart';
import '../data/asset_repository.dart';
import '../util/money.dart';

final _storedDate = DateFormat('yyyy-MM-dd');
final _shownDate = DateFormat('d MMM yyyy');

/// Adds a new asset of [type], or edits [existing]. Pops `true` when the
/// asset was saved or deleted.
class AssetFormScreen extends StatefulWidget {
  const AssetFormScreen({
    super.key,
    required this.repository,
    required this.type,
    this.existing,
  });

  final AssetRepository repository;
  final AssetType type;
  final Asset? existing;

  @override
  State<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends State<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final AssetForm _form = assetForms[widget.type]!;
  late final List<FieldSpec> _fields = [..._form.fields, notesField];
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _value = TextEditingController(
    text: widget.existing == null || widget.existing!.valuePaise == 0
        ? ''
        : paiseToInput(widget.existing!.valuePaise),
  );

  /// Text controllers for text, number and money fields.
  final _controllers = <String, TextEditingController>{};

  /// Current values of date and choice fields.
  final _picked = <String, String?>{};

  @override
  void initState() {
    super.initState();
    final details = widget.existing?.details ?? const {};
    for (final field in _fields) {
      final stored = details[field.key];
      switch (field.kind) {
        case FieldKind.date:
        case FieldKind.choice:
          _picked[field.key] = stored as String?;
        case FieldKind.money:
          _controllers[field.key] = TextEditingController(
            text: stored == null ? '' : paiseToInput(stored as int),
          );
        case FieldKind.number:
          _controllers[field.key] = TextEditingController(
            text: stored == null ? '' : _trimNumber(stored as num),
          );
        case FieldKind.text:
          _controllers[field.key] = TextEditingController(
            text: stored as String?,
          );
      }
    }
  }

  static String _trimNumber(num n) =>
      n == n.truncate() ? n.truncate().toString() : n.toString();

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, Object?> _collectDetails() {
    final details = <String, Object?>{};
    for (final field in _fields) {
      final Object? value = switch (field.kind) {
        FieldKind.date || FieldKind.choice => _picked[field.key],
        FieldKind.money => parseRupees(_controllers[field.key]!.text),
        FieldKind.number => double.tryParse(
          _controllers[field.key]!.text.trim(),
        ),
        FieldKind.text => _controllers[field.key]!.text.trim(),
      };
      if (value != null && value != '') details[field.key] = value;
    }
    return details;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.existing;
    final asset = Asset(
      id: existing?.id,
      type: widget.type,
      name: _name.text.trim(),
      valuePaise: _form.valueLabel == null ? 0 : parseRupees(_value.text) ?? 0,
      details: _collectDetails(),
      createdAt: existing?.createdAt,
    );
    if (existing == null) {
      await widget.repository.insert(asset);
    } else {
      await widget.repository.update(asset);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${widget.existing!.name}"?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.delete(widget.existing!.id!);
    if (mounted) Navigator.of(context).pop(true);
  }

  String? _validateMoney(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    return parseRupees(input) == null ? 'Enter an amount like 12500.50' : null;
  }

  String? _validateNumber(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    return double.tryParse(input.trim()) == null ? 'Enter a number' : null;
  }

  Widget _buildField(FieldSpec field) {
    switch (field.kind) {
      case FieldKind.text:
        return TextFormField(
          controller: _controllers[field.key],
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.hint,
          ),
          textCapitalization: TextCapitalization.sentences,
          maxLines: field == notesField ? null : 1,
        );
      case FieldKind.number:
        return TextFormField(
          controller: _controllers[field.key],
          decoration: InputDecoration(labelText: field.label),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: _validateNumber,
        );
      case FieldKind.money:
        return TextFormField(
          controller: _controllers[field.key],
          decoration: InputDecoration(labelText: field.label, prefixText: '₹ '),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: _validateMoney,
        );
      case FieldKind.choice:
        final current = _picked[field.key];
        return DropdownButtonFormField<String>(
          initialValue: field.options.contains(current) ? current : null,
          decoration: InputDecoration(labelText: field.label),
          items: [
            for (final option in field.options)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: (value) => setState(() => _picked[field.key] = value),
        );
      case FieldKind.date:
        final stored = _picked[field.key];
        final date = stored == null ? null : DateTime.tryParse(stored);
        return InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(1950),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() => _picked[field.key] = _storedDate.format(picked));
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: field.label,
              suffixIcon: date == null
                  ? const Icon(Icons.calendar_today_outlined)
                  : IconButton(
                      tooltip: 'Clear ${field.label}',
                      icon: const Icon(Icons.clear),
                      onPressed: () =>
                          setState(() => _picked[field.key] = null),
                    ),
            ),
            child: Text(date == null ? '' : _shownDate.format(date)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing ? 'Edit ${widget.type.label}' : 'Add ${widget.type.label}',
        ),
        actions: [
          if (editing)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('asset-name'),
              controller: _name,
              decoration: InputDecoration(labelText: _form.namePrompt),
              textCapitalization: TextCapitalization.words,
              validator: (input) =>
                  input == null || input.trim().isEmpty ? 'Required' : null,
            ),
            if (_form.valueLabel != null) ...[
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('asset-value'),
                controller: _value,
                decoration: InputDecoration(
                  labelText: _form.valueLabel,
                  prefixText: '₹ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _validateMoney,
              ),
            ],
            for (final field in _fields) ...[
              const SizedBox(height: 12),
              KeyedSubtree(
                key: Key('field-${field.key}'),
                child: _buildField(field),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
