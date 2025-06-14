# Global IP addresses
resource "google_compute_global_address" "global_ips" {
  for_each = var.global_load_balancers

  name         = "${var.name_prefix}-${each.key}-ip"
  ip_version   = each.value.ip_version
  address_type = "EXTERNAL"
}

# Regional IP addresses
resource "google_compute_address" "regional_ips" {
  for_each = var.regional_load_balancers

  name         = "${var.name_prefix}-${each.key}-ip"
  region       = each.value.region
  address_type = "EXTERNAL"
}
