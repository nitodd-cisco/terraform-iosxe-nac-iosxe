locals {
  class_maps = flatten([
    for device in local.devices : [
      for class_map in try(local.device_config[device.name].class_maps, []) : {
        key                                            = format("%s/%s", device.name, class_map.name)
        device                                         = device.name
        name                                           = try(class_map.name, null)
        type                                           = try(class_map.type, local.defaults.iosxe.configuration.class_maps.type, null)
        subscriber                                     = try(class_map.subscriber, local.defaults.iosxe.configuration.class_maps.subscriber, null)
        prematch                                       = try(class_map.prematch, local.defaults.iosxe.configuration.class_maps.prematch, null)
        match_authorization_status_authorized          = try(class_map.match.authorization_status_authorized, local.defaults.iosxe.configuration.class_maps.match.authorization_status_authorized, null)
        match_result_type_aaa_timeout                  = try(class_map.match.result_type_aaa_timeout, local.defaults.iosxe.configuration.class_maps.match.result_type_aaa_timeout, null)
        match_authorization_status_unauthorized        = try(class_map.match.authorization_status_unauthorized, local.defaults.iosxe.configuration.class_maps.match.authorization_status_unauthorized, null)
        match_activated_service_templates              = try(class_map.match.activated_service_templates, local.defaults.iosxe.configuration.class_maps.match.activated_service_templates, null)
        match_authorizing_method_priority_greater_than = try(class_map.match.authorizing_method_priority_greater_than, local.defaults.iosxe.configuration.class_maps.match.authorizing_method_priority_greater_than, null)
        match_method_dot1x                             = try(class_map.match.method_dot1x, local.defaults.iosxe.configuration.class_maps.match.method_dot1x, null)
        match_result_type_method_dot1x_authoritative   = try(class_map.match.result_type_method_dot1x_authoritative, local.defaults.iosxe.configuration.class_maps.match.result_type_method_dot1x_authoritative, null)
        match_result_type_method_dot1x_agent_not_found = try(class_map.match.result_type_method_dot1x_agent_not_found, local.defaults.iosxe.configuration.class_maps.match.result_type_method_dot1x_agent_not_found, null)
        match_result_type_method_dot1x_method_timeout  = try(class_map.match.result_type_method_dot1x_method_timeout, local.defaults.iosxe.configuration.class_maps.match.result_type_method_dot1x_method_timeout, null)
        match_method_mab                               = try(class_map.match.method_mab, local.defaults.iosxe.configuration.class_maps.match.method_mab, null)
        match_result_type_method_mab_authoritative     = try(class_map.match.result_type_method_mab_authoritative, local.defaults.iosxe.configuration.class_maps.match.result_type_method_mab_authoritative, null)
        match_dscp                                     = try(class_map.match.dscp, local.defaults.iosxe.configuration.class_maps.match.dscp, null)
        description                                    = try(class_map.description, local.defaults.iosxe.configuration.class_maps.description, null)
      }
    ]
  ])
}

resource "iosxe_class_map" "class_map" {
  for_each = { for e in local.class_maps : e.key => e }
  device   = each.value.device

  name                                           = each.value.name
  type                                           = each.value.type
  subscriber                                     = each.value.subscriber
  prematch                                       = each.value.prematch
  match_authorization_status_authorized          = each.value.match_authorization_status_authorized
  match_result_type_aaa_timeout                  = each.value.match_result_type_aaa_timeout
  match_authorization_status_unauthorized        = each.value.match_authorization_status_unauthorized
  match_activated_service_templates              = each.value.match_activated_service_templates
  match_authorizing_method_priority_greater_than = each.value.match_authorizing_method_priority_greater_than
  match_method_dot1x                             = each.value.match_method_dot1x
  match_result_type_method_dot1x_authoritative   = each.value.match_result_type_method_dot1x_authoritative
  match_result_type_method_dot1x_agent_not_found = each.value.match_result_type_method_dot1x_agent_not_found
  match_result_type_method_dot1x_method_timeout  = each.value.match_result_type_method_dot1x_method_timeout
  match_method_mab                               = each.value.match_method_mab
  match_result_type_method_mab_authoritative     = each.value.match_result_type_method_mab_authoritative
  match_dscp                                     = each.value.match_dscp
  description                                    = each.value.description
}
