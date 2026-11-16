import { BleManager, State, type Device, type Subscription } from 'react-native-ble-plx';

import { ensureBlePermissions } from '@/features/monitoring/data/transport/blePermissions';
import {
  BleSensorTransport,
  NORDIC_UART_SERVICE,
  NORDIC_UART_TX_CHARACTERISTIC,
} from '@/features/monitoring/data/transport/bleSensorTransport';

jest.mock('react-native-ble-plx', () => ({
  BleManager: jest.fn(),
  State: {
    Unknown: 'Unknown', Resetting: 'Resetting', Unsupported: 'Unsupported',
    Unauthorized: 'Unauthorized', PoweredOff: 'PoweredOff', PoweredOn: 'PoweredOn',
  },
}));
jest.mock('@/features/monitoring/data/transport/blePermissions', () => ({
  ensureBlePermissions: jest.fn(),
}));

const descriptor = { id: 'test-machine', name: 'Qualihive', rssi: -50 };
const permissions = jest.mocked(ensureBlePermissions);

function setup(initialState = State.PoweredOn) {
  let state = initialState;
  const listeners = new Set<(state: State) => void>();
  const characteristic = {
    uuid: NORDIC_UART_TX_CHARACTERISTIC, serviceUUID: NORDIC_UART_SERVICE,
    isNotifiable: true, isIndicatable: false,
    isWritableWithResponse: false, isWritableWithoutResponse: false,
  };
  const device = {
    id: descriptor.id, mtu: 23,
    discoverAllServicesAndCharacteristics: jest.fn().mockResolvedValue(undefined),
    services: jest.fn().mockResolvedValue([{
      uuid: NORDIC_UART_SERVICE,
      characteristics: jest.fn().mockResolvedValue([characteristic]),
    }]),
  };
  const manager = {
    state: jest.fn(async () => state),
    onStateChange: jest.fn((listener: (state: State) => void, emitCurrent: boolean): Subscription => {
      listeners.add(listener);
      if (emitCurrent) listener(state);
      return { remove: () => { listeners.delete(listener); } };
    }),
    startDeviceScan: jest.fn().mockResolvedValue(undefined),
    stopDeviceScan: jest.fn().mockResolvedValue(undefined),
    connectToDevice: jest.fn().mockResolvedValue(device),
    cancelDeviceConnection: jest.fn().mockResolvedValue(undefined),
    onDeviceDisconnected: jest.fn().mockReturnValue({ remove: jest.fn() }),
    monitorCharacteristicForDevice: jest.fn().mockReturnValue({ remove: jest.fn() }),
    destroy: jest.fn().mockResolvedValue(undefined),
  };
  const transport = new BleSensorTransport({ manager: manager as unknown as BleManager });
  return {
    transport, manager, device,
    changeState(next: State) {
      state = next;
      for (const listener of [...listeners]) listener(next);
    },
  };
}

beforeEach(() => {
  jest.useFakeTimers();
  permissions.mockReset().mockResolvedValue(true);
});
afterEach(() => { jest.useRealTimers(); });

test('checks the adapter after permission is granted, so a first scan starts immediately', async () => {
  const { transport, manager, changeState } = setup(State.Unauthorized);
  permissions.mockImplementationOnce(async () => { changeState(State.PoweredOn); return true; });
  const scan = transport.startScan();
  await jest.advanceTimersByTimeAsync(0);
  expect(manager.startDeviceScan).toHaveBeenCalledTimes(1);
  expect(transport.status.state).toBe('scanning');
  await transport.stopScan();
  await scan;
  await transport.dispose();
});

test('waits for the adapter to finish initializing', async () => {
  const { transport, manager, changeState } = setup(State.Unknown);
  const scan = transport.startScan();
  await jest.advanceTimersByTimeAsync(0);
  expect(manager.startDeviceScan).not.toHaveBeenCalled();
  changeState(State.PoweredOn);
  await jest.advanceTimersByTimeAsync(0);
  expect(manager.startDeviceScan).toHaveBeenCalledTimes(1);
  await transport.stopScan();
  await scan;
  await transport.dispose();
});

test('an adapter that never initializes reports a bounded failure', async () => {
  const { transport, manager } = setup(State.Unknown);
  const scan = transport.startScan();
  await jest.advanceTimersByTimeAsync(5_000);
  await scan;
  expect(manager.startDeviceScan).not.toHaveBeenCalled();
  expect(transport.status.message).toContain('still starting');
  await transport.dispose();
});

