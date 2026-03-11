# Flutter App — Complete Refactoring & Rearchitecture Plan

> **Goal:** Transform the Flutter application into a clean, maintainable, scalable codebase following Clean Architecture, SOLID principles, separated BLoC/Cubit states with `copyWith`, GetIt scopes, a strict 120-line file limit, and enhanced UI/UX.

---

## Phase 1: Project Audit & Preparation

### Step 1.1 — Catalog the current codebase
- Map every file in `lib/` and note its responsibility (UI, state, data, routing, DI, utils).
- Identify files exceeding 120 lines — these are the first refactoring targets.
- List every BLoC/Cubit and its current state handling approach.
- List all direct dependencies in `pubspec.yaml`.

### Step 1.2 — Define the target folder structure
Adopt a **feature-first Clean Architecture** layout:

```
lib/
├── app/
│   ├── app.dart                  # MaterialApp / root widget
│   ├── router.dart               # GoRouter / AutoRoute config
│   └── theme/
│       ├── preparatoryapp_theme.dart        # ThemeData definitions
│       ├── app_colors.dart       # Color constants
│       ├── app_text_styles.dart  # TextStyle constants
│       └── app_dimensions.dart   # Spacing, radius, sizing
├── core/
│   ├── di/
│   │   ├── injection.dart        # Top-level GetIt setup
│   │   └── scopes/               # Per-feature GetIt scopes
│   │       ├── auth_scope.dart
│   │       └── home_scope.dart
│   ├── error/
│   │   ├── failures.dart         # Failure sealed class
│   │   └── exceptions.dart       # Custom exceptions
│   ├── network/
│   │   ├── api_client.dart       # Dio / http setup
│   │   └── interceptors/
│   ├── usecases/
│   │   └── usecase.dart          # Abstract UseCase<Type, Params>
│   └── extensions/
│       ├── context_extensions.dart
│       └── string_extensions.dart
├── features/
│   └── <feature_name>/           # e.g. auth, home, profile
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── <feature>_remote_datasource.dart
│       │   │   └── <feature>_local_datasource.dart
│       │   ├── models/
│       │   │   └── <feature>_model.dart   # fromJson/toJson
│       │   └── repositories/
│       │       └── <feature>_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── <feature>_entity.dart
│       │   ├── repositories/
│       │   │   └── <feature>_repository.dart  # Abstract
│       │   └── usecases/
│       │       └── get_<feature>.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── <feature>_cubit.dart
│           │   └── <feature>_state.dart   # Separate file
│           ├── pages/
│           │   └── <feature>_page.dart
│           └── widgets/
│               └── <feature>_card.dart
└── main.dart                     # Entry point, init DI
```

### Step 1.3 — Add / update dependencies
Ensure the following packages are present in `pubspec.yaml`:

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | State management |
| `get_it` | Dependency injection |
| `injectable` + `injectable_generator` | DI code-gen (optional) |
| `dio` | Networking |
| `dartz` or `fpdart` | `Either<Failure, T>` |
| `go_router` or `auto_route` | Declarative routing |
| `freezed` + `freezed_annotation` | Immutable states with `copyWith` |
| `json_serializable` | Model serialization |
| `equatable` | Value equality (if not using freezed) |
| `very_good_analysis` | Strict linting |

---

## Phase 2: BLoC / Cubit State Separation

### Step 2.1 — Create a dedicated state file per Cubit/BLoC

Every Cubit or BLoC **must** have its state in a **separate file** named `<feature>_state.dart`.

**State design rules:**
- Use a single class with a `Status` enum (`initial`, `loading`, `loaded`, `error`).
- All fields `final`. Class `extends Equatable` (or use `freezed`).
- Implement a `copyWith` method for immutable updates.
- Keep state files under 80 lines; split into sub-states if needed.

**Example — Equatable approach:**

```dart
// file: auth_state.dart

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}
```

**Example — Freezed approach (recommended):**

```dart
// file: auth_state.dart

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(AuthStatus.initial) AuthStatus status,
    UserEntity? user,
    String? errorMessage,
  }) = _AuthState;
}
```

