/// Defines the synchronization policy for repository operations.
///
/// This enum dictates how data is fetched and synchronized between
/// local storage and remote data sources.
enum SyncPolicy {
  /// Returns local data immediately, then fetches from remote and updates local.
  /// (Best for UI responsiveness with eventual consistency)
  cacheFirst,

  /// Fetches from remote first. If failed, falls back to local cache.
  /// (Best for critical data accuracy)
  networkFirst,

  /// Only fetches from local cache.
  cacheOnly,

  /// Only fetches from remote, no caching.
  networkOnly,
}
