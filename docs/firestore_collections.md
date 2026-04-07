# Firestore Collections

This app now uses Firestore-only staff signup and login for driver and konduktor accounts. Because Firebase Auth is intentionally not used in this phase, Firestore rules can only validate document shape and limit broad reads. They cannot provide strong identity guarantees on their own.

## Collections

### `driver_accounts`

Document ID:
- normalized username, for example `konduktor03`

Fields:
- `username`: normalized username string
- `passwordHash`: SHA-256 hash used by the current Firestore-only login flow
- `name`: display name shown in profile and live bus identity
- `role`: `driver` or `konduktor`
- `badge`: unique bus badge used as the live bus key
- `assignedRoutes`: list of route IDs the account can operate
- `isActive`: account activation flag
- `createdAt`: server timestamp
- `updatedAt`: server timestamp
- `lastLoginAt`: server timestamp

Notes:
- The app reads a single account document by username during login.
- Listing this collection is denied in `firestore.rules`, but direct `get` access is still required because login is client-side.
- Plain-text `password` is considered legacy only; current writes use `passwordHash`.

### `driver_badges`

Document ID:
- normalized badge, for example `BUS-005`

Fields:
- `badge`: badge string matching the document ID
- `username`: owning account username
- `createdAt`: server timestamp
- `updatedAt`: server timestamp when the badge reservation changes

Purpose:
- reserves badge uniqueness independently of `driver_accounts`
- prevents two staff accounts from claiming the same live bus identifier

### `bus_locations`

Document ID:
- badge, for example `BUS-005`

Fields used by the current app:
- `driverBadge`
- `driverName`
- `routeId`
- `variantId`
- `lat`
- `lng`
- `currentStopIndex`
- `isActive`
- `timestamp`
- `occupancyStatus`
- `occupancyLastUpdated`

Purpose:
- source of truth for each active bus
- now also stores per-bus occupancy, which prevents multiple buses on the same route from overwriting one another

Aggregation rules in the app:
- route status is derived as `unavailable` only from manual route overrides, otherwise `operating` when at least one active bus exists, otherwise `onStandby`
- route occupancy is derived from active bus documents, using the highest occupancy severity across active buses on the route

### `route_status`

Document ID:
- route ID, for example `r102`

Current role:
- manual route-level override collection
- the app now treats `unavailable` as the only hard override that wins over live bus activity

Fields:
- `routeId`
- `status`
- `lastUpdatedAt`
- `lastUpdatedBy`

Legacy fields that may still exist:
- `occupancyStatus`
- `occupancyLastUpdated`

Notes:
- route occupancy should no longer be sourced from this collection for passenger displays
- existing legacy occupancy fields can remain for compatibility, but the app now derives occupancy from `bus_locations`

## Operational Notes

1. Changing a staff badge updates both `driver_accounts` and `driver_badges`.
2. The app should block badge and route changes while a staff member is actively operating a route.
3. Clearing a bus location also clears its per-bus occupancy fields so a future trip does not inherit stale passenger data.
4. The active driver trip screen pushes the current bus location to `bus_locations` immediately, then roughly every 10 seconds while the trip remains open in the foreground.

## Security Limitation

Without Firebase Auth, the app must read account documents directly from the client during login. The provided `firestore.rules` file narrows reads and validates schemas, but it cannot fully protect credential material in a production-grade way. If this moves beyond internal or demo use, migrate sign-in to Firebase Auth and keep Firestore for staff profile and operations data.