# Android Release Setup

This document explains how to create Android release builds and publish them to GitHub Releases.

## Prerequisites

### 1. Generate a Signing Key (One-time setup)

If you don't have a signing key yet, generate one:

```bash
cd frontend/android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias swaptunes
```

You'll be prompted for:
- Keystore password (remember this!)
- Key password (can be the same as keystore password)
- Your name, organization, etc.

**Important**: Keep `upload-keystore.jks` secure and NEVER commit it to Git!

### 2. Configure GitHub Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

1. **KEYSTORE_BASE64**: Base64-encoded keystore file
   ```bash
   cd frontend/android/app
   base64 -i upload-keystore.jks | pbcopy  # macOS
   # or
   base64 -i upload-keystore.jks  # Linux - copy the output
   ```

2. **KEYSTORE_PASSWORD**: The keystore password you entered

3. **KEY_PASSWORD**: The key password you entered

4. **KEY_ALIAS**: `swaptunes` (or whatever alias you used)

5. **SUPABASE_URL**: Your Supabase project URL

6. **SUPABASE_ANON_KEY**: Your Supabase anonymous key

## Creating a Release

### Option 1: Using Git Tags (Recommended)

```bash
# Make sure your code is ready
git add .
git commit -m "Prepare release v1.0.0"

# Create and push a tag
git tag v1.0.0
git push origin v1.0.0
```

The GitHub Action will automatically:
- Build the release APK and AAB
- Create a GitHub release
- Upload the artifacts

### Option 2: Manual Workflow Dispatch

1. Go to GitHub → Actions → "Android Release"
2. Click "Run workflow"
3. Enter the version (e.g., `1.0.0`)
4. Click "Run workflow"

## What Gets Built

The workflow creates two files:

1. **APK** (`swaptunes-vX.X.X.apk`) - For direct installation on Android devices
2. **AAB** (`swaptunes-vX.X.X.aab`) - For Google Play Store upload

## Backend Configuration

The release builds are configured to connect to:
```
https://backend.swaptunes.v2.dizzpy.dev/api/v1
```

To change this, update the `BACKEND_URL` in:
- `.github/workflows/android-release.yml` (line 51)
- `frontend/.env.example`

## Local Release Build

To build locally for testing:

```bash
cd frontend

# Create .env file with your credentials
cp .env.example .env
# Edit .env and fill in your secrets

# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

The outputs will be in:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## Troubleshooting

### "Keystore not found"
Make sure you've added the KEYSTORE_BASE64 secret correctly.

### "Wrong password"
Double-check your KEYSTORE_PASSWORD and KEY_PASSWORD secrets.

### Build fails on GitHub Actions
Check the Actions logs for specific errors. Common issues:
- Missing GitHub secrets
- Invalid keystore
- Flutter dependency issues

### App crashes on launch
- Make sure SUPABASE_URL and SUPABASE_ANON_KEY are set correctly
- Check that the backend URL is accessible

## Version Bumping

Update version in `frontend/pubspec.yaml`:

```yaml
version: 1.0.1+2  # 1.0.1 is versionName, 2 is versionCode
```

Then create a new tag with the same version number.