### Step 2.2 — Refactor each Cubit/BLoC
- Emit states **only** via `state.copyWith(...)`.
- No business logic inside Cubits — delegate to UseCases.
- Cubit file contains **only** the Cubit class (no state, no helpers).
- Target: Cubit files ≤ 100 lines. Split into sub-Cubits if larger.

**Example — Cubit using copyWith:**

```dart
// file: auth_cubit.dart

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;

  AuthCubit(this._loginUseCase) : super(const AuthState());

  Future<void> login(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _loginUseCase(
      LoginParams(email: email, password: password),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (user) => emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      )),
    );
  }
}
```

### Step 2.3 — BLoC event files (if using BLoC instead of Cubit)
- Create a separate `<feature>_event.dart` file.
- Use `sealed class` (Dart 3+) or abstract + concrete subclasses.
- Keep each event class minimal (just the payload).

```dart
// file: auth_event.dart

sealed class AuthEvent {
  const AuthEvent();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested({required this.email, required this.password});
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
```

---

## Phase 3: Clean Architecture Layers

### Step 3.1 — Domain layer (innermost, zero dependencies)

| Component | Rules |
|-----------|-------|
| **Entities** | Pure Dart classes. No framework imports. No `fromJson`. |
| **Repository contracts** | Abstract classes. Return `Future<Either<Failure, T>>`. |
| **UseCases** | One public `call()` method. Inject repository via constructor. |

**UseCase base class:**

```dart
// file: core/usecases/usecase.dart

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
```

### Step 3.2 — Data layer (implements domain contracts)

| Component | Rules |
|-----------|-------|
| **Models** | Extend/map to entities. Contain `fromJson` / `toJson`. |
| **DataSources** | Abstract + concrete. Remote (API) and Local (cache). |
| **Repository impls** | Combine data sources, catch exceptions, return `Either<Failure, T>`. |

### Step 3.3 — Presentation layer (depends on domain only)

| Component | Rules |
|-----------|-------|
| **Pages** | Stateless widgets. Provide BLoC via `BlocProvider`. Compose widgets. |
| **Widgets** | Small, reusable, stateless. Each in its own file. |
| **BLoC/Cubit + State** | As described in Phase 2. |

### Step 3.4 — Dependency rule enforcement
- ✅ Domain **MUST NOT** import data or presentation.
- ✅ Data **MUST NOT** import presentation.
- ✅ Presentation imports domain (entities, use cases) but **NEVER** data directly.
- Add custom lint rules in `analysis_options.yaml` to enforce import boundaries.

---

## Phase 4: GetIt Scopes

### Step 4.1 — Top-level registration (`core/di/injection.dart`)

```dart
final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // --- Core ---
  getIt.registerLazySingleton<Dio>(() => createDio());
  getIt.registerLazySingleton<SharedPreferences>(
    () => SharedPreferences.getInstance(),
  );

  // --- App-wide repositories ---
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt(), getIt()),
  );
}
```

Call `await configureDependencies()` in `main.dart` before `runApp`.

### Step 4.2 — Feature-level scoped registration

For features with a limited lifecycle (auth flow, checkout, onboarding), use **GetIt scopes**:

```dart
// file: core/di/scopes/auth_scope.dart

void pushAuthScope() {
  GetIt.I.pushNewScope(
    scopeName: 'auth',
    init: (getIt) {
      getIt.registerFactory(() => LoginUseCase(getIt<AuthRepository>()));
      getIt.registerFactory(() => AuthCubit(getIt<LoginUseCase>()));
    },
  );
}

void popAuthScope() {
  GetIt.I.popScope();
}
```

### Step 4.3 — Scope helper widget (recommended)

