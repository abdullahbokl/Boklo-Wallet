# Boklo Architecture Guide

This document outlines the architectural principles, structure, and guidelines for the Boklo application. It is intended for developers to ensure consistency and maintainability.

## 1. Architectural Pattern

Boklo follows **Clean Architecture** combined with a **Feature-First** directory structure. This separates concerns into three distinct layers:

### Layers

1.  **Presentation (UI)**: Widgets, Cubits/Blocs, State.
    - _Responsibility_: Display data and handle user interaction. Extends `BaseCubit` and `BaseState`.
    - _Rules_: No business logic in UI. Responsive via `ResponsiveBuilder`.
2.  **Domain (Business Logic)**: Entities, UseCases, Repository Interfaces.
    - _Responsibility_: Pure business logic.
    - _Rules_: No dependency on Flutter widgets or external libraries (serialization, databases).
3.  **Data (Infrastructure)**: DTOs, DataSources (Local/Remote), Repository Implementations.
    - _Responsibility_: Data retrieval and storage.
    - _Rules_: Handles serialization (`json_serializable`), caching, and networking (`Dio`).

## 2. Project Structure `lib/`

```
lib/
├── config/             # Environment, Routing, Theme
├── core/               # Shared logic reusable across features
│   ├── base/           # Base classes (BaseCubit, BaseState)
│   ├── di/             # Dependency Injection (GetIt/Injectable)
│   ├── error/          # AppError definitions
│   ├── network/        # ApiClient, Interceptors
│   ├── presentation/   # Shared Atomic Widgets (atoms, molecules)
│   └── utils/          # Result type, Helpers
├── features/           # Feature modules (Auth, Wallet, etc.)
│   └── [feature_name]/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── l10n/               # Localization ARB files
└── main_common.dart    # Entry point
```

## 3. Core Modules

### Base Architecture (`core/base`)

- **`BaseCubit`**: The foundation for all Cubits. Provides simpler APIs (`emitSuccess`, `emitError`) and `runBlocCatching` for safe async operations.
- **`BaseState`**: A sealed class (`Initial`, `Loading`, `Success`, `Error`) ensuring exhaustive state handling.

### Design System (`core/presentation/widgets`)

We follow **Atomic Design** principles for shared widgets:

- **Atoms**: Use `AppText`, `AppButton`. Do not use raw material widgets if an atom exists.
- **Molecules/Organisms**: Composed of atoms.

### Networking (`core/network`)

- **`ApiClient`**: Wrapper around Dio.
- **`ResponseWrapper`**: Standardizes API response parsing.
- **Offline-First**: Repositories should implement caching via `LocalDataSource` and sync via `RemoteDataSource`.

## 4. Responsive & Adaptive Design

### Guidelines

1.  **Golden Rule**: Use `ResponsiveBuilder` for layout changes.
2.  **No `MediaQuery`**: Do not use `MediaQuery.of(context)` for dimensions. Use `ScreenInfo` provided by `ResponsiveBuilder`.
3.  **Breakpoints**:
    - Mobile: < 600px
    - Tablet: 600px - 900px
    - Desktop: >= 900px

## 5. Coding Standards

- **State Management**: Use `flutter_bloc` with `BaseCubit`.
- **Immutability**: Use `freezed` for States, Events, and Entities.
- **Async**: Return `Result<T>` instead of throwing exceptions.
- **Localization**: All user-facing text must be in `l10n`.
