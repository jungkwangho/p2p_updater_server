//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <permission_handler_windows/permission_handler_windows_plugin.h>
#include <windows_apps_infos/windows_apps_infos_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  PermissionHandlerWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PermissionHandlerWindowsPlugin"));
  WindowsAppsInfosPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WindowsAppsInfosPluginCApi"));
}
