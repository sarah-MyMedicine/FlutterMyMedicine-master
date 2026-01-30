#!/bin/bash
# Quick debug script for Flutter app

echo "Checking for emulator..."
flutter devices

echo -e "\nLaunching emulator if not running..."
flutter emulators --launch Medium_Phone_API_36.1 &

echo "Waiting for emulator to boot..."
sleep 30

echo -e "\nRunning app..."
flutter run -d emulator-5554
