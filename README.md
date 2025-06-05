# Scaler iOS App

A SwiftUI-based iOS app that tracks device pitch angle and implements a shake-based interaction system.

## Features

### 1. Pitch Gate System
- Monitors device pitch using CoreMotion at 30 Hz
- Defines "level" threshold: -10° to +10° (adjustable)
- Shows overlay when device is not level

### 2. Usage Timer
- Tracks time when device is held level and app is in foreground
- Triggers shake sprint after 30 minutes of accumulated usage
- Displays progress and remaining time

### 3. Shake Sprint
- Activated after 30 minutes of usage time
- Requires ≥3 shakes per second for 60 seconds
- Shows circular progress indicator
- Real-time shake rate monitoring

### 4. Adaptive UI
- Normal UI: "Hello, Scaler!" with usage statistics
- Gate closed: Black overlay with leveling instructions
- Sprint active: Circular progress with shake requirements

## Architecture

### Models
- **PitchGateModel**: CoreMotion integration and threshold detection
- **ShakeSprintController**: Shake detection and sprint progress management  
- **UsageTimer**: Time tracking and sprint triggering

### Views
- **ContentView**: Main UI with state-based overlays
- **ScalerApp**: App entry point with environment objects

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Device with accelerometer/gyroscope (shake detection requires physical device)

## Building & Running

1. Open project in Xcode
2. Select target device (simulator for basic functionality, physical device for shake detection)
3. Build and run (⌘+R)

## Testing

The project includes comprehensive unit tests:

```bash
# Run tests in Xcode
⌘+U

# Or via command line
xcodebuild test -scheme Scaler -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Test Coverage
- **PitchGateModelTests**: Mock pitch values and threshold testing
- **ShakeSprintControllerTests**: Shake simulation and progress validation
- **UsageTimerTests**: Timer functionality and sprint triggering

## Usage

1. **Launch**: App starts with pitch monitoring active
2. **Level Device**: Hold phone level (within ±10°) to start usage timer
3. **Accumulate Time**: Keep device level for 30 minutes total
4. **Shake Sprint**: After 30 minutes, shake device ≥3 times/second for 60 seconds
5. **Complete**: Sprint progress reaches 100%

## Debug Information

The app displays real-time debug info:
- Current pitch angle
- Gate status (OPEN/CLOSED)
- Timer status (ACTIVE/INACTIVE)
- Shake rate (during sprint)

## Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **CoreMotion**: Device motion and orientation sensing
- **Combine**: Reactive programming for state management
- **XCTest**: Unit testing framework with async expectations

## Notes

- Motion permissions are automatically requested
- App must be in foreground for usage timer to run
- Shake detection requires physical device (won't work in simulator)
- Timer pauses when app enters background 