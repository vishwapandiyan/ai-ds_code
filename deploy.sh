#!/bin/bash

echo "🚀 Building for production..."

# Clean previous build
flutter clean

# Get dependencies
flutter pub get

# Build for web
flutter build web

echo "✅ Build completed!"
echo "📁 Build files are in build/web/"
echo ""
echo "To deploy:"
echo "1. Upload build/web/ to your hosting service"
echo "2. Configure your domain"
echo "3. Update Supabase configuration for production"
