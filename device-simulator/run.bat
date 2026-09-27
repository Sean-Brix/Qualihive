@echo off
rem Double-click to start the Qualihive device simulator.
rem The first run creates a private Python environment next to this file.
cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
  echo Setting up for the first run...
  python -m venv .venv || goto :nopython
  ".venv\Scripts\python.exe" -m pip install --quiet --disable-pip-version-check -r requirements.txt || goto :failed
)

".venv\Scripts\python.exe" qualihive_device.py
if errorlevel 1 pause
exit /b

:nopython
echo Python was not found. Install it from https://www.python.org and tick "Add to PATH".
pause
exit /b 1

:failed
echo Installing the Bluetooth packages failed. See the error above.
pause
exit /b 1