test('a denied permission never starts the native scan', async () => {
  const { transport, manager } = setup();
  permissions.mockResolvedValueOnce(false);
  await transport.startScan();
  expect(manager.startDeviceScan).not.toHaveBeenCalled();
  expect(transport.status.message).toContain('permission denied');
  await transport.dispose();
});

test('a rejected scan startup reports the error and releases the scan', async () => {
  const { transport, manager } = setup();
  manager.startDeviceScan.mockRejectedValueOnce(new Error('Location services disabled'));
  await transport.startScan();
  expect(transport.status).toMatchObject({ state: 'error', message: 'Location services disabled' });
  expect(manager.stopDeviceScan).toHaveBeenCalledTimes(1);
  await transport.dispose();
});

test('devices are discovered and selecting one stops scanning before connecting', async () => {
  const { transport, manager } = setup();
  const scan = transport.startScan();
  await jest.advanceTimersByTimeAsync(0);
  const callback = manager.startDeviceScan.mock.calls[0][2];
  callback(null, { ...descriptor, localName: null });
  expect(transport.discovered).toEqual([descriptor]);
  await transport.connect(descriptor);
  await scan;
  expect(manager.stopDeviceScan.mock.invocationCallOrder[0]).toBeLessThan(
    manager.connectToDevice.mock.invocationCallOrder[0],
  );
  expect(transport.status.state).toBe('connected');
  await transport.dispose();
});

test('service discovery failure closes the partially established connection', async () => {
  const { transport, manager, device } = setup();
  device.discoverAllServicesAndCharacteristics.mockRejectedValueOnce(new Error('Discovery failed'));
  await transport.connect(descriptor);
  expect(manager.cancelDeviceConnection).toHaveBeenCalledWith(descriptor.id);
  expect(transport.status.state).toBe('error');
  expect(transport.status.message).toContain('Discovering the sensor service: Discovery failed');
  await transport.dispose();
});

test('a disconnect during discovery cannot later report a connected machine', async () => {
  const { transport, device } = setup();
  let finish!: () => void;
  device.discoverAllServicesAndCharacteristics.mockReturnValueOnce(new Promise<void>((resolve) => { finish = resolve; }));
  const connecting = transport.connect(descriptor);
  await jest.advanceTimersByTimeAsync(0);
  await transport.disconnect();
  finish();
  await connecting;
  expect(transport.status.state).toBe('disconnected');
  await transport.dispose();
});

test('canceling while the radio connects closes the late connection', async () => {
  const { transport, manager, device } = setup();
  let finish!: (value: Device) => void;
  manager.connectToDevice.mockReturnValueOnce(new Promise<Device>((resolve) => { finish = resolve; }));
  const connecting = transport.connect(descriptor);
  await jest.advanceTimersByTimeAsync(0);
  await transport.disconnect();
  finish(device as unknown as Device);
  await connecting;
  expect(manager.cancelDeviceConnection).toHaveBeenCalledWith(descriptor.id);
  expect(transport.status.state).toBe('disconnected');
  await transport.dispose();
});

test('repeated connect taps share one native connection instead of canceling each other', async () => {
  const { transport, manager } = setup();
  const first = transport.connect(descriptor);
  const second = transport.connect(descriptor);
  expect(second).toBe(first);
  await Promise.all([first, second]);
  expect(manager.connectToDevice).toHaveBeenCalledTimes(1);
  expect(manager.connectToDevice).toHaveBeenCalledWith(descriptor.id, { timeout: 30_000 });
  expect(transport.status.state).toBe('connected');
  await transport.dispose();
});

test('connection errors retain the setup phase and native failure details', async () => {
  const { transport, manager } = setup();
  const error = Object.assign(new Error('Operation was cancelled'), {
    errorCode: 2, androidErrorCode: 133, reason: 'GATT setup failed',
  });
  const warning = jest.spyOn(console, 'warn').mockImplementation(() => undefined);
  manager.connectToDevice.mockRejectedValueOnce(error);
  await transport.connect(descriptor);
  expect(transport.status.state).toBe('error');
  expect(transport.status.message).toContain('Connecting to the device: Operation was cancelled');
  expect(transport.status.message).toContain('BLE 2, Android 133');
  expect(transport.status.message).toContain('GATT setup failed');
  warning.mockRestore();
  await transport.dispose();
});
