#include "include/window_manager/window_manager_plus_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <cstring>
#include <map>
#include <memory>
#include <string>

#include "window_manager_plus.h"

using namespace window_manager_plus;

struct _WindowManagerPlugin
{
  GObject parent_instance;
  FlPluginRegistrar *registrar;
  FlMethodChannel *channel;
  std::shared_ptr<WindowManagerPlus> window_manager;
};

G_DEFINE_TYPE(WindowManagerPlugin, window_manager_plugin, g_object_get_type())

// Static method handler for the plugin
static FlMethodResponse *handle_static_method_call(
    WindowManagerPlugin *self,
    const FlMethodCall *method_call)
{
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar *method = fl_method_call_get_name(method_call);
  FlValue *args = fl_method_call_get_args(method_call);

  if (strcmp(method, "createWindow") == 0)
  {
    if (fl_value_get_type(args) == FL_VALUE_TYPE_MAP)
    {
      FlValue *args_value = fl_value_lookup_string(args, "args");
      if (args_value && fl_value_get_type(args_value) == FL_VALUE_TYPE_LIST)
      {
        std::vector<std::string> window_args;
        for (size_t i = 0; i < fl_value_get_length(args_value); i++)
        {
          FlValue *arg = fl_value_get_list_value(args_value, i);
          if (fl_value_get_type(arg) == FL_VALUE_TYPE_STRING)
          {
            window_args.push_back(fl_value_get_string(arg));
          }
        }

        int new_window_id = WindowManagerPlus::createWindow(window_args);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(new_window_id)));
      }
    }

    if (!response)
    {
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_null()));
    }
  }
  else if (strcmp(method, "getAllWindowManagerIds") == 0)
  {
    FlValue *window_ids = fl_value_new_list();

    for (const auto &window : WindowManagerPlus::windowManagers_)
    {
      fl_value_append_take(window_ids, fl_value_new_int(window.first));
    }

    response = FL_METHOD_RESPONSE(fl_method_success_response_new(window_ids));
  }
  else
  {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  return FL_METHOD_RESPONSE(g_steal_pointer(&response));
}

