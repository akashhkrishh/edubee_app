import 'package:flutter/foundation.dart';

class ErrorService {
  static String handleError(Object error, StackTrace stackTrace) {
    debugPrint('Error: $error\nStackTrace: $stackTrace');
    return 'An unexpected error occurred. Please try again.';
  }
}