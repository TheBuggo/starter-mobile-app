import 'package:riverpod/riverpod.dart';

import 'app_controller.dart';

final Provider<AppController> appControllerProvider =
    Provider<AppController>((ref) {
  throw StateError('appControllerProvider must be overridden before use.');
});
