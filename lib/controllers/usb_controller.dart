import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:edubee_app/config/app_config.dart';
import 'package:usb_serial/usb_serial.dart';

class UsbController with ChangeNotifier {
  UsbPort? _port;
  StreamSubscription? _subscription;
  final StreamController<int> _answerController = StreamController<int>.broadcast();

  Stream<int> get answerStream => _answerController.stream;

  @override
  void dispose() {
    _subscription?.cancel();
    _port?.close();
    _answerController.close();
    super.dispose();
  }

  Future<void> initUsb() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (devices.isEmpty) {
      if (kDebugMode) print("No USB devices found");
      return;
    }

    UsbDevice device = devices.first;
    _port = await device.create();

    bool openResult = await _port!.open();
    if (!openResult) {
      if (kDebugMode) print("Failed to open port");
      return;
    }

    await _port!.setDTR(true);
    await _port!.setRTS(true);

    _port!.setPortParameters(
      AppConfig.usbBaudRate,
      AppConfig.usbDataBits,
      AppConfig.usbStopBits,
      AppConfig.usbParity,
    );

    _subscription = _port!.inputStream?.listen((data) {
      final message = String.fromCharCodes(data).trim();
      if (kDebugMode) print("Received from USB: $message");

      if (message.startsWith(AppConfig.usbMessagePrefix)) {
        final number = int.tryParse(message.replaceFirst(AppConfig.usbMessagePrefix, ""));
        if (number != null && (number == 1 || number == 2)) {
          _answerController.add(number - 1);
        }
      }
    }, onError: (e) {
      if (kDebugMode) print("USB stream error: $e");
    });
  }
}
