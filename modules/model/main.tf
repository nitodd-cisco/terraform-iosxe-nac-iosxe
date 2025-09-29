locals {
  iosxe            = try(local.model.iosxe, {})
  global           = try(local.iosxe.global, [])
  devices          = try(local.iosxe.devices, [])
  device_groups    = try(local.iosxe.device_groups, [])
  interface_groups = try(local.iosxe.interface_groups, [])

  all_devices = [for device in local.devices : {
    name    = device.name
    url     = device.url
    managed = try(device.managed, local.defaults.iosxe.devices.managed, true)
  }]

  managed_devices = [
    for device in local.devices : device if(length(var.managed_devices) == 0 || contains(var.managed_devices, device.name)) && (length(var.managed_device_groups) == 0 || anytrue([for dg in local.device_groups : contains(try(device.device_groups, []), dg.name) && contains(var.managed_device_groups, dg.name)]) || anytrue([for dg in local.device_groups : contains(try(dg.devices, []), device.name) && contains(var.managed_device_groups, dg.name)]))
  ]

  device_variables = { for device in local.managed_devices :
    device.name => merge(concat(
      [try(local.global.variables, {})],
      [for dg in local.device_groups : try(dg.variables, {}) if contains(try(device.device_groups, []), dg.name) || contains(try(dg.devices, []), device.name)],
      [try(device.variables, {})]
    )...)
  }

  global_config_templates = compact([
    for t in try(local.global.configuration_templates, []) :
    try([for path in local.template_paths : templatefile(path, try(local.global.variables, {})) if split(".", basename(path))[0] == t][0], null)
  ])

  group_config_templates = { for device in local.managed_devices :
    device.name => flatten([
      for dg in local.device_groups : compact([
        for t in try(dg.configuration_templates, []) :
        try([for path in local.template_paths : templatefile(path, merge(local.device_variables[device.name], try(dg.variables, {}))) if split(".", basename(path))[0] == t][0], null)
      ])
      if contains(try(device.device_groups, []), dg.name) || contains(try(dg.devices, []), device.name)
    ])
  }

  device_config_templates = { for device in local.managed_devices :
    device.name => compact([
      for t in try(device.configuration_templates, []) :
      try([for path in local.template_paths : templatefile(path, local.device_variables[device.name]) if split(".", basename(path))[0] == t][0], null)
    ])
  }

  devices_raw_config = { for device in local.managed_devices :
    device.name => try(provider::utils::yaml_merge(concat(
      local.global_config_templates,
      [yamlencode(try(local.global.configuration, {}))],
      local.group_config_templates[device.name],
      [for dg in local.device_groups : yamlencode(try(dg.configuration, {})) if contains(try(device.device_groups, []), dg.name) || contains(try(dg.devices, []), device.name)],
      local.device_config_templates[device.name],
      [yamlencode(try(device.configuration, {}))]
    )), "")
  }

  devices_config = { for device, config in local.devices_raw_config :
    device => yamldecode(templatestring(config, local.device_variables[device]))
  }

  interface_groups_raw_config = {
    for device in local.managed_devices : device.name => {
      for ig in local.interface_groups : ig.name => yamlencode(try(ig.configuration, {}))
    }
  }

  interface_groups_config = {
    for device in local.managed_devices : device.name => [
      for ig in local.interface_groups : {
        name          = ig.name
        configuration = yamldecode(templatestring(local.interface_groups_raw_config[device.name][ig.name], local.device_variables[device.name]))
      }
    ]
  }

  iosxe_devices = {
    iosxe = {
      devices = [
        for device in try(local.managed_devices, []) : {
          name    = device.name
          url     = device.url
          managed = try(device.managed, local.defaults.iosxe.devices.managed, true)
          configuration = merge(
            { for k, v in try(local.devices_config[device.name], {}) : k => v if k != "interfaces" },
            {
              interfaces = merge(
                { for k, v in try(local.devices_config[device.name].interfaces, {}) : k => v if k != "ethernets" && k != "loopbacks" && k != "vlans" },
                {
                  "ethernets" = [
                    for ethernet in try(local.devices_config[device.name].interfaces.ethernets, []) : merge(
                      yamldecode(provider::utils::yaml_merge(concat(
                        [for g in try(ethernet.interface_groups, []) : try([for ig in local.interface_groups_config[device.name] : yamlencode(ig.configuration) if ig.name == g][0], "")],
                        [yamlencode(ethernet)]
                      )))
                    )
                  ]
                },
                {
                  "vlans" = [
                    for vlan in try(local.devices_config[device.name].interfaces.vlans, []) : merge(
                      yamldecode(provider::utils::yaml_merge(concat(
                        [for g in try(vlan.interface_groups, []) : try([for ig in local.interface_groups_config[device.name] : yamlencode(ig.configuration) if ig.name == g][0], "")],
                        [yamlencode(vlan)]
                      )))
                    )
                  ]
                },
                {
                  "loopbacks" = [
                    for loopback in try(local.devices_config[device.name].interfaces.loopbacks, []) : merge(
                      yamldecode(provider::utils::yaml_merge(concat(
                        [for g in try(loopback.interface_groups, []) : try([for ig in local.interface_groups_config[device.name] : yamlencode(ig.configuration) if ig.name == g][0], "")],
                        [yamlencode(loopback)]
                      )))
                    )
                  ]
                }
              )
            }
          )
        }
      ]
    }
  }
}
