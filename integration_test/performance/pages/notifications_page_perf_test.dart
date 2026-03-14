import 'package:flutter_test/flutter_test.dart';

import '../core/page_test_config.dart';
import '../core/perf_test_binding.dart';
import '../page_perf_template.dart';

/// Performance benchmark for the **Notifications Page**.
void main() {
  final binding = initPerfBinding();

  const config = PageTestConfig(
    pageName: 'NotificationsPage',
    routePath: '/notifications',
    hasScrollableContent: true,
    scrollIterations: 5,
  );

  testWidgets('NotificationsPage performance benchmark', (tester) async {
    final result = await runPagePerfTest(tester, binding, config);
    binding.reportData = <String, dynamic>{
      'pages': {config.pageName: result.toJson()},
    };
  });
}
