locals {
  stable_config_pas = {
    lb_pool_web = nsxt_policy_lb_pool.pas-web.display_name
    lb_pool_tcp = nsxt_policy_lb_pool.pas-tcp.display_name
    lb_pool_ssh = nsxt_policy_lb_pool.pas-ssh.display_name
  }
  tas_vars = {
    "apps_domain" = "app-${var.environment_name}.tpk.lvn.broadcom.net"
    "credhub_key_encryption_password_secret" = "abcdefghijklmnopqrstuvwxyz"
    "custom_ca_certificate" = {
      "certificate" = tls_self_signed_cert.ca_cert.cert_pem
    }
    "mysql_monitor_recipient_email" = "noreply-development@vmware.com"
    "networking_poe_ssl_app_cert" = {
      "certificate" = tls_locally_signed_cert.app_server_cert.cert_pem
      "private_key" = tls_private_key.app_server_key.private_key_pem
    }
    "networking_poe_ssl_sys_cert" = {
      "certificate" = tls_locally_signed_cert.sys_server_cert.cert_pem
      "private_key" = tls_private_key.sys_server_key.private_key_pem
    }
    "other_az" = "deploy-az"
    "rsc_pool_name" = "${var.environment_name}-rp"
    "service_provider_key" = {
      "certificate" = tls_locally_signed_cert.login_server_cert.cert_pem
      "private_key" = tls_private_key.login_server_key.private_key_pem
    }

    "singleton_az": "deploy-az"
    "system_domain": "system-${var.environment_name}.tpk.lvn.broadcom.net"
    "vsphere_tas_network": "deploy-network"
  }
}

output "stable_config_pas" {
  value = jsonencode(local.stable_config_pas)
  sensitive = true
}

output "tas_vars" {
  value = yamlencode(local.tas_vars)
  sensitive = true
}



