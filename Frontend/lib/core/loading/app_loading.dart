import 'package:flutter/foundation.dart';

class AppLoadingController extends ChangeNotifier {
  int _count = 0;
  String? _message;

  bool get isLoading => _count > 0;
  String? get message => _message;

  void show([String? message]) {
    _count += 1;
    if (message != null && message.trim().isNotEmpty) {
      _message = message;
    }
    notifyListeners();
  }

  void hide() {
    if (_count == 0) return;
    _count -= 1;
    if (_count == 0) {
      _message = null;
    }
    notifyListeners();
  }

  Future<T> wrap<T>(Future<T> Function() action, {String? message}) async {
    show(message);
    try {
      return await action();
    } finally {
      hide();
    }
  }
}

class AppLoading {
  static final AppLoadingController controller = AppLoadingController();

  static void show([String? message]) => controller.show(message);

  static void hide() => controller.hide();

  static Future<T> wrap<T>(Future<T> Function() action, {String? message}) =>
      controller.wrap(action, message: message);
}
