#!/bin/bash

# Students' Coding Portal Setup Script
# This script helps set up the Flutter project with all necessary configurations

echo "🚀 Setting up Students' Coding Portal..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    echo "Visit: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Check Flutter version
FLUTTER_VERSION=$(flutter --version | grep -o "Flutter [0-9]*\.[0-9]*\.[0-9]*" | cut -d' ' -f2)
echo "✅ Flutter version: $FLUTTER_VERSION"

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p assets/images
mkdir -p assets/fonts

# Create placeholder files
echo "📝 Creating placeholder files..."
touch assets/images/.gitkeep
touch assets/fonts/.gitkeep

# Check if Supabase configuration needs to be updated
echo "🔧 Checking Supabase configuration..."
if grep -q "YOUR_SUPABASE_URL" lib/services/supabase_service.dart; then
    echo "⚠️  Please update Supabase configuration in lib/services/supabase_service.dart"
    echo "   - Replace YOUR_SUPABASE_URL with your actual Supabase URL"
    echo "   - Replace YOUR_SUPABASE_ANON_KEY with your actual Supabase anon key"
fi

# Create environment file template
echo "📄 Creating environment file template..."
cat > .env.template << EOF
# Supabase Configuration
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here

# Email Configuration (Optional)
SENDGRID_API_KEY=your_sendgrid_api_key_here
EMAIL_FROM=noreply@yourdomain.com
EOF

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📄 Creating .env file..."
    cp .env.template .env
    echo "⚠️  Please update .env file with your actual configuration values"
fi

# Check if web is enabled
echo "🌐 Checking Flutter web support..."
flutter config --list | grep -q "enable-web: true" || {
    echo "🌐 Enabling Flutter web support..."
    flutter config --enable-web
}

# Run Flutter doctor
echo "🔍 Running Flutter doctor..."
flutter doctor

# Create a simple test to verify setup
echo "🧪 Creating basic test..."
cat > test/setup_test.dart << EOF
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Basic setup test', () {
    expect(true, isTrue);
  });
}
EOF

# Create deployment script
echo "📜 Creating deployment script..."
cat > deploy.sh << 'EOF'
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
EOF

chmod +x deploy.sh

# Create development script
echo "📜 Creating development script..."
cat > dev.sh << 'EOF'
#!/bin/bash

echo "🛠️  Starting development server..."

# Check if Chrome is available
if command -v google-chrome &> /dev/null; then
    flutter run -d chrome --web-port 3000
elif command -v chromium-browser &> /dev/null; then
    flutter run -d chromium-browser --web-port 3000
else
    flutter run -d web-server --web-port 3000
fi
EOF

chmod +x dev.sh

echo ""
echo "✅ Setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Configure Supabase:"
echo "   - Create a Supabase project"
echo "   - Run database_schema.sql in Supabase SQL Editor"
echo "   - Run sample_data.sql in Supabase SQL Editor"
echo "   - Update lib/services/supabase_service.dart with your credentials"
echo ""
echo "2. Start development:"
echo "   ./dev.sh"
echo ""
echo "3. Build for production:"
echo "   ./deploy.sh"
echo ""
echo "📚 For more information, see README.md"
echo ""
echo "🎉 Happy coding!" 