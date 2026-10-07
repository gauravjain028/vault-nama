import 'asset.dart';

enum FieldKind { text, number, money, date, choice }

/// One type-specific field, stored in [Asset.details] under [key].
/// Money is stored in paise (int), dates as yyyy-MM-dd strings, numbers as
/// doubles.
class FieldSpec {
  const FieldSpec(
    this.key,
    this.label,
    this.kind, {
    this.options = const [],
    this.hint,
  });

  final String key;
  final String label;
  final FieldKind kind;
  final List<String> options;
  final String? hint;
}

/// The form for one asset type.
class AssetForm {
  const AssetForm({
    required this.namePrompt,
    required this.fields,
    this.valueLabel,
  });

  /// Label for the asset's name, e.g. "Policy name".
  final String namePrompt;

  /// Label for the current value, or null when the type has no value of its
  /// own (health and term cover).
  final String? valueLabel;
  final List<FieldSpec> fields;
}

const _premiumFrequency = FieldSpec(
  'premiumFrequency',
  'Premium frequency',
  FieldKind.choice,
  options: ['Monthly', 'Quarterly', 'Half-yearly', 'Yearly', 'Single'],
);
const _nominee = FieldSpec('nominee', 'Nominee', FieldKind.text);

const _metalFields = [
  FieldSpec(
    'form',
    'Form',
    FieldKind.choice,
    options: ['Jewellery', 'Coins / bars', 'Digital', 'ETF / bond'],
  ),
  FieldSpec('weightGrams', 'Weight (grams)', FieldKind.number),
  FieldSpec('purity', 'Purity', FieldKind.text, hint: 'e.g. 22K, 999'),
  FieldSpec('purchaseDate', 'Purchase date', FieldKind.date),
  FieldSpec('purchasePrice', 'Purchase price', FieldKind.money),
];

const assetForms = <AssetType, AssetForm>{
  AssetType.lifeInsurance: AssetForm(
    namePrompt: 'Policy name',
    valueLabel: 'Current / surrender value',
    fields: [
      FieldSpec('insurer', 'Insurer', FieldKind.text, hint: 'e.g. LIC'),
      FieldSpec('policyNumber', 'Policy number', FieldKind.text),
      FieldSpec('sumAssured', 'Sum assured', FieldKind.money),
      FieldSpec('premium', 'Premium', FieldKind.money),
      _premiumFrequency,
      FieldSpec('nextPremiumDue', 'Next premium due', FieldKind.date),
      FieldSpec('maturityDate', 'Maturity date', FieldKind.date),
      _nominee,
    ],
  ),
  AssetType.healthInsurance: AssetForm(
    namePrompt: 'Policy name',
    fields: [
      FieldSpec('insurer', 'Insurer', FieldKind.text),
      FieldSpec('policyNumber', 'Policy number', FieldKind.text),
      FieldSpec('coverAmount', 'Cover amount', FieldKind.money),
      FieldSpec('premium', 'Yearly premium', FieldKind.money),
      FieldSpec('renewalDate', 'Renewal date', FieldKind.date),
      FieldSpec('membersCovered', 'Members covered', FieldKind.text),
    ],
  ),
  AssetType.termInsurance: AssetForm(
    namePrompt: 'Policy name',
    fields: [
      FieldSpec('insurer', 'Insurer', FieldKind.text),
      FieldSpec('policyNumber', 'Policy number', FieldKind.text),
      FieldSpec('coverAmount', 'Cover amount', FieldKind.money),
      FieldSpec('premium', 'Premium', FieldKind.money),
      _premiumFrequency,
      FieldSpec('nextPremiumDue', 'Next premium due', FieldKind.date),
      FieldSpec('policyEndDate', 'Cover ends on', FieldKind.date),
      _nominee,
    ],
  ),
  AssetType.gold: AssetForm(
    namePrompt: 'Description',
    valueLabel: 'Current value',
    fields: _metalFields,
  ),
  AssetType.silver: AssetForm(
    namePrompt: 'Description',
    valueLabel: 'Current value',
    fields: _metalFields,
  ),
  AssetType.fixedDeposit: AssetForm(
    namePrompt: 'Name',
    valueLabel: 'Current value',
    fields: [
      FieldSpec('bank', 'Bank', FieldKind.text),
      FieldSpec('fdNumber', 'FD number', FieldKind.text),
      FieldSpec('principal', 'Principal', FieldKind.money),
      FieldSpec('interestRate', 'Interest rate (%)', FieldKind.number),
      FieldSpec('startDate', 'Start date', FieldKind.date),
      FieldSpec('maturityDate', 'Maturity date', FieldKind.date),
      FieldSpec('maturityAmount', 'Maturity amount', FieldKind.money),
      _nominee,
    ],
  ),
  AssetType.bankAccount: AssetForm(
    namePrompt: 'Name',
    valueLabel: 'Balance',
    fields: [
      FieldSpec('bank', 'Bank', FieldKind.text),
      FieldSpec(
        'accountType',
        'Account type',
        FieldKind.choice,
        options: ['Savings', 'Current', 'Salary', 'NRE', 'NRO', 'PPF'],
      ),
      FieldSpec('accountNumber', 'Account number', FieldKind.text),
      FieldSpec('ifsc', 'IFSC', FieldKind.text),
      FieldSpec('branch', 'Branch', FieldKind.text),
      _nominee,
    ],
  ),
  AssetType.realEstate: AssetForm(
    namePrompt: 'Property name',
    valueLabel: 'Current market value',
    fields: [
      FieldSpec(
        'propertyType',
        'Property type',
        FieldKind.choice,
        options: ['Flat', 'House', 'Plot', 'Commercial', 'Agricultural'],
      ),
      FieldSpec('address', 'Address', FieldKind.text),
      FieldSpec('area', 'Area', FieldKind.text, hint: 'e.g. 1200 sq ft'),
      FieldSpec('purchaseDate', 'Purchase date', FieldKind.date),
      FieldSpec('purchasePrice', 'Purchase price', FieldKind.money),
      FieldSpec('registrationNumber', 'Registration number', FieldKind.text),
    ],
  ),
  AssetType.other: AssetForm(
    namePrompt: 'Name',
    valueLabel: 'Current value',
    fields: [],
  ),
};

/// Free-text notes, shown on every form after the type's own fields.
const notesField = FieldSpec('notes', 'Notes', FieldKind.text);
