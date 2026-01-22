# CleanMac

A beautiful native macOS app for completely uninstalling applications and cleaning system junk.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

### 🗑️ Complete App Uninstaller
- Lists all installed applications from `/Applications` and `~/Applications`
- Finds and removes related files:
  - Preferences (plist files)
  - Caches
  - Application Support data
  - Containers
  - Logs
  - Saved Application State
  - Cookies
- Shows app sizes and total cleanup potential
- Detects running apps before uninstall

### 🧹 System Junk Cleaner
- Scans for system junk across multiple categories:
  - Xcode DerivedData, Archives, and Device Support
  - User Caches
  - System Logs
  - Browser caches (Safari, Chrome)
  - Homebrew cache
- Select/deselect individual items or entire categories
- Safe deletion to Trash

### ✨ Modern UI
- Native SwiftUI with translucent sidebar
- Smooth animations and loading states
- Dark/Light mode support
- Keyboard shortcuts

## Screenshots

*Coming soon*

## Requirements

- macOS 13.0 or later
- Xcode 15.0+ (for building)

## Installation

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/USERNAME/CleanMac.git
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

## Project Structure

```
CleanMac/
├── CleanMacApp.swift           # App entry point
├── Models/
│   ├── InstalledApp.swift      # App and related file models
│   └── SystemJunk.swift        # Junk category models
├── Services/
│   ├── AppManager.swift        # App scanning and deletion logic
│   └── JunkCleaner.swift       # System junk scanning and cleaning
└── Views/
    ├── ContentView.swift       # Main layout with tab switching
    ├── AppListView.swift       # Sidebar app list
    ├── AppDetailView.swift     # App details and file list
    ├── SystemJunkView.swift    # Junk cleaner interface
    └── Components/
        ├── LoadingView.swift   # Loading animations
        └── FullDiskAccessView.swift  # Permission prompts
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
