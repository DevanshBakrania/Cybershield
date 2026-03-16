//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <audioplayers_windows/audioplayers_windows_plugin.h>
#include <battery_plus/battery_plus_windows_plugin.h>
#include <connectivity_plus/connectivity_plus_windows_plugin.h>
#include <disk_space_2/disk_space_2_plugin.h>
#include <flutter_secure_storage_windows/flutter_secure_storage_windows_plugin.h>
#include <flutter_volume_controller/flutter_volume_controller_plugin_c_api.h>
#include <local_auth_windows/local_auth_plugin.h>
#include <permission_handler_windows/permission_handler_windows_plugin.h>
#include <record_windows/record_windows_plugin_c_api.h>
#include <screen_brightness_windows/screen_brightness_windows_plugin.h>
#include <url_launcher_windows/url_launcher_windows.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  AudioplayersWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("AudioplayersWindowsPlugin"));
  BatteryPlusWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("BatteryPlusWindowsPlugin"));
  ConnectivityPlusWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ConnectivityPlusWindowsPlugin"));
  DiskSpace_2PluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("DiskSpace_2Plugin"));
  FlutterSecureStorageWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterSecureStorageWindowsPlugin"));
  FlutterVolumeControllerPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterVolumeControllerPluginCApi"));
  LocalAuthPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("LocalAuthPlugin"));
  PermissionHandlerWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PermissionHandlerWindowsPlugin"));
  RecordWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("RecordWindowsPluginCApi"));
  ScreenBrightnessWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ScreenBrightnessWindowsPlugin"));
  UrlLauncherWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherWindows"));
}
