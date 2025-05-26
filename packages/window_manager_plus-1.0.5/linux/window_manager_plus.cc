#include "window_manager_plus.h"

#include <gdk/gdk.h>
#include <gdk/gdkx.h>
#include <gtk/gtk.h>

#include <algorithm>
#include <cstring>
#include <iostream>
#include <map>
#include <memory>
#include <string>
#include <vector>

// Implementation Note:
// This Linux implementation of window_manager_plus leverages GTK3 for window management.
// Some advanced features (like window shadows, certain transparency effects, etc.) 
// are dependent on the window manager being used and may not work consistently
// across all Linux distributions and desktop environments.

namespace window_manager_plus {

std::map<int, std::shared_ptr<WindowManagerPlus>> WindowManagerPlus::windowManagers_;
std::map<int, GtkWindow*> WindowManagerPlus::windows_;

WindowManagerPlus::WindowManagerPlus() : id(-1) {}

WindowManagerPlus::~WindowManagerPlus() {}

// Gets the GtkWindow widget for this instance's ID, or the default window if ID is -1
GtkWindow* GetWindow(int windowId) {
  if (windowId >= 0 && WindowManagerPlus::windows_.find(windowId) != WindowManagerPlus::windows_.end()) {
    return WindowManagerPlus::windows_[windowId];
  }
  return nullptr;
}

// Creates a new window and returns its ID
int WindowManagerPlus::createWindow(const std::vector<std::string>& arguments) {
  std::string app_id = "org.window_manager_plus.window";
  std::string title = "Flutter Window";
  int width = 800;
  int height = 600;
  
  // Parse arguments if available
  for (const auto& arg : arguments) {
    if (arg.find("--app-id=") == 0) {
      app_id = arg.substr(9);
    } else if (arg.find("--title=") == 0) {
      title = arg.substr(8);
    } else if (arg.find("--width=") == 0) {
      width = std::stoi(arg.substr(8));
    } else if (arg.find("--height=") == 0) {
      height = std::stoi(arg.substr(9));
    }
  }

  // Generate a unique ID for the new window
  int newWindowId = 0;
  while (WindowManagerPlus::windowManagers_.find(newWindowId) != WindowManagerPlus::windowManagers_.end()) {
    newWindowId++;
  }

  // Note: Actual window creation would happen through the Flutter engine
  // This is just a placeholder for the ID generation
  // In a real implementation, we would launch a new Flutter window here
  
  // For now, just return the ID that would be assigned
  return newWindowId;
}

void WindowManagerPlus::WaitUntilReadyToShow() {
  // Implementation not required for Linux as the window is shown by default
}

void WindowManagerPlus::SetAsFrameless() {
  GtkWindow* window = GetWindow(id);
  if (window) {
    gtk_window_set_decorated(window, FALSE);
    is_frameless_ = true;
  }
}

void WindowManagerPlus::Destroy() {
  GtkWindow* window = GetWindow(id);
  if (window) {
    gtk_window_close(window);
  }
}

void WindowManagerPlus::Close() {
  GtkWindow* window = GetWindow(id);
  if (window) {
    gtk_window_close(window);
  }
}

bool WindowManagerPlus::IsPreventClose() {
  return is_prevent_close_;
}

void WindowManagerPlus::SetPreventClose(const FlValue* args) {
  if (args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
    FlValue* is_prevent_close = fl_value_lookup_string(args, "isPreventClose");
    if (is_prevent_close && fl_value_get_type(is_prevent_close) == FL_VALUE_TYPE_BOOL) {
      is_prevent_close_ = fl_value_get_bool(is_prevent_close);
    }
  }
}

void WindowManagerPlus::Focus() {
  GtkWindow* window = GetWindow(id);
  if (window) {
    gtk_window_present(window);
  }
}

void WindowManagerPlus::Blur() {
  // GTK does not provide a direct way to blur a window
  // We could potentially use gdk_window_lower but this affects window stacking
}

bool WindowManagerPlus::IsFocused() {
  GtkWindow* window = GetWindow(id);
  if (window) {
    return gtk_window_is_active(window);
  }
  return false;
}

void WindowManagerPlus::Show() {
  GtkWindow* window = GetWindow(id);
  if (window) {
    gtk_widget_show(GTK_WIDGET(window));
  }
}

void WindowManagerPlus::Hide() {
  GtkWindow* window = GetWindow(id);
  if (window) {
    gtk_widget_hide(GTK_WIDGET(window));
  }
}

bool WindowManagerPlus::IsVisible() {
  GtkWindow* window = GetWindow(id);
  if (window) {
    return gtk_widget_get_visible(GTK_WIDGET(window));
  }
  return false;
}

bool WindowManagerPlus::IsMaximized() {
  GtkWindow* window = GetWindow(id);
  if (window) {
    GdkWindow* gdk_window = gtk_widget_get_window(GTK_WIDGET(window));
    if (gdk_window) {
      GdkWindowState state = gdk_window_get_state(gdk_window);
      return (state & GDK_WINDOW_STATE_MAXIMIZED) != 0;
    }
  }
  return false;
}

void WindowManagerPlus::Maximize(const FlValue* args) {
  GtkWindow* window = GetWindow(id);
  if (window) {
    gtk_window_maximize(window);
  }
}

void WindowManagerPlus::Unmaximize() {
  GtkWindow* window = GetWindow(id);
  if (window) {
    gtk_window_unmaximize(window);
  }
}

bool WindowManagerPlus::IsMinimized() {
  GtkWindow* window = GetWindow(id);
  if (window) {
    GdkWindow* gdk_window = gtk_widget_get_window(GTK_WIDGET(window));
    if (gdk_window) {
      GdkWindowState state = gdk_window_get_state(gdk_window);
      return (state & GDK_WINDOW_STATE_ICONIFIED) != 0;
    }
  }
  return false;
}

void WindowManagerPlus::Minimize() {
  GtkWindow* window = GetWindow(id);
  if (window) {
    gtk_window_iconify(window);
  }
}

void WindowManagerPlus::Restore() {
  GtkWindow* window = GetWindow(id);
  if (window) {
    gtk_window_present(window);
  }
}

bool WindowManagerPlus::IsDockable() {
  // Linux/GTK doesn't have a direct equivalent to macOS docking
  return false;
}

int WindowManagerPlus::IsDocked() {
  // Linux/GTK doesn't have a direct equivalent to macOS docking
  return 0;
}

void WindowManagerPlus::Dock(const FlValue* args) {
  // Linux/GTK doesn't have a direct equivalent to macOS docking
}

bool WindowManagerPlus::Undock() {
  // Linux/GTK doesn't have a direct equivalent to macOS docking
  return false;
}

bool WindowManagerPlus::IsFullScreen() {
  GtkWindow* window = GetWindow(id);
  if (window) {
    GdkWindow* gdk_window = gtk_widget_get_window(GTK_WIDGET(window));
    if (gdk_window) {
      GdkWindowState state = gdk_window_get_state(gdk_window);
      return (state & GDK_WINDOW_STATE_FULLSCREEN) != 0;
    }
  }
  return false;
}

void WindowManagerPlus::SetFullScreen(const FlValue* args) {
  GtkWindow* window = GetWindow(id);
  if (window) {
    bool isFullScreen = false;
    
    if (args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* is_full_screen = fl_value_lookup_string(args, "isFullScreen");
      if (is_full_screen && fl_value_get_type(is_full_screen) == FL_VALUE_TYPE_BOOL) {
        isFullScreen = fl_value_get_bool(is_full_screen);
      }
    }
    
    if (isFullScreen) {
      gtk_window_fullscreen(window);
    } else {
      gtk_window_unfullscreen(window);
    }
  }
}

void WindowManagerPlus::SetAspectRatio(const FlValue* args) {
  if (args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
    FlValue* aspect_ratio = fl_value_lookup_string(args, "aspectRatio");
    if (aspect_ratio && fl_value_get_type(aspect_ratio) == FL_VALUE_TYPE_FLOAT) {
      aspect_ratio_ = fl_value_get_float(aspect_ratio);
      
      // Set geometry hints for the aspect ratio
      GtkWindow* window = GetWindow(id);
      if (window && aspect_ratio_ > 0) {
        GdkGeometry geometry;
        geometry.min_aspect = aspect_ratio_;
        geometry.max_aspect = aspect_ratio_;
        
        gtk_window_set_geometry_hints(
            window, nullptr, &geometry, GDK_HINT_ASPECT);
      }
    }
  }
}

void WindowManagerPlus::SetBackgroundColor(const FlValue* args) {
  GtkWindow* window = GetWindow(id);
  if (window && args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
    FlValue* color = fl_value_lookup_string(args, "color");
    if (color && fl_value_get_type(color) == FL_VALUE_TYPE_INT) {
      int argb = fl_value_get_int(color);
      double alpha = ((argb >> 24) & 0xFF) / 255.0;
      double red = ((argb >> 16) & 0xFF) / 255.0;
      double green = ((argb >> 8) & 0xFF) / 255.0;
      double blue = (argb & 0xFF) / 255.0;
      
      // Apply CSS styling to set the background color
      GtkCssProvider *css_provider = gtk_css_provider_new();
      char css[256];
      snprintf(css, sizeof(css),
               "window { background-color: rgba(%d, %d, %d, %.2f); }",
               (int)(red * 255), (int)(green * 255), (int)(blue * 255), alpha);
      gtk_css_provider_load_from_data(css_provider, css, -1, nullptr);
      
      GtkStyleContext *context = gtk_widget_get_style_context(GTK_WIDGET(window));
      gtk_style_context_add_provider(
          context, GTK_STYLE_PROVIDER(css_provider),
          GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
      g_object_unref(css_provider);
    }
  }
}

FlValue* WindowManagerPlus::GetBounds(const FlValue* args) {
  GtkWindow* window = GetWindow(id);
  FlValue* result = fl_value_new_map();
  
  if (window) {
    int x, y, width, height;
    gtk_window_get_position(window, &x, &y);
    gtk_window_get_size(window, &width, &height);
    
    fl_value_set_string_take(result, "x", fl_value_new_float(x));
    fl_value_set_string_take(result, "y", fl_value_new_float(y));
    fl_value_set_string_take(result, "width", fl_value_new_float(width));
    fl_value_set_string_take(result, "height", fl_value_new_float(height));
  }
  
  return result;
}

void WindowManagerPlus::SetBounds(const FlValue* args) {
  GtkWindow* window = GetWindow(id);
  if (window && args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
    // Check if we have a devicePixelRatio to apply
    double device_pixel_ratio = 1.0;
    FlValue* pixel_ratio = fl_value_lookup_string(args, "devicePixelRatio");
    if (pixel_ratio && fl_value_get_type(pixel_ratio) == FL_VALUE_TYPE_FLOAT) {
      device_pixel_ratio = fl_value_get_float(pixel_ratio);
    }

    // Convert logical coordinates to physical
    FlValue* x = fl_value_lookup_string(args, "x");
    FlValue* y = fl_value_lookup_string(args, "y");
    FlValue* width = fl_value_lookup_string(args, "width");
    FlValue* height = fl_value_lookup_string(args, "height");
    
    if (width && height && 
        fl_value_get_type(width) == FL_VALUE_TYPE_FLOAT &&
        fl_value_get_type(height) == FL_VALUE_TYPE_FLOAT) {
      int w = (int)(fl_value_get_float(width) * device_pixel_ratio);
      int h = (int)(fl_value_get_float(height) * device_pixel_ratio);
      gtk_window_resize(window, w, h);
    }
    
    if (x && y && 
        fl_value_get_type(x) == FL_VALUE_TYPE_FLOAT &&
        fl_value_get_type(y) == FL_VALUE_TYPE_FLOAT) {
      int pos_x = (int)(fl_value_get_float(x) * device_pixel_ratio);
      int pos_y = (int)(fl_value_get_float(y) * device_pixel_ratio);
      gtk_window_move(window, pos_x, pos_y);
    }
  }
}

void WindowManagerPlus::SetMinimumSize(const FlValue* args) {
  GtkWindow* window = GetWindow(id);
  if (window && args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
    FlValue* width = fl_value_lookup_string(args, "width");
    FlValue* height = fl_value_lookup_string(args, "height");
    
    if (width && height && 
        fl_value_get_type(width) == FL_VALUE_TYPE_FLOAT &&
        fl_value_get_type(height) == FL_VALUE_TYPE_FLOAT) {
      double w = fl_value_get_float(width);
      double h = fl_value_get_float(height);
      
      minimum_size_[0] = w;
      minimum_size_[1] = h;
      
      GdkGeometry geometry;
      geometry.min_width = (int)w;
      geometry.min_height = (int)h;
      
      gtk_window_set_geometry_hints(
          window, nullptr, &geometry, GDK_HINT_MIN_SIZE);
    }
  }
}

void WindowManagerPlus::SetMaximumSize(const FlValue* args) {
  GtkWindow* window = GetWindow(id);
  if (window && args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
    FlValue* width = fl_value_lookup_string(args, "width");
    FlValue* height = fl_value_lookup_string(args, "height");
    
    if (width && height && 
        fl_value_get_type(width) == FL_VALUE_TYPE_FLOAT &&
        fl_value_get_type(height) == FL_VALUE_TYPE_FLOAT) {
      double w = fl_value_get_float(width);
      double h = fl_value_get_float(height);
      
      maximum_size_[0] = w;
      maximum_size_[1] = h;
      
      GdkGeometry geometry;
      geometry.max_width = (w < 0) ? G_MAXINT : (int)w;
      geometry.max_height = (h < 0) ? G_MAXINT : (int)h;
      
      gtk_window_set_geometry_hints(
          window, nullptr, &geometry, GDK_HINT_MAX_SIZE);
    }
  }
}

bool WindowManagerPlus::IsResizable() {
  return is_resizable_;
}

void WindowManagerPlus::SetResizable(const FlValue* args) {
  GtkWindow* window = GetWindow(id);
  if (window && args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
    FlValue* is_resizable = fl_value_lookup_string(args, "isResizable");
    if (is_resizable && fl_value_get_type(is_resizable) == FL_VALUE_TYPE_BOOL) {
      is_resizable_ = fl_value_get_bool(is_resizable);
      gtk_window_set_resizable(window, is_resizable_);
    }
  }
}

bool WindowManagerPlus::IsMinimizable() {
  // GTK doesn't have a direct way to determine if a window is minimizable
  // Most window managers allow windows to be minimized by default
  return true;
}

void WindowManagerPlus::SetMinimizable(const FlValue* args) {
  // GTK doesn't provide a direct way to disable minimization
  // This is typically controlled by the window manager
}

bool WindowManagerPlus::IsMaximizable() {
  // GTK doesn't have a direct way to determine if a window is maximizable
  // By default, windows can be maximized unless specific hints are set
  return true;
}

void WindowManagerPlus::SetMaximizable(const FlValue* args) {
  // GTK doesn't provide a direct way to disable maximization
  // This would typically need to be controlled via window manager hints
}

bool WindowManagerPlus::IsClosable() {
  // GTK doesn't have a direct way to determine if a window is closable
  // This would depend on the window manager and window decoration state
  return true;
}

void WindowManagerPlus::SetClosable(const FlValue* args) {
  // GTK doesn't provide a direct way to disable window closing
  // This would need to be handled through the delete-event signal
}

bool WindowManagerPlus::IsAlwaysOnTop() {
  return is_always_on_top_;
}

void WindowManagerPlus::SetAlwaysOnTop(const FlValue* args) {
  GtkWindow* window = GetWindow(id);
  if (window && args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
    FlValue* is_always_on_top = fl_value_lookup_string(args, "isAlwaysOnTop");
    if (is_always_on_top && fl_value_get_type(is_always_on_top) == FL_VALUE_TYPE_BOOL) {
      is_always_on_top_ = fl_value_get_bool(is_always_on_top);
      gtk_window_set_keep_above(window, is_always_on_top_);
    }
  }
}

bool WindowManagerPlus::IsAlwaysOnBottom() {
  return is_always_on_bottom_;
}

void WindowManagerPlus::SetAlwaysOnBottom(const FlValue* args) {
  GtkWindow* window = GetWindow(id);
  if (window && args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
    FlValue* is_always_on_bottom = fl_value_lookup_string(args, "isAlwaysOnBottom");
    if (is_always_on_bottom && fl_value_get_type(is_always_on_bottom) == FL_VALUE_TYPE_BOOL) {
      is_always_on_bottom_ = fl_value_get_bool(is_always_on_bottom);
      gtk_window_set_keep_below(window, is_always_on_bottom_);
    }
  }
}

std::string WindowManagerPlus::GetTitle() {
  GtkWindow* window = GetWindow(id);
  if (window) {
    return gtk_window_get_title(window);
  }
  return "";
}

void WindowManagerPlus::SetTitle(const FlValue* args) {
  GtkWindow* window = GetWindow(id);
  if (window && args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
    FlValue* title = fl_value_lookup_string(args, "title");
    if (title && fl_value_get_type(title) == FL_VALUE_TYPE_STRING) {
      gtk_window_set_title(window, fl_value_get_string(title));
    }
  }
}

void WindowManagerPlus::SetTitleBarStyle(const FlValue* args) {
  if (args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
    FlValue* style = fl_value_lookup_string(args, "titleBarStyle");
    if (style && fl_value_get_type(style) == FL_VALUE_TYPE_STRING) {
      title_bar_style_ = fl_value_get_string(style);
      
      GtkWindow* window = GetWindow(id);
      if (window) {
        // Handle title bar style
        if (title_bar_style_ == "hidden") {
          // For GTK, removing decorations is the closest to "hidden" style
          gtk_window_set_decorated(window, FALSE);
        } else {
          gtk_window_set_decorated(window, !is_frameless_);
        }
      }
    }
  }
}

int WindowManagerPlus::GetTitleBarHeight() {
  // This would require measuring the actual title bar height
  // Not directly available in GTK, would need custom measurement
  return 0;
}

bool WindowManagerPlus::IsSkipTaskbar() {
  return is_skip_taskbar_;
}

void WindowManagerPlus::SetSkipTaskbar(const FlValue* args) {
  GtkWindow* window = GetWindow(id);
  if (window && args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
    FlValue* is_skip_taskbar = fl_value_lookup_string(args, "isSkipTaskbar");
    if (is_skip_taskbar && fl_value_get_type(is_skip_taskbar) == FL_VALUE_TYPE_BOOL) {
      is_skip_taskbar_ = fl_value_get_bool(is_skip_taskbar);
      gtk_window_set_skip_taskbar_hint(window, is_skip_taskbar_);
    }
  }
}

void WindowManagerPlus::SetProgressBar(const FlValue* args) {
  // Linux/GTK doesn't have a standard way to show progress in the taskbar
  // This would need to be implemented using desktop-specific methods
  // such as Unity Launcher API or libunity for Ubuntu
}

void WindowManagerPlus::SetIcon(const FlValue* args) {
  GtkWindow* window = GetWindow(id);
  if (window && args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
    FlValue* file_path = fl_value_lookup_string(args, "filePath");
    if (file_path && fl_value_get_type(file_path) == FL_VALUE_TYPE_STRING) {
      const char* path = fl_value_get_string(file_path);
      gtk_window_set_icon_from_file(window, path, nullptr);
    }
  }
}

bool WindowManagerPlus::HasShadow() {
  // GTK doesn't have a direct API to check for window shadows
  // This is typically controlled by the window manager
  return true;
}

void WindowManagerPlus::SetHasShadow(const FlValue* args) {
  // GTK doesn't have a direct API to control window shadows
  // This would need to be implemented using window manager specific methods
}

double WindowManagerPlus::GetOpacity() {
  GtkWindow* window = GetWindow(id);
  if (window) {
    return gtk_widget_get_opacity(GTK_WIDGET(window));
  }
  return 1.0;
}

void WindowManagerPlus::SetOpacity(const FlValue* args) {
  GtkWindow* window = GetWindow(id);
  if (window && args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
    FlValue* opacity = fl_value_lookup_string(args, "opacity");
    if (opacity && fl_value_get_type(opacity) == FL_VALUE_TYPE_FLOAT) {
      double opacity_value = fl_value_get_float(opacity);
      gtk_widget_set_opacity(GTK_WIDGET(window), opacity_value);
    }
  }
}

void WindowManagerPlus::SetBrightness(const FlValue* args) {
  // Linux/GTK doesn't have a direct API to control window brightness
  // This would need to be implemented using a compositing approach or window shader
}

void WindowManagerPlus::SetIgnoreMouseEvents(const FlValue* args) {
  GtkWindow* window = GetWindow(id);
  if (window && args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
    FlValue* ignore = fl_value_lookup_string(args, "ignore");
    if (ignore && fl_value_get_type(ignore) == FL_VALUE_TYPE_BOOL) {
      bool should_ignore = fl_value_get_bool(ignore);
      
      if (should_ignore) {
        // Make the window passthrough for mouse events
        GdkWindow* gdk_window = gtk_widget_get_window(GTK_WIDGET(window));
        if (gdk_window) {
          gdk_window_set_events(gdk_window, 
                               gdk_window_get_events(gdk_window) & 
                               ~(GDK_BUTTON_PRESS_MASK | 
                                 GDK_BUTTON_RELEASE_MASK | 
                                 GDK_POINTER_MOTION_MASK));
          
          // For more advanced passthrough, X11-specific code might be needed
          #ifdef GDK_WINDOWING_X11
          if (GDK_IS_X11_WINDOW(gdk_window)) {
            Display* xdisplay = gdk_x11_get_default_xdisplay();
            Window xid = gdk_x11_window_get_xid(gdk_window);
            XShapeCombineRectangles(xdisplay, xid, ShapeInput, 0, 0, nullptr, 0, ShapeSet, 0);
          }
          #endif
        }
      } else {
        // Restore normal event handling
        GdkWindow* gdk_window = gtk_widget_get_window(GTK_WIDGET(window));
        if (gdk_window) {
          gdk_window_set_events(gdk_window, 
                               gdk_window_get_events(gdk_window) | 
                               GDK_BUTTON_PRESS_MASK | 
                               GDK_BUTTON_RELEASE_MASK | 
                               GDK_POINTER_MOTION_MASK);
          
          #ifdef GDK_WINDOWING_X11
          if (GDK_IS_X11_WINDOW(gdk_window)) {
            Display* xdisplay = gdk_x11_get_default_xdisplay();
            Window xid = gdk_x11_window_get_xid(gdk_window);
            XShapeCombineMask(xdisplay, xid, ShapeInput, 0, 0, None, ShapeSet);
          }
          #endif
        }
      }
    }
  }
}

void WindowManagerPlus::PopUpWindowMenu(const FlValue* args) {
  // This would need to be implemented using window manager specific methods
  // GTK doesn't have a standard API for this operation
}

void WindowManagerPlus::StartDragging() {
  GtkWindow* window = GetWindow(id);
  if (window) {
    // This needs to be implemented at the event level
    // Typically by handling mouse events and calling gtk_window_begin_move_drag
    // Cannot be easily implemented here without event context
    is_moving_ = true;
    
    // Note: Actual implementation would require handling button press events
    // and calling gtk_window_begin_move_drag from there
  }
}

void WindowManagerPlus::StartResizing(const FlValue* args) {
  GtkWindow* window = GetWindow(id);
  if (window) {
    GdkWindowEdge edge = GDK_WINDOW_EDGE_SOUTH_EAST; // Default to bottom-right
    
    if (args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* direction = fl_value_lookup_string(args, "direction");
      if (direction && fl_value_get_type(direction) == FL_VALUE_TYPE_STRING) {
        const char* dir_str = fl_value_get_string(direction);
        
        if (strcmp(dir_str, "top") == 0) {
          edge = GDK_WINDOW_EDGE_NORTH;
        } else if (strcmp(dir_str, "bottom") == 0) {
          edge = GDK_WINDOW_EDGE_SOUTH;
        } else if (strcmp(dir_str, "left") == 0) {
          edge = GDK_WINDOW_EDGE_WEST;
        } else if (strcmp(dir_str, "right") == 0) {
          edge = GDK_WINDOW_EDGE_EAST;
        } else if (strcmp(dir_str, "top-left") == 0) {
          edge = GDK_WINDOW_EDGE_NORTH_WEST;
        } else if (strcmp(dir_str, "top-right") == 0) {
          edge = GDK_WINDOW_EDGE_NORTH_EAST;
        } else if (strcmp(dir_str, "bottom-left") == 0) {
          edge = GDK_WINDOW_EDGE_SOUTH_WEST;
        }
      }
    }
    
    is_resizing_ = true;
    
    // Note: Actual implementation would require handling button press events
    // and calling gtk_window_begin_resize_drag from there
  }
}

void WindowManagerPlus::ForceChildRefresh() {
  GtkWindow* window = GetWindow(id);
  if (window) {
    // Force redraw of all child widgets
    gtk_widget_queue_draw(GTK_WIDGET(window));
  }
}

}  // namespace window_manager_plus
