import 'package:usb_serial/usb_serial.dart';

class AppConfig {
  static const int usbBaudRate = 9600;
  static const int usbDataBits = UsbPort.DATABITS_8;
  static const int usbStopBits = UsbPort.STOPBITS_1;
  static const int usbParity = UsbPort.PARITY_NONE;
  static const String usbMessagePrefix = "edu";
  static const int usbVendorId = 1234;
  static const int usbProductId = 5678;
}