# DNS Managed Zones
resource "google_dns_managed_zone" "zones" {
  for_each = var.dns_zones

  name        = "${var.name_prefix}-${each.key}"
  dns_name    = each.value.dns_name
  description = each.value.description
  visibility  = each.value.visibility

  # Private zone configuration
  dynamic "private_visibility_config" {
    for_each = each.value.visibility == "private" ? [each.value.private_visibility_config] : []
    content {
      dynamic "networks" {
        for_each = private_visibility_config.value.networks
        content {
          network_url = networks.value.network_url
        }
      }

      dynamic "gke_clusters" {
        for_each = private_visibility_config.value.gke_clusters
        content {
          gke_cluster_name = gke_clusters.value.gke_cluster_name
        }
      }
    }
  }

  # Forwarding configuration
  dynamic "forwarding_config" {
    for_each = each.value.forwarding_config != null ? [each.value.forwarding_config] : []
    content {
      dynamic "target_name_servers" {
        for_each = forwarding_config.value.target_name_servers
        content {
          ipv4_address    = target_name_servers.value.ipv4_address
          forwarding_path = target_name_servers.value.forwarding_path
        }
      }
    }
  }

  # Peering configuration
  dynamic "peering_config" {
    for_each = each.value.peering_config != null ? [each.value.peering_config] : []
    content {
      target_network {
        network_url = peering_config.value.target_network_url
      }
    }
  }

  # Reverse lookup configuration
  dynamic "reverse_lookup" {
    for_each = each.value.reverse_lookup ? [1] : []
    content {}
  }

  # Service directory configuration
  dynamic "service_directory_config" {
    for_each = each.value.service_directory_config != null ? [each.value.service_directory_config] : []
    content {
      namespace {
        namespace_url = service_directory_config.value.namespace_url
      }
    }
  }

  # DNSSEC configuration
  dynamic "dnssec_config" {
    for_each = each.value.dnssec_config != null ? [each.value.dnssec_config] : []
    content {
      state         = dnssec_config.value.state
      non_existence = dnssec_config.value.non_existence

      dynamic "default_key_specs" {
        for_each = dnssec_config.value.default_key_specs
        content {
          algorithm  = default_key_specs.value.algorithm
          key_length = default_key_specs.value.key_length
          key_type   = default_key_specs.value.key_type
        }
      }
    }
  }

  # Cloud logging configuration
  dynamic "cloud_logging_config" {
    for_each = each.value.cloud_logging_config != null ? [each.value.cloud_logging_config] : []
    content {
      enable_logging = cloud_logging_config.value.enable_logging
    }
  }

  labels = merge(var.tags, each.value.labels)
}

# DNS Record Sets
resource "google_dns_record_set" "records" {
  for_each = var.dns_records

  name         = each.value.name
  managed_zone = google_dns_managed_zone.zones[each.value.zone_key].name
  type         = each.value.type
  ttl          = each.value.ttl
  rrdatas      = each.value.rrdatas

  depends_on = [google_dns_managed_zone.zones]
}

# DNS Policies
resource "google_dns_policy" "policies" {
  for_each = var.dns_policies

  name                      = "${var.name_prefix}-${each.key}"
  enable_inbound_forwarding = each.value.enable_inbound_forwarding
  enable_logging            = each.value.enable_logging
  description               = each.value.description

  # Networks
  dynamic "networks" {
    for_each = each.value.networks
    content {
      network_url = networks.value.network_url
    }
  }

  # Alternative name servers
  dynamic "alternative_name_server_config" {
    for_each = each.value.alternative_name_server_config != null ? [each.value.alternative_name_server_config] : []
    content {
      dynamic "target_name_servers" {
        for_each = alternative_name_server_config.value.target_name_servers
        content {
          ipv4_address    = target_name_servers.value.ipv4_address
          forwarding_path = target_name_servers.value.forwarding_path
        }
      }
    }
  }
}

# DNS Response Policies
resource "google_dns_response_policy" "response_policies" {
  for_each = var.dns_response_policies

  response_policy_name = "${var.name_prefix}-${each.key}"
  description          = each.value.description

  # Networks
  dynamic "networks" {
    for_each = each.value.networks
    content {
      network_url = networks.value.network_url
    }
  }

  # GKE clusters
  dynamic "gke_clusters" {
    for_each = each.value.gke_clusters
    content {
      gke_cluster_name = gke_clusters.value.gke_cluster_name
    }
  }
}

# DNS Response Policy Rules
resource "google_dns_response_policy_rule" "response_policy_rules" {
  for_each = var.dns_response_policy_rules

  response_policy = google_dns_response_policy.response_policies[each.value.response_policy_key].response_policy_name
  rule_name       = each.key
  dns_name        = each.value.dns_name

  # Local data
  dynamic "local_data" {
    for_each = each.value.local_data != null ? [each.value.local_data] : []
    content {
      dynamic "local_datas" {
        for_each = local_data.value.local_datas
        content {
          name    = local_datas.value.name
          type    = local_datas.value.type
          ttl     = local_datas.value.ttl
          rrdatas = local_datas.value.rrdatas
        }
      }
    }
  }

  # Behavior
  behavior = each.value.behavior
}
