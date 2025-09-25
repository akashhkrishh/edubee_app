import 'package:flutter/material.dart';

class AppConstants {
  static const Map<String, Color> categoryColors = {
    'transport': Colors.blue,
    'signs': Colors.orange,
    'safety': Colors.red,
    'fruits': Colors.green,
    'house': Colors.purple,
    'clothing': Colors.teal,
  };

  static const Map<String, IconData> categoryIcons = {
    'transport': Icons.directions_car,
    'signs': Icons.traffic,
    'safety': Icons.security,
    'fruits': Icons.apple,
    'house': Icons.home,
    'clothing': Icons.checkroom,
  };

  static const int usbVendorId = 1234;
  static const int usbProductId = 5678;
}