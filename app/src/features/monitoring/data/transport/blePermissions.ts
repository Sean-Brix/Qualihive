import { PermissionsAndroid, Platform } from 'react-native';

/**
 * Runtime permissions BLE scanning needs.
 *
 * Android 12 (API 31) split Bluetooth into `BLUETOOTH_SCAN` / `CONNECT`;
 * below that, scanning counts as a location request. iOS handles this through
 * the Info.plist usage string and needs nothing here.
 */
export async function ensureBlePermissions(): Promise<boolean> {
  if (Platform.OS !== 'android') return true;

  const apiLevel = typeof Platform.Version === 'number' ? Platform.Version : 0;

  if (apiLevel >= 31) {
    const statuses = await PermissionsAndroid.requestMultiple([
      PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN,
      PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT,
    ]);
    const granted = PermissionsAndroid.RESULTS.GRANTED;
    return (
      statuses[PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN] === granted &&
      statuses[PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT] === granted
    );
  }

  // Android 11 and below: scanning is gated on location.
  const location = await PermissionsAndroid.request(
    PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
  );
  return location === PermissionsAndroid.RESULTS.GRANTED;
}
