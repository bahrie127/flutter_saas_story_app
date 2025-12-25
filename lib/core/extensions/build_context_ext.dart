import 'package:flutter/material.dart';

extension BuildContextExt on BuildContext {
  // Navigation
  Future<T?> push<T>(Widget widget, [String? name]) async {
    return Navigator.push<T>(
      this,
      MaterialPageRoute(
        builder: (_) => widget,
        settings: RouteSettings(name: name),
      ),
    );
  }

  Future<T?> pushReplacement<T>(Widget widget, [String? name]) async {
    return Navigator.pushReplacement<T, dynamic>(
      this,
      MaterialPageRoute(
        builder: (_) => widget,
        settings: RouteSettings(name: name),
      ),
    );
  }

  Future<T?> pushAndRemoveUntil<T>(
    Widget widget,
    bool Function(Route<dynamic>) predicate,
  ) async {
    return Navigator.pushAndRemoveUntil<T>(
      this,
      MaterialPageRoute(builder: (_) => widget),
      predicate,
    );
  }

  void pop<T>([T? result]) => Navigator.pop<T>(this, result);

  // Device Size
  double get deviceHeight => MediaQuery.of(this).size.height;
  double get deviceWidth => MediaQuery.of(this).size.width;

  // SnackBar
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  void showSuccess(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }

  void showError(String message) {
    showSnackBar(message, backgroundColor: Colors.red);
  }
}
