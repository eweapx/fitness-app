#!/bin/bash

# Stop on errors
set -e

echo "Preparing Flutter Web App..."

# Create the public directory
mkdir -p public

# Check if we already have a build in fitness_tracker/build/web or build/web
if [ -d "build/web" ] && [ -f "build/web/index.html" ]; then
  echo "Using existing Flutter web build from build/web..."
  
  # Copy the build to the public directory
  echo "Copying build files to public directory..."
  cp -R build/web/* public/
  
  echo "Copied build files to public directory"
  echo "You can now start the web server to view the application"
  exit 0
elif [ -d "fitness_tracker/build/web" ] && [ -f "fitness_tracker/build/web/index.html" ]; then
  echo "Using existing Flutter web build from fitness_tracker/build/web..."
  
  # Copy the build to the public directory
  echo "Copying build files to public directory..."
  cp -R fitness_tracker/build/web/* public/
  
  echo "Copied build files to public directory"
  echo "You can now start the web server to view the application"
  exit 0
fi

echo "No existing build found. Building Flutter Web App from scratch..."

# Go to fitness_tracker directory
cd fitness_tracker

# Enable web support
echo "Enabling web support..."
flutter config --enable-web

# Get dependencies without cleaning (to speed up build)
echo "Getting dependencies..."
flutter pub get

# Build web version with environment variables for Firebase
echo "Building web version..."
flutter build web \
  --dart-define=FIREBASE_API_KEY="$FIREBASE_API_KEY" \
  --dart-define=FIREBASE_APP_ID="$FIREBASE_APP_ID" \
  --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID"

echo "Flutter Web build completed!"

# Create the target directory for the web build
mkdir -p ../public

# Copy the build to the public directory for serving
echo "Copying build files to public directory..."
cp -R build/web/* ../public/

echo "Copied build files to public directory"
echo "You can now start the web server to view the application"