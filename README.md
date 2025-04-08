# Shift Studios - Refactored

This is a refactored version of the Shift Studios iOS app. The codebase has been reorganized to improve maintainability and reduce redundancy.

## Project Structure

The project has been reorganized into a feature-based architecture:

- **Core**: Essential components used throughout the app
  - AppDelegate: App lifecycle management
  - Models: Data models
  - Services: Core services like AppBlockingService
  - Utils: Utility classes and constants

- **Features**: Organized by feature rather than technical type
  - FocusMode: Focus mode functionality
  - Stats: Usage statistics tracking and display
  - Settings: App configuration

- **Resources**: Static resources
  - Assets: Images and colors
  - Localization: Localized strings

- **Support**: Supporting components
  - Extensions: UI extensions
  - NFC: NFC tag functionality

## Changes Made

1. Removed redundant view components that weren't being used
2. Reorganized files by feature rather than technical type
3. Simplified the folder structure for better maintainability
4. Eliminated duplicate functionality
5. Maintained all core functionality and UI

The refactored codebase has 36 files compared to 50 in the original, a 28% reduction in file count.
