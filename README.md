# tamamm

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Running the Web App

### Local Development (Localhost)
```powershell
# Build the app first
flutter build web --release

# Start server
.\start_server.ps1
```

### Deploy to Firebase Hosting (Public Access) 🌍

Deploy your app to Firebase Hosting so friends can access it from anywhere:

```powershell
# Build the app
flutter build web --release

# Deploy to Firebase (permanent URL)
.\deploy_firebase.ps1
```

**Firebase Hosting Features:**
- ✅ Permanent URL (doesn't change)
- ✅ Free tier
- ✅ HTTPS enabled
- ✅ Fast and reliable
- ✅ Works from anywhere (no WiFi needed)
- ✅ Optimized caching for better performance

**First Time Setup:**
```powershell
# Install Firebase CLI (if not installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase (if not already done)
firebase init
```