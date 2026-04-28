// encryption_recovery.dart: User-facing strings for the encryption migration
// recovery flow.
//
// All strings are centralized here to keep the UI code clean and make them
// testable. Used when _migrateToEncrypted() fails and the user needs to
// manually export, reset, and re-import their data.
//
// Cross-ref:
//   - Recovery screen: screens/settings/encryption_issue_screen.dart
//   - Settings banner: screens/manage_items_screen.dart
//   - Launch toast: screens/calendar_screen.dart

const String encryptionRecoveryToastMessage =
    'A problem occurred. Please open Settings to address the issue.';

const String encryptionRecoveryBannerTitle = 'Encryption Issue';

const String encryptionRecoveryBannerSubtitle =
    'Your data needs attention. Tap to resolve.';

const String encryptionRecoveryScreenTitle = 'Encryption Issue';

const String encryptionRecoveryExplanation =
    'In order to further protect your data, the app encrypts everything '
    'stored on your device so that only Wellnot can read it. This keeps your '
    'health information private even if someone else gets access to your '
    'device.\n\n'
    'During the most recent update, we were unable to encrypt your data for '
    'you. Your data is still present on your device, but not yet encrypted.\n\n'
    'To fix this, you will need to save a copy of your data, reset the app, '
    'and then load it back in. Follow the steps below.';

const String encryptionRecoveryDataWarning =
    'If you continue without exporting your data, all of your entries will be '
    'permanently lost. There will be no way to recover them.';

const String encryptionRecoveryConfirmationPhrase = 'I promise';

const String encryptionRecoveryConfirmationPrompt =
    "Type 'I promise' to confirm you have exported your data";

const String encryptionRecoveryEncryptComplete =
    'Your database has been encrypted. The app will now close. When you '
    'reopen it, go to Settings > Import Data to restore your entries.';

const String encryptionRecoveryEncryptCompleteTitle = 'Encryption Complete';

const String encryptionRecoveryResetConfirmTitle = 'Encrypt Database?';

const String encryptionRecoveryResetConfirmBody =
    'This will encrypt your database. Make sure you have exported your '
    'data first. The app will close and your data will be ready to import '
    'when you reopen.';
