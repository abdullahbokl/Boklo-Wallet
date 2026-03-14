import 'package:integration_test/integration_test.dart';

/// Initializes and returns the [IntegrationTestWidgetsFlutterBinding].
///
/// Must be called once at the top of the test `main()`.
/// Returns the binding so callers can use `traceAction()` and `reportData()`.
IntegrationTestWidgetsFlutterBinding initPerfBinding() {
  return IntegrationTestWidgetsFlutterBinding.ensureInitialized();
}
