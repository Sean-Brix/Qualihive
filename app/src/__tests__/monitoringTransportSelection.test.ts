import { useMonitoringStore } from '@/features/monitoring/application/monitoringStore';
import { BleSensorTransport } from '@/features/monitoring/data/transport/bleSensorTransport';
import { DISCONNECTED, type SensorTransport } from '@/features/monitoring/data/transport/sensorTransport';
import { SimulatedSensorTransport } from '@/features/monitoring/data/transport/simulatedSensorTransport';

jest.mock('@/features/monitoring/data/transport/bleSensorTransport', () => ({
  BleSensorTransport: jest.fn(),
}));
jest.mock('@/features/monitoring/data/transport/simulatedSensorTransport', () => ({
  SimulatedSensorTransport: jest.fn(),
}));
jest.mock('@/features/settings/application/pumpTimerStore', () => ({ readPumpTimers: jest.fn() }));
jest.mock('@/features/settings/application/standardStore', () => ({ readActiveStandard: jest.fn() }));
jest.mock('@/features/monitoring/application/services', () => ({
  batchSession: { restore: jest.fn().mockResolvedValue(undefined) },
  alertRepository: {}, batchRepository: {}, readingRepository: {}, sampleDataSeeder: {},
}));

function transport(): SensorTransport {
  return {
    status: DISCONNECTED, discovered: [],
    onStatus: jest.fn(() => jest.fn()),
    onReading: jest.fn(() => jest.fn()),
    onDiscovered: jest.fn(() => jest.fn()),
    startScan: jest.fn(), stopScan: jest.fn(), connect: jest.fn(), disconnect: jest.fn(),
    send: jest.fn(), dispose: jest.fn().mockResolvedValue(undefined),
  };
}

test('switching back to Bluetooth waits for the previous manager to finish destroying', async () => {
  jest.useFakeTimers();
  const firstBle = transport();
  const simulator = transport();
  const secondBle = transport();
  let finishDisposal!: () => void;
  jest.mocked(firstBle.dispose).mockReturnValueOnce(new Promise<void>((resolve) => { finishDisposal = resolve; }));
  jest.mocked(BleSensorTransport)
    .mockImplementationOnce(() => firstBle as BleSensorTransport)
    .mockImplementationOnce(() => secondBle as BleSensorTransport);
  jest.mocked(SimulatedSensorTransport).mockImplementationOnce(() => simulator as SimulatedSensorTransport);

  expect(useMonitoringStore.getState().ensureTransport()).toBe(firstBle);
  const toSimulator = useMonitoringStore.getState().selectTransport('simulator');
  const backToBle = useMonitoringStore.getState().selectTransport('ble');
  await jest.advanceTimersByTimeAsync(0);

  expect(useMonitoringStore.getState().switchingTransport).toBe(true);
  expect(SimulatedSensorTransport).not.toHaveBeenCalled();
  expect(BleSensorTransport).toHaveBeenCalledTimes(1);
  expect(() => useMonitoringStore.getState().ensureTransport()).toThrow('finish switching');

  finishDisposal();
  await Promise.all([toSimulator, backToBle]);
  expect(simulator.dispose).toHaveBeenCalledTimes(1);
  expect(BleSensorTransport).toHaveBeenCalledTimes(2);
  expect(useMonitoringStore.getState()).toMatchObject({
    transportKind: 'ble', transport: secondBle, switchingTransport: false, error: null,
  });
  jest.useRealTimers();
});
