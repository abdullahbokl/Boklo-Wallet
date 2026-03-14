import 'package:flutter_test/flutter_test.dart';

import '../core/page_test_config.dart';
import '../core/perf_test_binding.dart';
import '../page_perf_template.dart';

/// Performance benchmark for the **Login Page**.
///
/// Run standalone:
/// ```bash
/// flutter drive \
///   --driver=test_driver/perf_driver.dart \
///   --target=integration_test/performance/pages/login_page_perf_test.dart \
///   --profile
/// ```
void main() {
  final binding = initPerfBinding();

  const config = PageTestConfig(
    pageName: 'LoginPage',
    routePath: '/login',
    hasScrollableContent: false,
    scrollIterations: 0,
  );

  testWidgets('LoginPage performance benchmark', (tester) async {
    final result = await runPagePerfTest(tester, binding, config);

    // Report results so the driver can save them.
    binding.reportData = <String, dynamic>{
      'pages': {config.pageName: result.toJson()},
    };
  });
}
