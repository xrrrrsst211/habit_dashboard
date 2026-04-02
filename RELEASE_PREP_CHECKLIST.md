# Habit Dashboard Release Prep Checklist

## 1) Create your upload keystore
Run this in a terminal:

```bash
keytool -genkeypair -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then move `upload-keystore.jks` into `android/app/`.

## 2) Create key.properties
Copy `android/key.properties.example` to `android/key.properties` and replace the values with your real passwords.

## 3) Build commands
```bash
flutter clean
flutter pub get
flutter build appbundle
```

Your release bundle should appear here:
`build/app/outputs/bundle/release/app-release.aab`

## 4) Before uploading to Play Console
- Replace the support email in the app if you want to use another email.
- Host the privacy policy on a public URL.
- Prepare screenshots, app icon, and feature graphic.
- Fill in Data safety honestly.
- Use the same package name: `com.presshutdev.habitdashboard`.
