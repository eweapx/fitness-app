# Fuel Fitness App Architecture

## Overview

Fuel Fitness is a cross-platform fitness tracking application built with Flutter for the frontend and Firebase for backend services. The application allows users to track their fitness activities, calories burned, and health metrics across multiple platforms (Android, iOS, web, desktop).

The architecture follows a client-server model with:
- A Flutter frontend for cross-platform UI
- Firebase services for authentication and data storage
- A Node.js Express server for web hosting and API endpoints
- Native health data integration on mobile platforms

## System Architecture

### High-Level Architecture

```
┌─────────────────┐     ┌───────────────────┐     ┌─────────────────┐
│                 │     │                   │     │                 │
│  Flutter UI     │────▶│  Firebase Services│◀───▶│  Express Server │
│  (Cross-platform)│    │  (Auth/Firestore) │     │  (Web/API)      │
│                 │     │                   │     │                 │
└────────┬────────┘     └───────────────────┘     └─────────────────┘
         │                                               ▲
         │                                               │
         ▼                                               │
┌────────────────┐                               ┌───────────────┐
│                │                               │               │
│  Native Health │                               │  Jest Tests   │
│  Integration   │                               │               │
│                │                               │               │
└────────────────┘                               └───────────────┘
```

### Architecture Decisions

1. **Cross-Platform Development**: Flutter was chosen to enable a single codebase for all platforms (web, iOS, Android, desktop), reducing development and maintenance costs.

2. **Client-Server Model**: The app follows a client-server architecture with:
   - Client: Flutter UI that runs on multiple platforms
   - Server: Firebase for backend services and data storage

3. **Backend as a Service (BaaS)**: Firebase was chosen as the backend solution to handle:
   - User authentication
   - Data persistence via Firestore
   - Real-time data synchronization

4. **Express Server**: A Node.js Express server is used to:
   - Serve the web version of the application
   - Provide API endpoints for non-Firebase operations
   - Support health checks and monitoring

## Key Components

### Frontend (Flutter)

The Flutter application follows a layered architecture:

1. **Presentation Layer**: Contains screens and widgets
   - `screens/`: Contains main application screens (home, profile, login)
   - `widgets/`: Reusable UI components (activity chart, log dialog)

2. **Service Layer**: Manages business logic and external service integrations
   - `services/`: Contains service classes for auth, health data, voice commands

3. **Utility Layer**: Provides helper functions and cross-cutting concerns
   - `utils/`: Contains utilities for logging, connectivity, environment config

### Backend Services

1. **Firebase Authentication**: Handles user registration, login, and session management

2. **Cloud Firestore**: NoSQL database for storing:
   - User profiles
   - Activity records
   - Application logs

3. **Express Server**: Provides HTTP endpoints for:
   - Health check API (`/api/health`)
   - Static file serving
   - Web application hosting

### Health Data Integration

The application integrates with device health APIs to access fitness data:
- Uses the `health` package for accessing health data from Google Fit/Apple Health
- Requests permissions for step count, heart rate, and energy data
- Supports activity tracking for running, cycling, weights, and swimming

### Voice Command Processing

The app includes voice command capabilities for hands-free operation:
- Uses the `speech_to_text` package to recognize user commands
- Parses natural language to extract activity details (type, duration, calories)

## Data Flow

### User Authentication Flow

1. User enters credentials in the login screen
2. Flutter app calls Firebase Auth API
3. Firebase validates credentials and returns user token
4. App stores authentication token for subsequent requests
5. User profile is loaded from Firestore

### Activity Tracking Flow

1. User grants health permissions
2. App reads health data from device APIs
3. Data is processed and displayed in the UI
4. When user logs an activity manually:
   - Activity is stored locally
   - Activity is synchronized with Firestore
   - Stats are updated in the UI

### Offline Handling

1. The app uses connectivity detection to monitor network status
2. When offline:
   - Operations are queued for later synchronization
   - UI indicates offline status to the user
3. When connectivity is restored, pending operations are executed

## External Dependencies

### Flutter Packages

1. **State Management**:
   - `provider`: For state management using the Provider pattern

2. **Firebase Integration**:
   - `firebase_core`: Firebase core functionality
   - `firebase_auth`: Authentication services
   - `cloud_firestore`: NoSQL database access

3. **Device Integration**:
   - `health`: For accessing health/fitness data from platform APIs
   - `permission_handler`: Managing system permissions
   - `speech_to_text`: Voice recognition capabilities

4. **Utilities**:
   - `intl`: Internationalization and formatting
   - `shared_preferences`: Local storage
   - `url_launcher`: Opening external links

### Server Dependencies

1. **Express.js**: Web server framework
2. **Jest**: Testing framework for JavaScript code

## Deployment Strategy

### Mobile Deployment

The application is configured for deployment to:
- Android devices (via Google Play Store)
- iOS devices (via Apple App Store)
- Testing via CI/CD pipelines

### Web Deployment

The web version can be deployed in two ways:
1. **Static hosting**: The Flutter web build output can be deployed to static hosting services
2. **Express server**: The application includes an Express.js server that can serve the web application

### Development Environment

The project includes configuration for:
- Replit: For collaborative development and testing
- Local development: Using Flutter and Node.js tools
- Automated testing: Using Jest for JavaScript and Flutter testing framework

### Automated Testing

The project includes:
- Flutter widget tests: For UI component testing
- Jest tests for JavaScript components:
  - Unit tests for activity and fitness tracker models
  - Integration tests for the Express server