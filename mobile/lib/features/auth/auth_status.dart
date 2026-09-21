/// Explicit states for the root-level auth pipeline, layered over
/// sessionControllerProvider + sessionExpiredProvider purely to give
/// app_root.dart's _RootGate a single named switch point instead of
/// scattered null/error checks. Screens elsewhere still read the user
/// directly off sessionControllerProvider — this isn't a replacement data
/// layer, just a routing-decision view.
enum AuthStatus { initializing, unauthenticated, sessionExpired, authenticated }