```dart
// file: core/di/scope_provider.dart

class ScopeProvider extends StatefulWidget {
  final String scopeName;
  final void Function(GetIt getIt) init;
  final Widget child;

  const ScopeProvider({
    required this.scopeName,
    required this.init,
    required this.child,
  });

  @override
  State<ScopeProvider> createState() => _ScopeProviderState();
}

class _ScopeProviderState extends State<ScopeProvider> {
  @override
  void initState() {
    super.initState();
    GetIt.I.pushNewScope(
      scopeName: widget.scopeName,
      init: widget.init,
    );
  }

  @override
  void dispose() {
    GetIt.I.popScope();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

### Step 4.4 — Registration conventions

| Type | Method | When |
|------|--------|------|
| **Singleton** | `registerLazySingleton` | Services, API clients, shared repos |
| **Factory** | `registerFactory` | Cubits/BLoCs (new instance per screen) |
| **Scoped** | Inside `pushNewScope` | Feature-specific dependencies |

> Always register by **abstract type** and resolve against the interface.

---

## Phase 5: Enforce 120-Line File Limit

### Step 5.1 — Identify violations

Run from project root:

```bash
find lib -name '*.dart' -exec awk 'END{if(NR>120) print FILENAME": "NR" lines"}' {} \;
```

### Step 5.2 — Splitting strategies

| File Type | Strategy |
|-----------|----------|
| **Page widget** | Extract sections into widget files in `widgets/` |
| **Cubit/BLoC** | Move state → `_state.dart`, events → `_event.dart`, helpers → UseCase |
| **Repository impl** | Split per-method into helper classes |
| **Model** | Move mapping logic to extension files |
| **Theme / Constants** | Split by concern: colors, text styles, dimensions |
| **Utility files** | Split into focused extensions or helper classes |

### Step 5.3 — Add a lint rule

In `analysis_options.yaml` or using `dart_code_metrics` / `dcm`:

```yaml
dart_code_metrics:
  metrics:
    - source-lines-of-code: 120
  rules:
    - prefer-extracting-callbacks
    - prefer-single-widget-per-file
```

Run in CI: `dart run dcm analyze lib`

---

## Phase 6: SOLID Principles Enforcement

### 6.1 — Single Responsibility (SRP)
- Every class has **one reason to change**.
- Cubits only orchestrate state. UseCases only execute business logic. Repositories only fetch/store data.
- If a class name needs "And" to describe it, split it.

### 6.2 — Open/Closed (OCP)
- Use abstract repository contracts so new data sources can be added without modifying existing code.
- Use strategy/factory patterns for features with multiple variants (e.g., payment methods).

### 6.3 — Liskov Substitution (LSP)
- Repository implementations must fully satisfy the abstract contract.
- Avoid throwing unrelated exceptions from overridden methods.

### 6.4 — Interface Segregation (ISP)
- Keep repository interfaces small and focused.
- If a repository grows beyond 5–6 methods, split it into role-specific interfaces.

### 6.5 — Dependency Inversion (DIP)
- Cubits depend on abstract UseCases/Repositories, **never** concrete implementations.
- All concrete wiring happens in `core/di/` via GetIt.
- No `new ConcreteClass()` inside business logic.

---

## Phase 7: UI/UX Enhancements

### 7.1 — Design system & theming
- Centralize all colors, typography, spacing in `app/theme/`.
- Use `Theme.of(context)` and `context.textTheme` everywhere — **zero hardcoded values**.
- Support light & dark themes via `ThemeMode`.
- Create semantic color aliases: `surfacePrimary`, `textSecondary`, etc.

### 7.2 — Loading & error states
- Create reusable components:
  - `ShimmerPlaceholder` — skeleton loading for lists/grids.
  - `ErrorView` — icon + message + retry button.
  - `EmptyStateView` — illustration + message + CTA.
- Use `BlocBuilder` / `BlocConsumer` with `buildWhen` to rebuild only what changed.
- Never show a blank screen — always show meaningful feedback.

### 7.3 — Animations & transitions
- `Hero` animations for shared elements between list → detail pages.
- `AnimatedSwitcher` for state transitions (loading → loaded → error).
- Page transitions via the router (slide, fade, shared axis).
- `AnimatedContainer` for expandable sections.

### 7.4 — Responsive layout
- Use `LayoutBuilder` or `MediaQuery` to adapt between mobile and tablet.
- Extract breakpoints into `app_dimensions.dart`.
- Consider `Sliver` widgets for complex scrollable layouts.

### 7.5 — Accessibility
- Add `Semantics` widgets to all interactive elements.
- Ensure sufficient color contrast (4.5:1 minimum).
- Support dynamic font scaling (`MediaQuery.textScaleFactorOf`).
- Test with TalkBack / VoiceOver.

### 7.6 — Micro-interactions
- Haptic feedback on key actions (`HapticFeedback.lightImpact()`).
- `SnackBar` or toast for success/error feedback — never fail silently.
- Pull-to-refresh on list screens (`RefreshIndicator`).
- Subtle scale/opacity animations on tap.

---

## Phase 8: Additional Best Practices

### 8.1 — Error handling

```dart
// file: core/error/failures.dart

