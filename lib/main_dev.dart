import 'package:boklo/core/config/app_bootstrap.dart';
import 'package:boklo/firebase_options_dev.dart';
import 'package:injectable/injectable.dart';

void main() async {
  await AppBootstrap.bootstrap(
    environment: Environment.dev,
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    useFirebaseEmulator: true,
  );
}
