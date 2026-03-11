# VSLA App — Firebase Setup Guide

Firebase is used **only for authentication** (sign up and login).  
All other app data (meetings, savings, loans, reports) is stored **offline** in SQLite on the device.

---

## Step 1: Create a Firebase Project

1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project**
3. Enter a project name (e.g. `vsla-app`) and follow the prompts
4. Disable Google Analytics if not needed → click **Create project**

---

## Step 2: Enable Email/Password Authentication

1. In the Firebase Console, click **Authentication** in the left sidebar
2. Click **Get Started**
3. Under the **Sign-in method** tab, click **Email/Password**
4. Toggle **Enable** → click **Save**

> This is critical. Without this step, all logins and registrations will fail.

---

## Step 3: Get Your Web API Key

1. Click the ⚙️ gear icon → **Project settings**
2. Scroll to **Your apps** section
3. If you don't have a web app yet:
   - Click **Add app** → choose the `</>` Web icon
   - Enter any app nickname → click **Register app**
4. You'll see a config block like:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSy...",          ← Copy this value
  authDomain: "vsla-app.firebaseapp.com",
  projectId: "vsla-app",
  ...
};
```

5. Copy the `apiKey` value

---

## Step 4: Add the API Key to the App

Open this file in your project:

```
lib/utils/firebase_config.dart
```

Replace `YOUR_FIREBASE_WEB_API_KEY` with your actual key:

```dart
static const String webApiKey = 'AIzaSyABC123...your-real-key-here';
```

**That's it.** No other Firebase files are needed.

---

## How Authentication Works

The app uses the **Firebase Auth REST API** (HTTP calls), which works on all platforms:
- ✅ Linux desktop
- ✅ Windows desktop
- ✅ macOS
- ✅ Android
- ✅ iOS
- ✅ Web

Users always log in with their **UMVA ID** (e.g. `john.doe`) and password.  
Internally, the app uses `john.doe@vsla-platform.app` as the Firebase email — users never see this.

---

## Run the App

```bash
flutter pub get
flutter run -d linux    # or windows / macos / android / ios
```

---

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `OPERATION_NOT_ALLOWED` | Email/Password not enabled | Follow Step 2 above |
| `Invalid API key` | Wrong or missing API key | Check Step 4 |
| No internet / network error | Device is offline | Login and registration require internet |
| `EMAIL_EXISTS` | User already registered | Use login instead |
| `INVALID_LOGIN_CREDENTIALS` | Wrong UMVA ID or password | Check credentials |

---

## Offline vs Online

| Feature | Online Required? |
|---------|-----------------|
| Register | ✅ Yes (Firebase Auth) |
| Login | ✅ Yes (Firebase Auth) |
| Meetings | ❌ Offline (SQLite) |
| Savings / Loans | ❌ Offline (SQLite) |
| Reports | ❌ Offline (SQLite) |
| End Cycle | ❌ Offline (SQLite) |
| Settings | ❌ Offline (SQLite) |
