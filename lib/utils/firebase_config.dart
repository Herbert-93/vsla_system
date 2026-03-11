/// ─────────────────────────────────────────────────────────────────────────────
/// FIREBASE CONFIGURATION
/// ─────────────────────────────────────────────────────────────────────────────
/// HOW TO GET YOUR WEB API KEY:
///   1. Go to https://console.firebase.google.com
///   2. Open your project (or create one if you haven't)
///   3. Click ⚙️ Project Settings (gear icon, top left)
///   4. Scroll to "Your apps" → click the Web app (</>) icon
///      (If you don't have a web app, click "Add app" → Web)
///   5. Copy the "apiKey" value from the config shown
///   6. Paste it below, replacing YOUR_FIREBASE_WEB_API_KEY
///
/// IMPORTANT: Also make sure to enable Email/Password sign-in in Firebase:
///   Firebase Console → Authentication → Sign-in method → Email/Password → Enable
/// ─────────────────────────────────────────────────────────────────────────────

class FirebaseConfig {
  /// Your Firebase project Web API Key.
  /// Replace this string with your actual key from Firebase Console.
  static const String webApiKey = 'YOUR_FIREBASE_WEB_API_KEY';

  /// The email domain used internally to register UMVA IDs with Firebase.
  /// Firebase requires email+password; we auto-generate emails as:
  ///   {umvaId}@vsla-platform.app
  /// Users NEVER see or need to know this domain — they always use their UMVA ID.
  static const String emailDomain = 'vsla-platform.app';

  /// Construct a Firebase email from a UMVA ID.
  static String toEmail(String umvaId) {
    return '${umvaId.toLowerCase().trim()}@$emailDomain';
  }

  /// Firebase Auth REST API base URL.
  static const String authBaseUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts';

  /// Token refresh URL.
  static const String tokenRefreshUrl =
      'https://securetoken.googleapis.com/v1/token';
}
