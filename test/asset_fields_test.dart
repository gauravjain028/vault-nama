import 'package:flutter_test/flutter_test.dart';
import 'package:vault_nama/data/asset.dart';
import 'package:vault_nama/data/asset_fields.dart';

void main() {
  test('every asset type has a form with unique field keys', () {
    for (final type in AssetType.values) {
      final form = assetForms[type];
      expect(form, isNotNull, reason: '$type has no form');
      final keys = [...form!.fields.map((f) => f.key), notesField.key];
      expect(keys.toSet(), hasLength(keys.length), reason: '$type');
    }
  });

  test('choice fields have options', () {
    for (final form in assetForms.values) {
      for (final field in form.fields.where(
        (f) => f.kind == FieldKind.choice,
      )) {
        expect(field.options, isNotEmpty, reason: field.key);
      }
    }
  });
}
