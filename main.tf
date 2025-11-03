locals {
  wnw_rules_json         = jsondecode(file("${var.wnw_rules_json_file_path}"))
  wnw_rules_data         = local.wnw_rules_json.data.policy.wanNetwork.policy.rules
  sections_data_unsorted = local.wnw_rules_json.data.policy.wanNetwork.policy.sections
  # Create a map with section_index as key to sort sections correctly
  sections_by_index = {
    for section in local.sections_data_unsorted :
    tostring(section.section_index) => section
  }
  # Sort sections by section_index to ensure consistent ordering regardless of JSON file order
  sections_data_list = [
    for index in sort(keys(local.sections_by_index)) :
    local.sections_by_index[index]
  ]
  # Convert sections to map for provider schema compatibility
  sections_data = {
    for section in local.sections_data_list :
    section.section_name => section
  }
  # Convert rules to map for provider schema compatibility
  rules_data = {
    for rule in local.wnw_rules_json.data.policy.wanNetwork.policy.rules_in_sections :
    rule.rule_name => rule
  }
}

resource "cato_wnw_section" "sections" {
  for_each = local.sections_data
  at = {
    position = "LAST_IN_POLICY"
  }
  section = {
    name = each.value.section_name
  }
}

resource "cato_wnw_rule" "rules" {
  depends_on = [cato_wnw_section.sections]
  for_each   = { for rule in local.wnw_rules_data : rule.rule.name => rule }

  at = {
    position = "LAST_IN_POLICY" // adding last to reorder in cato_bulk_wnw_move_rule
  }

  rule = merge(
    {
      name      = each.value.rule.name
      enabled   = each.value.rule.enabled
      rule_type = each.value.rule.ruleType
    },

    # Only include description if it's not empty
    each.value.rule.description != "" ? {
      description = each.value.rule.description
    } : {},

    # Only include route_type if it exists
    try(each.value.rule.routeType, null) != null ? {
      route_type = each.value.rule.routeType
    } : {},

    # Dynamic source block - include if source exists (even if empty)
    try(each.value.rule.source, null) != null ? {
      source = {
        for k, v in {
          ip                = try(length(each.value.rule.source.ip), 0) > 0 ? each.value.rule.source.ip : null
          host              = try(length(each.value.rule.source.host), 0) > 0 ? [for host in each.value.rule.source.host : can(host.name) ? { name = host.name } : { id = host.id }] : null
          site              = try(length(each.value.rule.source.site), 0) > 0 ? [for site in each.value.rule.source.site : can(site.name) ? { name = site.name } : { id = site.id }] : null
          users_group       = try(length(each.value.rule.source.usersGroup), 0) > 0 ? [for group in each.value.rule.source.usersGroup : can(group.name) ? { name = group.name } : { id = group.id }] : null
          subnet            = try(length(each.value.rule.source.subnet), 0) > 0 ? each.value.rule.source.subnet : null
          ip_range          = try(length(each.value.rule.source.ipRange), 0) > 0 ? [for range in each.value.rule.source.ipRange : {
            from = range.from
            to   = range.to
          }] : null
          network_interface   = try(length(each.value.rule.source.networkInterface), 0) > 0 ? [for ni in each.value.rule.source.networkInterface : can(ni.name) ? { name = ni.name } : { id = ni.id }] : null
          floating_subnet     = try(length(each.value.rule.source.floatingSubnet), 0) > 0 ? [for subnet in each.value.rule.source.floatingSubnet : can(subnet.name) ? { name = subnet.name } : { id = subnet.id }] : null
          site_network_subnet = try(length(each.value.rule.source.siteNetworkSubnet), 0) > 0 ? [for subnet in each.value.rule.source.siteNetworkSubnet : can(subnet.name) ? { name = subnet.name } : { id = subnet.id }] : null
          system_group        = try(length(each.value.rule.source.systemGroup), 0) > 0 ? [for group in each.value.rule.source.systemGroup : can(group.name) ? { name = group.name } : { id = group.id }] : null
          group               = try(length(each.value.rule.source.group), 0) > 0 ? [for group in each.value.rule.source.group : can(group.name) ? { name = group.name } : { id = group.id }] : null
          user                = try(length(each.value.rule.source.user), 0) > 0 ? [for user in each.value.rule.source.user : can(user.name) ? { name = user.name } : { id = user.id }] : null
          global_ip_range     = try(length(each.value.rule.source.globalIpRange), 0) > 0 ? [for range in each.value.rule.source.globalIpRange : can(range.name) ? { name = range.name } : { id = range.id }] : null
        } : k => v if v != null
      }
    } : {},

    # Dynamic destination block - include if destination exists (even if empty)
    try(each.value.rule.destination, null) != null ? {
      destination = {
        for k, v in {
          ip                  = try(length(each.value.rule.destination.ip), 0) > 0 ? each.value.rule.destination.ip : null
          host                = try(length(each.value.rule.destination.host), 0) > 0 ? [for host in each.value.rule.destination.host : can(host.name) ? { name = host.name } : { id = host.id }] : null
          site                = try(length(each.value.rule.destination.site), 0) > 0 ? [for site in each.value.rule.destination.site : can(site.name) ? { name = site.name } : { id = site.id }] : null
          users_group         = try(length(each.value.rule.destination.usersGroup), 0) > 0 ? [for group in each.value.rule.destination.usersGroup : can(group.name) ? { name = group.name } : { id = group.id }] : null
          subnet              = try(length(each.value.rule.destination.subnet), 0) > 0 ? each.value.rule.destination.subnet : null
          ip_range            = try(length(each.value.rule.destination.ipRange), 0) > 0 ? [for range in each.value.rule.destination.ipRange : {
            from = range.from
            to   = range.to
          }] : null
          network_interface   = try(length(each.value.rule.destination.networkInterface), 0) > 0 ? [for ni in each.value.rule.destination.networkInterface : can(ni.name) ? { name = ni.name } : { id = ni.id }] : null
          floating_subnet     = try(length(each.value.rule.destination.floatingSubnet), 0) > 0 ? [for subnet in each.value.rule.destination.floatingSubnet : can(subnet.name) ? { name = subnet.name } : { id = subnet.id }] : null
          site_network_subnet = try(length(each.value.rule.destination.siteNetworkSubnet), 0) > 0 ? [for subnet in each.value.rule.destination.siteNetworkSubnet : can(subnet.name) ? { name = subnet.name } : { id = subnet.id }] : null
          system_group        = try(length(each.value.rule.destination.systemGroup), 0) > 0 ? [for group in each.value.rule.destination.systemGroup : can(group.name) ? { name = group.name } : { id = group.id }] : null
          group               = try(length(each.value.rule.destination.group), 0) > 0 ? [for group in each.value.rule.destination.group : can(group.name) ? { name = group.name } : { id = group.id }] : null
          user                = try(length(each.value.rule.destination.user), 0) > 0 ? [for user in each.value.rule.destination.user : can(user.name) ? { name = user.name } : { id = user.id }] : null
          global_ip_range     = try(length(each.value.rule.destination.globalIpRange), 0) > 0 ? [for range in each.value.rule.destination.globalIpRange : can(range.name) ? { name = range.name } : { id = range.id }] : null
        } : k => v if v != null
      }
    } : {},

    # Dynamic application block - include if application exists (even if empty)
    try(each.value.rule.application, null) != null ? {
      application = {
        for k, v in {
          app_category = try(length(each.value.rule.application.appCategory), 0) > 0 ? [for cat in each.value.rule.application.appCategory : can(cat.name) ? { name = cat.name } : { id = cat.id }] : null

          application = try(length(each.value.rule.application.application), 0) > 0 ? [for app in each.value.rule.application.application : can(app.name) ? { name = app.name } : { id = app.id }] : null

          custom_app = try(length(each.value.rule.application.customApp), 0) > 0 ? [for app in each.value.rule.application.customApp : can(app.name) ? { name = app.name } : { id = app.id }] : null

          custom_category = try(length(each.value.rule.application.customCategory), 0) > 0 ? [for cat in each.value.rule.application.customCategory : can(cat.name) ? { name = cat.name } : { id = cat.id }] : null

          domain = try(length(each.value.rule.application.domain), 0) > 0 ? each.value.rule.application.domain : null

          fqdn = try(length(each.value.rule.application.fqdn), 0) > 0 ? each.value.rule.application.fqdn : null

          service = try(length(each.value.rule.application.service), 0) > 0 ? [for svc in each.value.rule.application.service : can(svc.name) ? { name = svc.name } : { id = svc.id }] : null

          custom_service = try(length(each.value.rule.application.customService), 0) > 0 ? [for svc in each.value.rule.application.customService : merge(
            {
              protocol = svc.protocol
            },
            try(length(svc.port), 0) > 0 ? {
              port = [for p in svc.port : tostring(p)]
            } : {},
            try(svc.portRange, null) != null ? {
              port_range = {
                from = tostring(svc.portRange.from)
                to   = tostring(svc.portRange.to)
              }
            } : {}
          )] : null

          custom_service_ip = try(length(each.value.rule.application.customServiceIp), 0) > 0 ? [for svc in each.value.rule.application.customServiceIp : merge(
            {
              name = svc.name
            },
            try(svc.ip, null) != null && svc.ip != "" ? {
              ip = svc.ip
            } : {},
            try(svc.ipRange, null) != null ? {
              ip_range = {
                from = svc.ipRange.from
                to   = svc.ipRange.to
              }
            } : {}
          )] : null
        } : k => v if v != null
      }
    } : {},

    # Dynamic configuration block
    try(each.value.rule.configuration, null) != null ? {
      configuration = merge(
        # Active TCP Acceleration
        try(each.value.rule.configuration.activeTcpAcceleration, null) != null ? {
          active_tcp_acceleration = each.value.rule.configuration.activeTcpAcceleration
        } : {},

        # Packet Loss Mitigation
        try(each.value.rule.configuration.packetLossMitigation, null) != null ? {
          packet_loss_mitigation = each.value.rule.configuration.packetLossMitigation
        } : {},

        # Preserve Source Port
        try(each.value.rule.configuration.preserveSourcePort, null) != null ? {
          preserve_source_port = each.value.rule.configuration.preserveSourcePort
        } : {},

        # Allocation IP
        try(length(each.value.rule.configuration.allocationIp), 0) > 0 ? {
          allocation_ip = [for ip in each.value.rule.configuration.allocationIp : can(ip.name) ? { name = ip.name } : { id = ip.id }]
        } : {},

        # Backhauling Site
        try(length(each.value.rule.configuration.backhaulingSite), 0) > 0 ? {
          backhauling_site = [for site in each.value.rule.configuration.backhaulingSite : can(site.name) ? { name = site.name } : { id = site.id }]
        } : {},

        # PoP Location
        try(length(each.value.rule.configuration.popLocation), 0) > 0 ? {
          pop_location = [for pop in each.value.rule.configuration.popLocation : can(pop.name) ? { name = pop.name } : { id = pop.id }]
        } : {},

        # Primary Transport
        try(each.value.rule.configuration.primaryTransport, null) != null ? {
          primary_transport = {
            for k, v in {
              transport_type            = try(each.value.rule.configuration.primaryTransport.transportType, null)
              primary_interface_role    = try(each.value.rule.configuration.primaryTransport.primaryInterfaceRole, null)
              secondary_interface_role  = try(each.value.rule.configuration.primaryTransport.secondaryInterfaceRole, null)
            } : k => v if v != null
          }
        } : {},

        # Secondary Transport
        try(each.value.rule.configuration.secondaryTransport, null) != null ? {
          secondary_transport = {
            for k, v in {
              transport_type            = try(each.value.rule.configuration.secondaryTransport.transportType, null)
              primary_interface_role    = try(each.value.rule.configuration.secondaryTransport.primaryInterfaceRole, null)
              secondary_interface_role  = try(each.value.rule.configuration.secondaryTransport.secondaryInterfaceRole, null)
            } : k => v if v != null
          }
        } : {}
      )
    } : {},

    # Bandwidth Priority
    try(each.value.rule.bandwidthPriority.name, null) != null ? {
      bandwidth_priority = {
        name = each.value.rule.bandwidthPriority.name
      }
    } : {},

    # Dynamic exceptions block - only if exceptions exist
    try(length(each.value.rule.exceptions), 0) > 0 ? {
      exceptions = [
        for exception in each.value.rule.exceptions : merge(
          {
            name = exception.name
          },

          # Exception source - always required
          {
            source = {
              for k, v in {
                ip                  = try(length(exception.source.ip), 0) > 0 ? exception.source.ip : null
                host                = try(length(exception.source.host), 0) > 0 ? [for host in exception.source.host : can(host.name) ? { name = host.name } : { id = host.id }] : null
                site                = try(length(exception.source.site), 0) > 0 ? [for site in exception.source.site : can(site.name) ? { name = site.name } : { id = site.id }] : null
                users_group         = try(length(exception.source.usersGroup), 0) > 0 ? [for group in exception.source.usersGroup : can(group.name) ? { name = group.name } : { id = group.id }] : null
                network_interface   = try(length(exception.source.networkInterface), 0) > 0 ? [for ni in exception.source.networkInterface : can(ni.name) ? { name = ni.name } : { id = ni.id }] : null
                ip_range            = try(length(exception.source.ipRange), 0) > 0 ? [for range in exception.source.ipRange : {
                  from = range.from
                  to   = range.to
                }] : null
                floating_subnet     = try(length(exception.source.floatingSubnet), 0) > 0 ? [for subnet in exception.source.floatingSubnet : can(subnet.name) ? { name = subnet.name } : { id = subnet.id }] : null
                site_network_subnet = try(length(exception.source.siteNetworkSubnet), 0) > 0 ? [for subnet in exception.source.siteNetworkSubnet : can(subnet.name) ? { name = subnet.name } : { id = subnet.id }] : null
                system_group        = try(length(exception.source.systemGroup), 0) > 0 ? [for group in exception.source.systemGroup : can(group.name) ? { name = group.name } : { id = group.id }] : null
                group               = try(length(exception.source.group), 0) > 0 ? [for group in exception.source.group : can(group.name) ? { name = group.name } : { id = group.id }] : null
                user                = try(length(exception.source.user), 0) > 0 ? [for user in exception.source.user : can(user.name) ? { name = user.name } : { id = user.id }] : null
                subnet              = try(length(exception.source.subnet), 0) > 0 ? exception.source.subnet : null
                global_ip_range     = try(length(exception.source.globalIpRange), 0) > 0 ? [for range in exception.source.globalIpRange : can(range.name) ? { name = range.name } : { id = range.id }] : null
              } : k => v if v != null
            }
          },

          # Exception destination - always required
          {
            destination = {
              for k, v in {
                ip                  = try(length(exception.destination.ip), 0) > 0 ? exception.destination.ip : null
                host                = try(length(exception.destination.host), 0) > 0 ? [for host in exception.destination.host : can(host.name) ? { name = host.name } : { id = host.id }] : null
                site                = try(length(exception.destination.site), 0) > 0 ? [for site in exception.destination.site : can(site.name) ? { name = site.name } : { id = site.id }] : null
                users_group         = try(length(exception.destination.usersGroup), 0) > 0 ? [for group in exception.destination.usersGroup : can(group.name) ? { name = group.name } : { id = group.id }] : null
                network_interface   = try(length(exception.destination.networkInterface), 0) > 0 ? [for ni in exception.destination.networkInterface : can(ni.name) ? { name = ni.name } : { id = ni.id }] : null
                ip_range            = try(length(exception.destination.ipRange), 0) > 0 ? [for range in exception.destination.ipRange : {
                  from = range.from
                  to   = range.to
                }] : null
                floating_subnet     = try(length(exception.destination.floatingSubnet), 0) > 0 ? [for subnet in exception.destination.floatingSubnet : can(subnet.name) ? { name = subnet.name } : { id = subnet.id }] : null
                site_network_subnet = try(length(exception.destination.siteNetworkSubnet), 0) > 0 ? [for subnet in exception.destination.siteNetworkSubnet : can(subnet.name) ? { name = subnet.name } : { id = subnet.id }] : null
                system_group        = try(length(exception.destination.systemGroup), 0) > 0 ? [for group in exception.destination.systemGroup : can(group.name) ? { name = group.name } : { id = group.id }] : null
                group               = try(length(exception.destination.group), 0) > 0 ? [for group in exception.destination.group : can(group.name) ? { name = group.name } : { id = group.id }] : null
                user                = try(length(exception.destination.user), 0) > 0 ? [for user in exception.destination.user : can(user.name) ? { name = user.name } : { id = user.id }] : null
                subnet              = try(length(exception.destination.subnet), 0) > 0 ? exception.destination.subnet : null
                global_ip_range     = try(length(exception.destination.globalIpRange), 0) > 0 ? [for range in exception.destination.globalIpRange : can(range.name) ? { name = range.name } : { id = range.id }] : null
              } : k => v if v != null
            }
          },

          # Exception application - always required
          {
            application = {
              for k, v in {
                app_category = try(length(exception.application.appCategory), 0) > 0 ? [for cat in exception.application.appCategory : can(cat.name) ? { name = cat.name } : { id = cat.id }] : null

                application = try(length(exception.application.application), 0) > 0 ? [for app in exception.application.application : can(app.name) ? { name = app.name } : { id = app.id }] : null

                custom_app = try(length(exception.application.customApp), 0) > 0 ? [for app in exception.application.customApp : can(app.name) ? { name = app.name } : { id = app.id }] : null

                custom_category = try(length(exception.application.customCategory), 0) > 0 ? [for cat in exception.application.customCategory : can(cat.name) ? { name = cat.name } : { id = cat.id }] : null

                domain = try(length(exception.application.domain), 0) > 0 ? exception.application.domain : null

                fqdn = try(length(exception.application.fqdn), 0) > 0 ? exception.application.fqdn : null

                service = try(length(exception.application.service), 0) > 0 ? [for svc in exception.application.service : can(svc.name) ? { name = svc.name } : { id = svc.id }] : null

                custom_service = try(length(exception.application.customService), 0) > 0 ? [for svc in exception.application.customService : merge(
                  {
                    protocol = svc.protocol
                  },
                  try(length(svc.port), 0) > 0 ? {
                    port = [for p in svc.port : tostring(p)]
                  } : {},
                  try(svc.portRange, null) != null ? {
                    port_range = {
                      from = tostring(svc.portRange.from)
                      to   = tostring(svc.portRange.to)
                    }
                  } : {}
                )] : null

                custom_service_ip = try(length(exception.application.customServiceIp), 0) > 0 ? [for svc in exception.application.customServiceIp : merge(
                  {
                    name = svc.name
                  },
                  try(svc.ip, null) != null && svc.ip != "" ? {
                    ip = svc.ip
                  } : {},
                  try(svc.ipRange, null) != null ? {
                    ip_range = {
                      from = svc.ipRange.from
                      to   = svc.ipRange.to
                    }
                  } : {}
                )] : null
              } : k => v if v != null
            }
          }
        )
      ]
    } : {}
  )
}

resource "cato_bulk_wnw_move_rule" "all_wnw_rules" {
  depends_on                = [cato_wnw_section.sections, cato_wnw_rule.rules]
  rule_data                 = local.rules_data
  section_data              = local.sections_data
  section_to_start_after_id = var.section_to_start_after_id != null ? var.section_to_start_after_id : null
}
