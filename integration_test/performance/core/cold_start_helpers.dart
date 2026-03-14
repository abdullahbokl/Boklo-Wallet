import 'package:boklo/core/di/di_initializer.dart';
import 'package:flutter/painting.dart';

/// Simulates a cold-start by clearing all caches and resetting DI.
///
/// This forces:
/// - All decoded images to be re-decoded (image cache clear)
/// - All singletons (Cubits, Repos, Services) to be re-created (DI reset)
/// - Impeller to re-compile shaders for widgets it hasn't seen in this run
///   (shaders are process-level, so a DI reset alone won't clear them, but
///    it does force widget tree reconstruction which re-triggers pipeline ops)
Future<void> simulateColdStart({String environment = 'dev'}) async {
  print('   🧊 Clearing image cache...');
  clearImageCache();
  print('   🧊 Resetting DI...');
  await resetDependencyInjection(environment: environment);
  print('   🧊 DI Reset complete.');
}

/// Clears the Flutter image cache and live image references.
///
/// This ensures that any cached decoded images (e.g., PNG assets, network
/// images) are evicted, forcing a full decode on next paint — which is
/// exactly what happens on first app open.
void clearImageCache() {
  PaintingBinding.instance.imageCache.clear();
  PaintingBinding.instance.imageCache.clearLiveImages();
}

/// Resets the GetIt dependency injection container and re-configures it.
///
/// This destroys all singleton instances (Cubits, Repositories, Services)
/// and recreates them, simulating the state of a freshly launched app.
Future<void> resetDependencyInjection({
  String environment = 'dev',
}) async {
  print('      - getIt.reset()...');
  await getIt.reset();
  print('      - getIt.reset() done. Re-configuring for $environment...');
  await configureDependencies(environment);
}
