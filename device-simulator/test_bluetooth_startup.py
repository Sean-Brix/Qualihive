import queue
import unittest
from concurrent.futures import Future
from types import SimpleNamespace
from unittest.mock import AsyncMock, Mock, patch

from qualihive_device import App, BlePeripheral, BluetoothError


class BluetoothStartupTests(unittest.IsolatedAsyncioTestCase):
    def peripheral(self):
        # No worker thread or GUI needed to exercise adapter discovery.
        ble = BlePeripheral.__new__(BlePeripheral)
        ble.events = queue.Queue()
        ble.provider = None
        ble.tx = None
        return ble

    async def test_dongle_appearing_after_startup_still_advertises(self):
        ble = self.peripheral()
        tx = Mock()
        provider = Mock()
        provider.service.create_characteristic_async = AsyncMock(return_value=SimpleNamespace(
            error=BluetoothError.SUCCESS, characteristic=tx,
        ))
        adapter = SimpleNamespace(is_peripheral_role_supported=True)
        with (
            patch('qualihive_device.BluetoothAdapter') as adapter_class,
            patch('qualihive_device.GattServiceProvider') as provider_class,
            patch('qualihive_device.asyncio.sleep', new_callable=AsyncMock) as sleep,
        ):
            adapter_class.get_default_async = AsyncMock(side_effect=[None, None, adapter])
            provider_class.create_async = AsyncMock(return_value=SimpleNamespace(
                error=BluetoothError.SUCCESS, service_provider=provider,
            ))
            await ble.start()
        self.assertEqual(adapter_class.get_default_async.await_count, 3)
        self.assertEqual(sleep.await_count, 2)
        provider.start_advertising_with_parameters.assert_called_once()
        self.assertIs(ble.tx, tx)

    async def test_missing_adapter_finishes_with_recovery_instructions(self):
        ble = self.peripheral()
        with (
            patch('qualihive_device.BluetoothAdapter') as adapter_class,
            patch('qualihive_device.asyncio.sleep', new_callable=AsyncMock),
        ):
            adapter_class.get_default_async = AsyncMock(return_value=None)
            await ble.start()
        self.assertEqual(adapter_class.get_default_async.await_count, 5)
        messages = []
        while not ble.events.empty():
            messages.append(ble.events.get_nowait())
        self.assertIn('Retry Bluetooth', messages[-1][1])
        self.assertIsNone(ble.provider)

    async def test_retry_stops_old_advertising_and_clears_old_characteristic(self):
        ble = self.peripheral()
        previous = ble.provider = Mock()
        ble.tx = Mock()
        with patch('qualihive_device.BluetoothAdapter') as adapter_class:
            adapter_class.get_default_async = AsyncMock(return_value=SimpleNamespace(
                is_peripheral_role_supported=False,
            ))
            await ble.start()
        previous.stop_advertising.assert_called_once()
        self.assertIsNone(ble.tx)
        self.assertIsNone(ble.provider)


class StartupErrorTests(unittest.TestCase):
    def test_background_startup_exception_is_reported_to_the_ui(self):
        app = App.__new__(App)
        app.starting_bluetooth = False
        app.retry_bluetooth = Mock()
        app.ble_status = Mock()
        app.clients = Mock()
        app.events = queue.Queue()
        app.ble = Mock()
        result = Future()
        result.set_exception(RuntimeError('Radio unavailable'))
        app.ble.run.return_value = result
        app._start_bluetooth()
        self.assertIn('Radio unavailable', app.events.get_nowait()[1])
        self.assertEqual(app.events.get_nowait()[0], 'bluetooth_start_finished')


if __name__ == '__main__':
    unittest.main()
