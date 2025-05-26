#ifndef WINDOW_MANAGER_PLUS_LINUX_WINDOW_MANAGER_PLUS_H_
#define WINDOW_MANAGER_PLUS_LINUX_WINDOW_MANAGER_PLUS_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <map>
#include <memory>
#include <string>

namespace window_manager_plus {

enum WindowState {
  STATE_NORMAL,
  STATE_MAXIMIZED,
  STATE_MINIMIZED,
  STATE_FULLSCREEN_ENTERED
};

class WindowManagerPlus {
 public:
  WindowManagerPlus();
  ~WindowManagerPlus();

  static std::map<int, std::shared_ptr<WindowManagerPlus>> windowManagers_;
  static std::map<int, GtkWindow*> windows_;
  static int createWindow(const std::vector<std::string>& arguments);

  int id;
  std::unique_ptr<FlMethodChannel> channel;
  std::unique_ptr<FlMethodChannel> static_channel;
  GtkWidget* native_window;
  bool is_prevent_close_ = false;
  bool is_frameless_ = false;
  WindowState last_state = STATE_NORMAL;
  std::string title_bar_style_ = "normal";
  bool is_resizable_ = true;
  bool is_resizing_ = false;
  bool is_moving_ = false;
  bool is_always_on_top_ = false;
  bool is_always_on_bottom_ = false;
  bool is_skip_taskbar_ = false;
  float pixel_ratio_ = 1.0f;
  double aspect_ratio_ = 0;
  double minimum_size_[2] = {0, 0};
  double maximum_size_[2] = {-1, -1};

  void WaitUntilReadyToShow();
  void SetAsFrameless();
  void Destroy();
  void Close();
  bool IsPreventClose();
  void SetPreventClose(const FlValue* args);
  void Focus();
  void Blur();
  bool IsFocused();
  void Show();
  void Hide();
  bool IsVisible();
  bool IsMaximized();
  void Maximize(const FlValue* args);
  void Unmaximize();
  bool IsMinimized();
  void Minimize();
  void Restore();
  bool IsDockable();
  int IsDocked();
  void Dock(const FlValue* args);
  bool Undock();
  bool IsFullScreen();
  void SetFullScreen(const FlValue* args);
  void SetAspectRatio(const FlValue* args);
  void SetBackgroundColor(const FlValue* args);
  FlValue* GetBounds(const FlValue* args);
  void SetBounds(const FlValue* args);
  void SetMinimumSize(const FlValue* args);
  void SetMaximumSize(const FlValue* args);
  bool IsResizable();
  void SetResizable(const FlValue* args);
  bool IsMinimizable();
  void SetMinimizable(const FlValue* args);
  bool IsMaximizable();
  void SetMaximizable(const FlValue* args);
  bool IsClosable();
  void SetClosable(const FlValue* args);
  bool IsAlwaysOnTop();
  void SetAlwaysOnTop(const FlValue* args);
  bool IsAlwaysOnBottom();
  void SetAlwaysOnBottom(const FlValue* args);
  std::string GetTitle();
  void SetTitle(const FlValue* args);
  void SetTitleBarStyle(const FlValue* args);
  int GetTitleBarHeight();
  bool IsSkipTaskbar();
  void SetSkipTaskbar(const FlValue* args);
  void SetProgressBar(const FlValue* args);
  void SetIcon(const FlValue* args);
  bool HasShadow();
  void SetHasShadow(const FlValue* args);
  double GetOpacity();
  void SetOpacity(const FlValue* args);
  void SetBrightness(const FlValue* args);
  void SetIgnoreMouseEvents(const FlValue* args);
  void PopUpWindowMenu(const FlValue* args);
  void StartDragging();
  void StartResizing(const FlValue* args);
  void ForceChildRefresh();
};

}  // namespace window_manager_plus

#endif  // WINDOW_MANAGER_PLUS_LINUX_WINDOW_MANAGER_PLUS_H_
