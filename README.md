# Hackethos4U

A Flutter application with BLoC state management, Firebase authentication, and role-based navigation.

## Features

- **Authentication**: Email/password, Google Sign-in, and Phone OTP authentication
- **State Management**: BLoC pattern with proper separation of concerns
- **Role-based Navigation**: Admin and User home screens based on email pattern
- **Dark Mode**: System-wide theme switching with persistent storage
- **Connectivity**: Internet connectivity monitoring with snackbar notifications
- **Session Management**: Persistent authentication state
- **Clean Architecture**: Proper folder structure with dependency injection

## Project Structure

```
lib/
├── src/
│   ├── core/
│   │   ├── bloc/
│   │   │   ├── auth/           # Authentication state management
│   │   │   ├── connectivity/   # Internet connectivity management
│   │   │   └── theme/          # Dark/Light theme management
│   │   ├── constants/
│   │   │   └── app_constants.dart
│   │   ├── di/
│   │   │   └── service_locator.dart
│   │   ├── router/
│   │   │   └── app_router.dart
│   │   └── theme/
│   │       └── app_theme.dart
│   ├── data/
│   │   └── repositories/
│   │       ├── auth_repository.dart
│   │       ├── connectivity_repository.dart
│   │       └── theme_repository.dart
│   └── presentation/
│       ├── screens/
│       │   ├── splash/
│       │   ├── login/
│       │   └── home/
│       └── widgets/
│           └── common/
├── firebase_options.dart
└── main.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.1.4)
- Firebase project setup
- Android Studio / VS Code

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Place your `google-services.json` in `android/app/`
   - Update Firebase configuration as needed

4. Run the application:
   ```bash
   flutter run
   ```

## Authentication

The app supports three authentication methods:

1. **Email/Password**: Traditional login with validation
2. **Google Sign-in**: OAuth authentication with Google
3. **Phone OTP**: SMS-based verification

## Role-based Access

- **Admin**: Users with "admin" in their email address
- **User**: Regular users with standard access

## State Management

The app uses BLoC pattern for state management:

- `AuthBloc`: Handles authentication state
- `ConnectivityBloc`: Monitors internet connectivity
- `ThemeBloc`: Manages dark/light theme switching

## Dependencies

- `flutter_bloc`: State management
- `firebase_auth`: Authentication
- `google_sign_in`: Google authentication
- `connectivity_plus`: Network connectivity
- `shared_preferences`: Local storage
- `get_it`: Dependency injection

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
