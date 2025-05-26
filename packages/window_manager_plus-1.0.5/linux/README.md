# Linux Implementation for window_manager_plus

This directory contains the Linux implementation for the window_manager_plus plugin.

## Files

- `CMakeLists.txt`: Build configuration for the Linux implementation
- `window_manager_plus.h` and `window_manager_plus.cc`: Core implementation of the WindowManagerPlus class
- `window_manager_plus_plugin.cc`: Plugin registration and method handling
- `include/window_manager/window_manager_plugin.h` and `window_manager_plus_plugin.h`: Header files for the plugin

## Integration Notes

When integrating with a Flutter project:

1. Make sure the plugin is properly registered in your Flutter app's `linux/flutter/generated_plugin_registrant.cc` file
2. The plugin uses GTK3 for Linux window management
3. For advanced window properties like transparency, you may need additional X11 dependencies

## Troubleshooting

- If you encounter build errors, make sure all GTK3 development packages are installed:
  ```
  sudo apt-get install libgtk-3-dev
  ```
- For X11-specific features, additional dependencies might be required:
  ```
  sudo apt-get install libx11-dev libxext-dev
  ```
- If the plugin doesn't register correctly, check the plugin registration name in `generated_plugin_registrant.cc`

## Features on Linux

Some features have platform-specific behaviors on Linux:
- Window transparency requires a compositing window manager
- Frameless windows may still show window decorations on some window managers
- Title bar styling is limited compared to macOS and Windows

## Testing

To test this implementation:
1. Run a Flutter app with the window_manager_plus plugin on a Linux system
2. Test basic window operations (resize, move, minimize, maximize)
3. Test advanced features (transparency, frameless mode)
