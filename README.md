# CleanMac

A native macOS app for completely uninstalling applications and cleaning system junk.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

### Complete App Uninstaller
- Lists all installed applications from `/Applications` and `~/Applications`
- Finds and removes related files (preferences, caches, containers, logs, etc.)
- Shows app sizes and total cleanup potential
- Detects running apps before uninstall

### System Junk Cleaner
- Scans for system junk: Xcode DerivedData, user caches, logs, browser caches, Homebrew cache
- Select/deselect individual items or entire categories
- Safe deletion to Trash

### Modern UI
- Native SwiftUI with translucent sidebar
- Smooth animations and loading states
- Dark/Light mode support

## Requirements

- macOS 13.0 or later
- Xcode 15.0+ (for building)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/fiston-user/CleanMac.git
   cd CleanMac
   ```

2. Open in Xcode:
   ```bash
   open CleanMac.xcodeproj
   ```

3. Build and run (⌘R)

### Permissions

For complete cleanup, CleanMac may request:
- **Full Disk Access**: Required to delete protected container files
  - System Settings → Privacy & Security → Full Disk Access → Add CleanMac

## Usage

1. **Uninstall Apps**: Select an app from the sidebar, review related files, and click "Uninstall"
2. **Clean System Junk**: Switch to "System Junk" tab, click "Scan", review findings, and click "Clean"

## License

MIT License - see [LICENSE](LICENSE) for details.
