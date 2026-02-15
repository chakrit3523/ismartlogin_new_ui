# Hexagonal Architecture (BLoC-first)

## Layout

- `app/`: application bootstrap and top-level wiring.
- `core/`: shared abstractions (network, failures, use cases, DI, shared BLoC helpers).
- `features/<feature>/domain`: entities, repository contracts, use cases.
- `features/<feature>/data`: API/local adapters + repository implementations.
- `features/<feature>/presentation`: BLoC/Cubit + pages/widgets.

## Migration rule

1. New business logic goes into `features/*/domain` and `features/*/data`.
2. UI state must be managed by BLoC/Cubit.
3. Legacy `lib/page/*` path has been removed from the runtime code.
4. Runtime imports must point to `lib/src/*` only.

## Transitional helper

`blocSetState(...)` is available from
`src/core/presentation/bloc/bloc_material.dart`.

It is a temporary bridge to remove direct `setState` calls while moving
screen logic into dedicated Cubits.
