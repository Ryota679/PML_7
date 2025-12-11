# 🏗️ Architecture Documentation

## Overview

Aplikasi ini menggunakan **Feature-First Architecture** dengan prinsip **Clean Architecture** yang disederhanakan untuk kemudahan development dan maintenance.

## Architecture Layers

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (UI Widgets, Pages, Screens)           │
│  Location: features/*/presentation/     │
└───────────────┬─────────────────────────┘
                │
                ↓
┌─────────────────────────────────────────┐
│      Presentation Logic Layer           │
│  (State Management, Providers)          │
│  Location: features/*/providers/        │
└───────────────┬─────────────────────────┘
                │
                ↓
┌─────────────────────────────────────────┐
│          Data Layer                     │
│  (Repositories, Data Sources)           │
│  Location: features/*/data/             │
└───────────────┬─────────────────────────┘
                │
                ↓
┌─────────────────────────────────────────┐
│      Infrastructure Layer               │
│  (External Services: Appwrite)          │
│  Location: core/config/                 │
└─────────────────────────────────────────┘
```

## Directory Structure

```
lib/
├── core/                          # Infrastructure & Shared Utilities
│   ├── config/                   # Configuration files
│   │   └── appwrite_config.dart  # Appwrite credentials
│   ├── constants/                # App-wide constants
│   │   └── app_constants.dart    # Role types, status enums
│   ├── router/                   # Navigation logic
│   │   └── app_router.dart       # GoRouter configuration
│   ├── theme/                    # UI theming
│   │   └── app_theme.dart        # Material 3 theme
│   └── utils/                    # Utility functions
│       └── logger.dart           # Logging wrapper
│
├── features/                      # Feature modules
│   ├── auth/                     # Authentication feature
│   │   ├── data/                 # Data layer
│   │   │   └── auth_repository.dart
│   │   ├── providers/            # State management
│   │   │   └── auth_provider.dart
│   │   └── presentation/         # UI layer
│   │       └── login_page.dart
│   │
│   ├── business_owner/           # Business Owner feature
│   │   └── presentation/
│   │       └── business_owner_dashboard.dart
│   │
│   └── tenant/                   # Tenant feature
│       └── presentation/
│           └── tenant_dashboard.dart
│
└── shared/                       # Shared across features
    ├── models/                   # Domain entities
    │   └── user_model.dart
    ├── providers/                # Global providers
    │   └── appwrite_provider.dart
    └── widgets/                  # Reusable UI components
        ├── loading_widget.dart
        └── error_widget.dart
```

## Data Flow Example: Login

```dart
1. User Input
   ↓
2. LoginPage (Presentation)
   - Validates form
   - Calls authProvider.login()
   ↓
3. AuthNotifier (Providers)
   - Manages auth state
   - Calls authRepository.login()
   ↓
4. AuthRepository (Data)
   - Calls Appwrite Account service
   - Transforms response to UserModel
   ↓
5. Appwrite (Infrastructure)
   - Authenticates user
   - Returns session
   ↓
6. State Update
   - AuthNotifier updates state
   - UI rebuilds via Riverpod
   ↓
7. Navigation
   - AppRouter redirects based on role
   - Shows appropriate dashboard
```

## Design Patterns Used

### 1. **Repository Pattern**
```dart
// Abstraction over data sources
class AuthRepository {
  final Account account;
  final Databases database;
  
  Future<Session> login({...}) async {
    // Encapsulates Appwrite calls
  }
}
```

### 2. **Provider Pattern (Dependency Injection)**
```dart
// Riverpod providers for DI
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final account = ref.watch(appwriteAccountProvider);
  final database = ref.watch(appwriteDatabaseProvider);
  return AuthRepository(account: account, database: database);
});
```

### 3. **State Management (Riverpod)**
```dart
// Centralized state management
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository authRepository;
  // Manages authentication state
}
```

### 4. **Model-View Pattern**
```dart
// Separation of data and presentation
UserModel (Model) → AuthProvider (Logic) → LoginPage (View)
```

## Dependency Rules

### ✅ Allowed Dependencies:
- Presentation → Providers → Data → Infrastructure
- Any layer → Shared (models, widgets, providers)
- Any layer → Core (config, constants, utils)

### ❌ Forbidden Dependencies:
- Data → Providers
- Data → Presentation
- Infrastructure → Features
- Lower layers → Higher layers

## Benefits

### 1. **Maintainability**
- Clear separation of concerns
- Easy to locate and modify code
- Changes in one layer don't affect others

### 2. **Testability**
- Each layer can be tested independently
- Easy to mock dependencies
- Providers and repositories are unit-testable

### 3. **Scalability**
- Easy to add new features
- Features are independent
- Shared code is centralized

### 4. **Documentation**
- Self-documenting structure
- Clear naming conventions
- Easy to onboard new developers

## Adding New Features

### Step-by-step guide:

1. **Create feature folder:**
   ```
   features/new_feature/
   ```

2. **Add layers as needed:**
   ```
   features/new_feature/
   ├── data/              # If needs data access
   │   └── repository.dart
   ├── providers/         # If needs state management
   │   └── provider.dart
   └── presentation/      # UI components
       └── page.dart
   ```

3. **Create models if needed:**
   ```
   shared/models/
   └── new_model.dart
   ```

4. **Update router:**
   ```dart
   // core/router/app_router.dart
   GoRoute(
     path: '/new-feature',
     builder: (context, state) => NewFeaturePage(),
   )
   ```

## Code Organization Principles

### 1. **Feature-First**
Group by feature, not by technical layer

### 2. **DRY (Don't Repeat Yourself)**
Shared code goes to `shared/`

### 3. **Single Responsibility**
Each file has one clear purpose

### 4. **Dependency Inversion**
Depend on abstractions (providers), not concrete implementations

## Technology Stack

| Layer | Technology |
|-------|-----------|
| **State Management** | Riverpod 2.5.1 |
| **Routing** | GoRouter 14.6.2 |
| **Backend** | Appwrite 13.0.0 |
| **Local DB** | Drift 2.20.3 |
| **Logging** | Logger 2.4.0 |

## Performance Considerations

- **Lazy Loading**: Features loaded on-demand
- **Provider Caching**: Riverpod caches providers automatically
- **Efficient Rebuilds**: Only affected widgets rebuild
- **Optimized Navigation**: GoRouter for declarative routing

## Future Improvements

As the app grows, consider:

1. **Use Cases Layer**: Separate business logic from providers
2. **Abstract Repositories**: Interface-based repositories
3. **Error Handling**: Centralized error handling
4. **Logging**: More comprehensive logging strategy
5. **Analytics**: User behavior tracking

## References

- [Flutter Clean Architecture](https://resocoder.com/flutter-clean-architecture-tdd/)
- [Riverpod Documentation](https://riverpod.dev/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Appwrite Documentation](https://appwrite.io/docs)

---

**Last Updated**: Sprint 1 - November 18, 2025
**Version**: 1.0.0