// Handler for method calls on the plugin
static void window_manager_plugin_handle_method_call(
    WindowManagerPlugin *self,
    FlMethodCall *method_call)
{
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar *method = fl_method_call_get_name(method_call);
  FlValue *args = fl_method_call_get_args(method_call);
  int windowId = -1;

  if (fl_value_get_type(args) == FL_VALUE_TYPE_MAP)
  {
    FlValue *window_id_value = fl_value_lookup_string(args, "windowId");
    if (window_id_value && fl_value_get_type(window_id_value) == FL_VALUE_TYPE_INT)
    {
      windowId = fl_value_get_int(window_id_value);
    }
  }

  std::shared_ptr<WindowManagerPlus> wManager = self->window_manager;
  if (windowId >= 0 && WindowManagerPlus::windowManagers_.find(windowId) != WindowManagerPlus::windowManagers_.end())
  {
    wManager = WindowManagerPlus::windowManagers_[windowId];
  }

  // Static method handler
  if (strcmp(method, "createWindow") == 0 ||
      strcmp(method, "getAllWindowManagerIds") == 0)
  {
    response = handle_static_method_call(self, method_call);
  }
  // Handle ensureInitialized separately as it needs special handling
  else if (strcmp(method, "ensureInitialized") == 0)
  {
    if (windowId >= 0)
    {
      // Set up the window manager with the given ID
      self->window_manager->id = windowId;
      self->window_manager->native_window = fl_plugin_registrar_get_view(self->registrar);

      // Create a new channel for this window ID if needed
      std::string channel_name = "window_manager_plus_" + std::to_string(windowId);
      FlBinaryMessenger *messenger = fl_plugin_registrar_get_messenger(self->registrar);

      if (self->channel)
      {
        g_object_unref(self->channel);
      }

      self->channel = fl_method_channel_new(
          messenger,
          channel_name.c_str(),
          FL_METHOD_CODEC(fl_standard_method_codec_new()));

      fl_method_channel_set_method_call_handler(
          self->channel,
          reinterpret_cast<FlMethodChannelMethodCallHandler>(window_manager_plugin_handle_method_call),
          self, NULL);

      // Store window manager in static map
      WindowManagerPlus::windowManagers_[windowId] = self->window_manager;

      // Get the actual GTK window and store it
      GtkWidget *view = GTK_WIDGET(fl_plugin_registrar_get_view(self->registrar));
      if (view)
      {
        GtkWindow *window = GTK_WINDOW(gtk_widget_get_toplevel(view));
        if (window && GTK_IS_WINDOW(window))
        {
          WindowManagerPlus::windows_[windowId] = window;
        }
      }

      response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
    }
    else
    {
      response = FL_METHOD_RESPONSE(
          fl_method_error_response_new(
              "0", "Cannot ensureInitialized! windowId >= 0 is required", nullptr));
    }
  }
  // Handle other window manager methods
  else if (strcmp(method, "waitUntilReadyToShow") == 0)
  {
    wManager->WaitUntilReadyToShow();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "setAsFrameless") == 0)
  {
    wManager->SetAsFrameless();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "destroy") == 0)
  {
    wManager->Destroy();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "close") == 0)
  {
    wManager->Close();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "isPreventClose") == 0)
  {
    bool value = wManager->IsPreventClose();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(value)));
  }
  else if (strcmp(method, "setPreventClose") == 0)
  {
    wManager->SetPreventClose(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "focus") == 0)
  {
    wManager->Focus();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "blur") == 0)
  {
    wManager->Blur();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "isFocused") == 0)
  {
    bool value = wManager->IsFocused();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(value)));
  }
  else if (strcmp(method, "show") == 0)
  {
    wManager->Show();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "hide") == 0)
  {
    wManager->Hide();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "isVisible") == 0)
  {
    bool value = wManager->IsVisible();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(value)));
  }
  else if (strcmp(method, "isMaximized") == 0)
  {
    bool value = wManager->IsMaximized();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(value)));
  }
  else if (strcmp(method, "maximize") == 0)
  {
    wManager->Maximize(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "unmaximize") == 0)
  {
    wManager->Unmaximize();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "isMinimized") == 0)
  {
    bool value = wManager->IsMinimized();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(value)));
  }
  else if (strcmp(method, "minimize") == 0)
  {
    wManager->Minimize();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "restore") == 0)
  {
    wManager->Restore();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "isDockable") == 0)
  {
    bool value = wManager->IsDockable();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(value)));
  }
  else if (strcmp(method, "isDocked") == 0)
  {
    int value = wManager->IsDocked();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(value)));
  }
  else if (strcmp(method, "dock") == 0)
  {
    wManager->Dock(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "undock") == 0)
  {
    bool value = wManager->Undock();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(value)));
  }
  else if (strcmp(method, "isFullScreen") == 0)
  {
    bool value = wManager->IsFullScreen();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(value)));
  }
  else if (strcmp(method, "setFullScreen") == 0)
  {
    wManager->SetFullScreen(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "setAspectRatio") == 0)
  {
    wManager->SetAspectRatio(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "setBackgroundColor") == 0)
  {
    wManager->SetBackgroundColor(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "getBounds") == 0)
  {
    FlValue *value = wManager->GetBounds(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(value));
  }
  else if (strcmp(method, "setBounds") == 0)
  {
    wManager->SetBounds(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "setMinimumSize") == 0)
  {
    wManager->SetMinimumSize(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "setMaximumSize") == 0)
  {
    wManager->SetMaximumSize(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "isResizable") == 0)
  {
    bool value = wManager->IsResizable();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(value)));
  }
  else if (strcmp(method, "setResizable") == 0)
  {
    wManager->SetResizable(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "isMinimizable") == 0)
  {
    bool value = wManager->IsMinimizable();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(value)));
  }
  else if (strcmp(method, "setMinimizable") == 0)
  {
    wManager->SetMinimizable(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "isMaximizable") == 0)
  {
    bool value = wManager->IsMaximizable();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(value)));
  }
  else if (strcmp(method, "setMaximizable") == 0)
  {
    wManager->SetMaximizable(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "isClosable") == 0)
  {
    bool value = wManager->IsClosable();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(value)));
  }
  else if (strcmp(method, "setClosable") == 0)
  {
    wManager->SetClosable(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "isAlwaysOnTop") == 0)
  {
    bool value = wManager->IsAlwaysOnTop();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(value)));
  }
  else if (strcmp(method, "setAlwaysOnTop") == 0)
  {
    wManager->SetAlwaysOnTop(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "isAlwaysOnBottom") == 0)
  {
    bool value = wManager->IsAlwaysOnBottom();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(value)));
  }
  else if (strcmp(method, "setAlwaysOnBottom") == 0)
  {
    wManager->SetAlwaysOnBottom(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "getTitle") == 0)
  {
    std::string value = wManager->GetTitle();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_string(value.c_str())));
  }
  else if (strcmp(method, "setTitle") == 0)
  {
    wManager->SetTitle(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "setTitleBarStyle") == 0)
  {
    wManager->SetTitleBarStyle(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "getTitleBarHeight") == 0)
  {
    int value = wManager->GetTitleBarHeight();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(value)));
  }
  else if (strcmp(method, "isSkipTaskbar") == 0)
  {
    bool value = wManager->IsSkipTaskbar();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(value)));
  }
  else if (strcmp(method, "setSkipTaskbar") == 0)
  {
    wManager->SetSkipTaskbar(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "setProgressBar") == 0)
  {
    wManager->SetProgressBar(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "setIcon") == 0)
  {
    wManager->SetIcon(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "hasShadow") == 0)
  {
    bool value = wManager->HasShadow();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(value)));
  }
  else if (strcmp(method, "setHasShadow") == 0)
  {
    wManager->SetHasShadow(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "getOpacity") == 0)
  {
    double value = wManager->GetOpacity();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_float(value)));
  }
  else if (strcmp(method, "setOpacity") == 0)
  {
    wManager->SetOpacity(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "setBrightness") == 0)
  {
    wManager->SetBrightness(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "setIgnoreMouseEvents") == 0)
  {
    wManager->SetIgnoreMouseEvents(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "popUpWindowMenu") == 0)
  {
    wManager->PopUpWindowMenu(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "startDragging") == 0)
  {
    wManager->StartDragging();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else if (strcmp(method, "startResizing") == 0)
  {
    wManager->StartResizing(args);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  else
  {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  if (!response)
  {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

// Signal handlers for window state changes
static gboolean on_window_state_event(GtkWidget *widget, GdkEventWindowState *event, gpointer user_data)
{
  WindowManagerPlugin *plugin = WINDOW_MANAGER_PLUGIN(user_data);

  // Check for state changes
  if (event->changed_mask & GDK_WINDOW_STATE_FULLSCREEN)
  {
    if (event->new_window_state & GDK_WINDOW_STATE_FULLSCREEN)
    {
      // Entered fullscreen
      plugin->window_manager->last_state = STATE_FULLSCREEN_ENTERED;
      // Emit event
      if (plugin->channel)
      {
        g_autoptr(FlValue) event_map = fl_value_new_map();
        fl_value_set_string_take(event_map, "eventName", fl_value_new_string("enter-full-screen"));
        fl_method_channel_invoke_method(plugin->channel, "onEvent", event_map, nullptr, nullptr, nullptr);
      }
    }
    else
    {
      // Left fullscreen
      plugin->window_manager->last_state = STATE_NORMAL;
      // Emit event
      if (plugin->channel)
      {
        g_autoptr(FlValue) event_map = fl_value_new_map();
        fl_value_set_string_take(event_map, "eventName", fl_value_new_string("leave-full-screen"));
        fl_method_channel_invoke_method(plugin->channel, "onEvent", event_map, nullptr, nullptr, nullptr);
      }
    }
  }

  if (event->changed_mask & GDK_WINDOW_STATE_MAXIMIZED)
  {
    if (event->new_window_state & GDK_WINDOW_STATE_MAXIMIZED)
    {
      // Maximized
      plugin->window_manager->last_state = STATE_MAXIMIZED;
      // Emit event
      if (plugin->channel)
      {
        g_autoptr(FlValue) event_map = fl_value_new_map();
        fl_value_set_string_take(event_map, "eventName", fl_value_new_string("maximize"));
        fl_method_channel_invoke_method(plugin->channel, "onEvent", event_map, nullptr, nullptr, nullptr);
      }
    }
    else if (plugin->window_manager->last_state == STATE_MAXIMIZED)
    {
      // Unmaximized
      plugin->window_manager->last_state = STATE_NORMAL;
      // Emit event
      if (plugin->channel)
      {
        g_autoptr(FlValue) event_map = fl_value_new_map();
        fl_value_set_string_take(event_map, "eventName", fl_value_new_string("unmaximize"));
        fl_method_channel_invoke_method(plugin->channel, "onEvent", event_map, nullptr, nullptr, nullptr);
      }
    }
  }

  if (event->changed_mask & GDK_WINDOW_STATE_ICONIFIED)
  {
    if (event->new_window_state & GDK_WINDOW_STATE_ICONIFIED)
    {
      // Minimized
      plugin->window_manager->last_state = STATE_MINIMIZED;
      // Emit event
      if (plugin->channel)
      {
        g_autoptr(FlValue) event_map = fl_value_new_map();
        fl_value_set_string_take(event_map, "eventName", fl_value_new_string("minimize"));
        fl_method_channel_invoke_method(plugin->channel, "onEvent", event_map, nullptr, nullptr, nullptr);
      }
    }
    else if (plugin->window_manager->last_state == STATE_MINIMIZED)
    {
      // Restored from minimized
      plugin->window_manager->last_state = STATE_NORMAL;
      // Emit event
      if (plugin->channel)
      {
        g_autoptr(FlValue) event_map = fl_value_new_map();
        fl_value_set_string_take(event_map, "eventName", fl_value_new_string("restore"));
        fl_method_channel_invoke_method(plugin->channel, "onEvent", event_map, nullptr, nullptr, nullptr);
      }
    }
  }

  return FALSE;
}

static gboolean on_delete_event(GtkWidget *widget, GdkEvent *event, gpointer user_data)
{
  WindowManagerPlugin *plugin = WINDOW_MANAGER_PLUGIN(user_data);

  // Emit close event
  if (plugin->channel)
  {
    g_autoptr(FlValue) event_map = fl_value_new_map();
    fl_value_set_string_take(event_map, "eventName", fl_value_new_string("close"));
    fl_method_channel_invoke_method(plugin->channel, "onEvent", event_map, nullptr, nullptr, nullptr);
  }

  // Check if we should prevent close
  if (plugin->window_manager->IsPreventClose())
  {
    return TRUE; // Prevent close
  }

  return FALSE; // Allow close
}

static gboolean on_focus_in_event(GtkWidget *widget, GdkEvent *event, gpointer user_data)
{
  WindowManagerPlugin *plugin = WINDOW_MANAGER_PLUGIN(user_data);

  // Emit focus event
  if (plugin->channel)
  {
    g_autoptr(FlValue) event_map = fl_value_new_map();
    fl_value_set_string_take(event_map, "eventName", fl_value_new_string("focus"));
    fl_method_channel_invoke_method(plugin->channel, "onEvent", event_map, nullptr, nullptr, nullptr);
  }

  return FALSE;
}

static gboolean on_focus_out_event(GtkWidget *widget, GdkEvent *event, gpointer user_data)
{
  WindowManagerPlugin *plugin = WINDOW_MANAGER_PLUGIN(user_data);

  // Emit blur event
  if (plugin->channel)
  {
    g_autoptr(FlValue) event_map = fl_value_new_map();
    fl_value_set_string_take(event_map, "eventName", fl_value_new_string("blur"));
    fl_method_channel_invoke_method(plugin->channel, "onEvent", event_map, nullptr, nullptr, nullptr);
  }

  return FALSE;
}

// Plugin initialization and teardown
static void window_manager_plugin_dispose(GObject *object)
{
  WindowManagerPlugin *self = WINDOW_MANAGER_PLUGIN(object);

  g_clear_object(&self->channel);
  g_clear_object(&self->registrar);

  G_OBJECT_CLASS(window_manager_plugin_parent_class)->dispose(object);
}

static void window_manager_plugin_class_init(WindowManagerPluginClass *klass)
{
  G_OBJECT_CLASS(klass)->dispose = window_manager_plugin_dispose;
}

static void window_manager_plugin_init(WindowManagerPlugin *self)
{
  self->window_manager = std::make_shared<WindowManagerPlus>();
}

static void method_call_cb(FlMethodChannel *channel, FlMethodCall *method_call,
                           gpointer user_data)
{
  WindowManagerPlugin *plugin = WINDOW_MANAGER_PLUGIN(user_data);
  window_manager_plugin_handle_method_call(plugin, method_call);
}

void window_manager_plugin_register_with_registrar(FlPluginRegistrar *registrar)
{
  // FIXME: If there are issues with plugin registration, make sure this function
  // name matches what's expected in the generated plugin registrant
  WindowManagerPlugin *plugin = WINDOW_MANAGER_PLUGIN(
      g_object_new(window_manager_plugin_get_type(), nullptr));

  plugin->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));

  // Create channel for main plugin
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->channel = fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                                          "window_manager_plus",
                                          FL_METHOD_CODEC(g_object_ref(codec)));
  fl_method_channel_set_method_call_handler(plugin->channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  // Create static channel
  g_autoptr(FlMethodChannel) static_channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "window_manager_plus_static",
      FL_METHOD_CODEC(g_object_ref(codec)));
  fl_method_channel_set_method_call_handler(static_channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);
  plugin->window_manager->static_channel = std::unique_ptr<FlMethodChannel>(
      FL_METHOD_CHANNEL(g_object_ref(static_channel)));

  // Connect to window state signals
  GtkWidget *view = GTK_WIDGET(fl_plugin_registrar_get_view(registrar));
  if (view != nullptr)
  {
    GtkWindow *window = GTK_WINDOW(gtk_widget_get_toplevel(view));
    if (GTK_IS_WINDOW(window))
    {
      // Store window reference
      int default_id = 0;
      WindowManagerPlus::windows_[default_id] = window;

      // Connect signals
      g_signal_connect(window, "window-state-event", G_CALLBACK(on_window_state_event), plugin);
      g_signal_connect(window, "delete-event", G_CALLBACK(on_delete_event), plugin);
      g_signal_connect(window, "focus-in-event", G_CALLBACK(on_focus_in_event), plugin);
      g_signal_connect(window, "focus-out-event", G_CALLBACK(on_focus_out_event), plugin);
    }
  }

  g_object_unref(plugin);
}
