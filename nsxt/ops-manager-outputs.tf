locals {
  stable_config_opsmanager = {
    environment_name = var.environment_name
    
    nsxt_host     = var.nsxt_host
    nsxt_username = var.nsxt_username
    nsxt_password = var.nsxt_password
    nsxt_ca_cert  = var.nsxt_ca_cert

    vcenter_datacenter    = var.vcenter_datacenter
    vcenter_datastore     = var.vcenter_datastore
    vcenter_host          = var.vcenter_host
    vcenter_username      = var.vcenter_username
    vcenter_password      = var.vcenter_password
    vcenter_resource_pool = var.vcenter_resource_pool
    vcenter_cluster       = var.vcenter_cluster

    ops_manager_ntp             = var.ops_manager_ntp
    ops_manager_netmask         = var.ops_manager_netmask
    ops_manager_dns             = var.ops_manager_dns
    ops_manager_dns_servers     = var.ops_manager_dns_servers
    ops_manager_folder          = var.ops_manager_folder
    ops_manager_ssh_public_key  = tls_private_key.ops-manager.public_key_openssh
    ops_manager_ssh_private_key = tls_private_key.ops-manager.private_key_pem
    ops_manager_public_ip       = var.ops_manager_public_ip
    ops_manager_private_ip      = nsxt_policy_nat_rule.dnat_om.translated_networks[0]

    management_subnet_name               = nsxt_policy_segment.infrastructure_sg.display_name
    management_subnet_cidr               = "${var.infra_management_subnet}"
    management_subnet_gateway            = "${var.infra_management_gateway}"
    management_subnet_reserved_ip_ranges = "${var.infra_management_reserved_ip_start}-${var.infra_management_reserved_ip_end}"

    allow_unverified_ssl      = var.allow_unverified_ssl
    disable_ssl_verification  = !var.allow_unverified_ssl
  }
}

output "stable_config_opsmanager" {
  value     = jsonencode(local.stable_config_opsmanager)
  sensitive = true
}
