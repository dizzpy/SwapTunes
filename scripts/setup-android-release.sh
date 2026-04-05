#!/bin/bash

# SwapTunes Android Release Setup Script
# This script helps you set up everything needed for Android releases

set -e

echo "🚀 SwapTunes Android Release Setup"
echo "======================================"
echo ""

# Check if running from project root
if [ ! -d "frontend/android" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

cd frontend/android/app

# Check if keystore already exists
if [ -f "upload-keystore.jks" ]; then
    echo "⚠️  Keystore already exists at frontend/android/app/upload-keystore.jks"
    read -p "Do you want to create a new one? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing keystore."
        SKIP_KEYGEN=true
    else
        mv upload-keystore.jks upload-keystore.jks.backup
        echo "✅ Backed up existing keystore to upload-keystore.jks.backup"
    fi
fi

# Generate keystore
if [ "$SKIP_KEYGEN" != "true" ]; then
    echo ""
    echo "📝 Generating Android signing key..."
    echo "Please answer the following questions:"
    echo ""
    
    keytool -genkey -v -keystore upload-keystore.jks \
        -keyalg RSA -keysize 2048 -validity 10000 \
        -alias swaptunes
    
    echo ""
    echo "✅ Keystore generated successfully!"
fi

echo ""
echo "📋 Next steps:"
echo ""
echo "1. Add these secrets to GitHub (Settings → Secrets and variables → Actions):"
echo ""
echo "   KEYSTORE_BASE64:"
echo "   Run this command and copy the output:"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "   $ base64 -i frontend/android/app/upload-keystore.jks | pbcopy"
    echo "   (Already copied to clipboard!)"
    base64 -i upload-keystore.jks | pbcopy
else
    echo "   $ base64 -i frontend/android/app/upload-keystore.jks"
fi

echo ""
echo "   KEYSTORE_PASSWORD: (the password you just entered)"
echo "   KEY_PASSWORD: (the key password you just entered)"
echo "   KEY_ALIAS: swaptunes"
echo ""
echo "   SUPABASE_URL: (your Supabase project URL)"
echo "   SUPABASE_ANON_KEY: (your Supabase anon key)"
echo ""
echo "2. Create a release:"
echo "   $ git tag v1.0.0"
echo "   $ git push origin v1.0.0"
echo ""
echo "3. Or manually trigger the workflow on GitHub Actions"
echo ""
echo "📖 See docs/ANDROID_RELEASE.md for more details"
echo ""
echo "✨ Setup complete!"