sealed class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}
```

- All repository methods return `Future<Either<Failure, T>>`.
- Map exceptions → failures at the repository boundary.
- Never let raw exceptions reach the UI layer.

### 8.2 — Routing
- Use `go_router` (declarative, type-safe).
- Keep route definitions in `app/router.dart` — one file, under 120 lines.
- Use typed route parameters / extras instead of passing raw data.
- Guard routes with `redirect` for auth-protected pages.

### 8.3 — Logging & debugging
- Add a `LoggerService` in `core/` wrapping `logger` package.
- Log all API calls, errors, and navigation events in debug mode.
- Strip logs in release builds.

### 8.4 — Testing readiness
The architecture makes every layer independently testable:

| Layer | Test Type | Mock |
|-------|-----------|------|
| **Domain** | Unit test UseCases | Mocked repositories |
| **Data** | Unit test repositories | Mocked data sources |
| **Presentation** | Widget test pages | `MockCubit` via `bloc_test` |
| **Integration** | Flow tests | Real or fake DI setup |

- Each testable class receives dependencies via **constructor injection**.
- Never use `GetIt.I<T>()` inline in business logic — inject in DI layer only.

### 8.5 — Code generation (optional but recommended)

| Tool | Purpose |
|------|---------|
| `freezed` | Immutable states/entities with `copyWith`, `==`, `toString` |
| `json_serializable` | Model `fromJson` / `toJson` |
| `injectable` | GetIt registration code-gen |

Run: `dart run build_runner build --delete-conflicting-outputs`

---

## Execution Order

| # | Phase | Priority | Effort | Description |
|---|-------|----------|--------|-------------|
| 1 | Phase 1 | 🔴 Critical | Low | Audit codebase, set up folder structure, update deps |
| 2 | Phase 3 | 🔴 Critical | High | Implement Clean Architecture layers |
| 3 | Phase 2 | 🔴 Critical | Medium | Separate all BLoC/Cubit states with `copyWith` |
| 4 | Phase 4 | 🟡 High | Medium | Implement GetIt scopes per feature |
| 5 | Phase 5 | 🟡 High | Medium | Enforce 120-line file limit across all files |
| 6 | Phase 6 | 🟡 High | Low | SOLID audit and fixes |
| 7 | Phase 7 | 🟢 Normal | High | UI/UX enhancements |
| 8 | Phase 8 | 🟢 Normal | Medium | Error handling, routing, logging, testing |

---

## Quick Reference Checklist

- [ ] Every feature follows `data/` → `domain/` → `presentation/` structure
- [ ] Every Cubit/BLoC has a **separate** `_state.dart` file
- [ ] All state updates use `state.copyWith(...)`
- [ ] No file exceeds 120 lines
- [ ] GetIt scopes are used for feature-specific dependencies
- [ ] Domain layer has zero imports from data or presentation
- [ ] All repositories return `Either<Failure, T>`
- [ ] UseCases have a single `call()` method
- [ ] No hardcoded colors, sizes, or strings in widgets
- [ ] Reusable loading/error/empty widgets exist
- [ ] `analysis_options.yaml` enforces strict linting
- [ ] Constructor injection everywhere — no inline service locator calls in logic

---

> **Usage:** Open your Flutter project workspace and feed this plan to the AI agent to get file-specific, line-by-line refactoring actions applied automatically.

