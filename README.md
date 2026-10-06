# Vault Nama

An offline-only mobile app for keeping a record of your assets: LIC and other
life policies, health and term insurance, gold and silver, fixed deposits,
bank accounts and real estate.

Nothing leaves the phone. There is no server, account or network access.

## Security

- Data is stored in a SQLCipher-encrypted SQLite database.
- The database key is random and kept only in the Android Keystore / iOS Keychain.
- The app is locked with a 4–8 digit PIN (stored as a salted PBKDF2 hash), with
  optional fingerprint or Face ID unlock. It locks again whenever it goes to
  the background.
- Android cloud backup and screenshots are disabled.

## Roadmap

1. App setup, encrypted storage and app lock ✅
2. Add, edit and list each asset type with its own fields
3. Dashboard of totals by category, with reminders for premiums and FD maturity
4. Encrypted backup file export and restore

## Development

Requires Flutter 3.47 or newer. Android needs API 24+.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```
