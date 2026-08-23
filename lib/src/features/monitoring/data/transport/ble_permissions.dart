import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Runtime permissions BLE scanning needs.
///
/// Android 12 (API 31) split Bluetooth into `BLUETOOTH_SCAN` / `CONNECT`;
/// below that, scanning counts as a location request. iOS handles this through
/// the Info.plist usage string and needs nothing here.
abstract final class BlePermissions {
  static Future<bool> ensureGranted() async {
    if (!Platform.isAndroid) return true;

    final statuses = await <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    // locationWhenInUse is only required on Android 11 and below; treat it as
    // optional so newer devices are not blocked by a denial they never saw.
    final scan = statuses[Permission.bluetoothScan];
    final connect = statuses[Permission.bluetoothConnect];

    final scanOk = scan == null || scan.isGranted;
    final connectOk = connect == null || connect.isGranted;

    if (scanOk && connectOk) return true;

    final location = statuses[Permission.locationWhenInUse];
    return location != null && location.isGranted;
  }
}
