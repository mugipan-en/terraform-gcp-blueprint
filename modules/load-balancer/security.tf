# Security policies (Cloud Armor)
resource "google_compute_security_policy" "security_policies" {
  for_each = var.security_policies

  name        = "${var.name_prefix}-${each.key}-security-policy"
  description = each.value.description

  dynamic "rule" {
    for_each = each.value.rules
    content {
      action   = rule.value.action
      priority = rule.value.priority

      dynamic "match" {
        for_each = rule.value.match != null ? [rule.value.match] : []
        content {
          versioned_expr = match.value.versioned_expr

          dynamic "config" {
            for_each = match.value.config != null ? [match.value.config] : []
            content {
              src_ip_ranges = config.value.src_ip_ranges
            }
          }

          dynamic "expr" {
            for_each = match.value.expr != null ? [match.value.expr] : []
            content {
              expression = expr.value.expression
            }
          }
        }
      }

      description = rule.value.description
    }
  }

  dynamic "adaptive_protection_config" {
    for_each = each.value.adaptive_protection_config != null ? [each.value.adaptive_protection_config] : []
    content {
      layer_7_ddos_defense_config {
        enable          = adaptive_protection_config.value.layer_7_ddos_defense_enable
        rule_visibility = adaptive_protection_config.value.layer_7_ddos_defense_rule_visibility
      }
    }
  }
}
