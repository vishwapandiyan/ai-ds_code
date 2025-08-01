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
