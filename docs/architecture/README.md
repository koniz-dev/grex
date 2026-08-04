# Architecture Documentation

Comprehensive documentation about the architecture and design decisions of this Flutter Clean Architecture template.

## Overview

This section covers:
- Why Clean Architecture was chosen
- Architecture layers and their responsibilities
- Design decisions and rationale
- Trade-offs and alternatives
- When to use this template

## Documentation

### Core Architecture

- **[Architecture Overview](overview.md)** - Why Clean Architecture, benefits, trade-offs, when to use, and learning resources
- **[State Management & Dependency Injection](state-management.md)** - How BLoC, Riverpod, and GetIt divide responsibility, the rules for adding code, and known defects in the seam **(read this first)**
- **[Design Decisions](design-decisions.md)** - Original rationale for routing, state management, error handling, logging, storage, and HTTP client choices. ⚠️ Its state-management and HTTP-client sections are outdated — see the two docs above

### Related Documentation

- **[Understanding the Codebase](../guides/onboarding/understanding-codebase.md)** - Architecture and code organization
- **[Common Tasks](../guides/features/common-tasks.md)** - How to add features following Clean Architecture
- **[Adding Features](../api/examples/adding-features.md)** - Step-by-step guide to adding new features
- **[API Documentation](../api/README.md)** - Complete API reference

## Quick Start

New to the architecture? Start here:

1. Read [Architecture Overview](overview.md) to understand why Clean Architecture
2. Read [State Management & DI](state-management.md) — three systems run side by side; this says which owns what
3. Review [Design Decisions](design-decisions.md) to understand technical choices
3. Check [Understanding the Codebase](../guides/onboarding/understanding-codebase.md) for code organization
4. Follow [Common Tasks](../guides/features/common-tasks.md) to add your first feature

## Architecture Layers

```
┌─────────────────────────────────────┐
│   Presentation Layer (UI)           │
│  - Screens, Widgets, BLoCs          │
│  - State: BLoC + Riverpod + GetIt   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Domain Layer                   │
│  - Entities, Use Cases, Repositories │
│  - Business Logic (Framework-free)   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Data Layer                     │
│  - Models, Data Sources, Repository  │
│  - Implementations                   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Core Layer                     │
│  - Network, Storage, Config, Utils   │
└─────────────────────────────────────┘
```

For detailed information, see [Architecture Overview](overview.md).

