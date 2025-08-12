data "nsxt_policy_lb_monitor" "pas-web" {
  type = "HTTP"
  display_name          = "vasanth-monitor"
}
data "nsxt_policy_lb_monitor" "pas-tcp" {
  type = "HTTP"
  display_name          = "sk-ops-manager-web-hm"
}
data "nsxt_policy_lb_monitor" "pas-ssh" {
  type = "TCP"
  display_name          = "default-tcp-lb-monitor"
}

resource "nsxt_policy_lb_pool" "pas-web" {
  description              = "The Server Pool of Web (HTTP(S)) traffic handling VMs"
  display_name             = "${var.environment_name}-pas-web-pool"
  algorithm                = "ROUND_ROBIN"
  tcp_multiplexing_enabled = false
  active_monitor_paths     = [data.nsxt_policy_lb_monitor.pas-web.path]
  snat {
    type = "AUTOMAP"
  }
  tag {
    scope = "terraform"
    tag   = var.environment_name
  }
}

resource "nsxt_policy_lb_pool" "pas-tcp" {
  description              = "The Server Pool of TCP traffic handling VMs"
  display_name             = "${var.environment_name}-pas-tcp-pool"
  algorithm                = "ROUND_ROBIN"
  tcp_multiplexing_enabled = false
  active_monitor_paths     = [data.nsxt_policy_lb_monitor.pas-tcp.path]
  snat {
    type = "DISABLED"
  }
  tag {
    scope = "terraform"
    tag   = var.environment_name
  }
}

resource "nsxt_policy_lb_pool" "pas-ssh" {
  description              = "The Server Pool of SSH traffic handling VMs"
  display_name             = "${var.environment_name}-pas-ssh-pool"
  algorithm                = "ROUND_ROBIN"
  tcp_multiplexing_enabled = false
  active_monitor_paths     = [data.nsxt_policy_lb_monitor.pas-ssh.path]
  snat {
    type = "DISABLED"
  }
  tag {
    scope = "terraform"
    tag   = var.environment_name
  }
}

# for the policy API we just use the default profile that is installed with
# NSXT as it appears to offer the same timeout values as the one we used to
# create.
data "nsxt_policy_lb_app_profile" "pas_lb_tcp_application_profile" {
  display_name  = "default-tcp-lb-app-profile"
}

resource "nsxt_policy_lb_virtual_server" "lb_web_virtual_server" {
  description            = "The Virtual Server for Web (HTTP(S)) traffic"
  display_name           = "${var.environment_name}-pas-web-vs"
  application_profile_path = data.nsxt_policy_lb_app_profile.pas_lb_tcp_application_profile.path
  ip_address             = var.nsxt_lb_web_virtual_server_ip_address
  ports                  = ["443"]
  pool_path                = nsxt_policy_lb_pool.pas-web.path
  service_path = nsxt_policy_lb_service.pas_lb.path

  tag {
    scope = "terraform"
    tag   = var.environment_name
  }
}

resource "nsxt_policy_lb_virtual_server" "lb_tcp_virtual_server" {
  description            = "The Virtual Server for TCP traffic"
  display_name           = "${var.environment_name}-pas-tcp-vs"
  application_profile_path = data.nsxt_policy_lb_app_profile.pas_lb_tcp_application_profile.path
  ip_address             = var.nsxt_lb_tcp_virtual_server_ip_address
  ports                  = var.nsxt_lb_tcp_virtual_server_ports
  pool_path                = nsxt_policy_lb_pool.pas-tcp.path
  service_path = nsxt_policy_lb_service.pas_lb.path

  tag {
    scope = "terraform"
    tag   = var.environment_name
  }
}

resource "nsxt_policy_lb_virtual_server" "lb_ssh_virtual_server" {
  description            = "The Virtual Server for SSH traffic"
  display_name           = "${var.environment_name}-pas-ssh-vs"
  application_profile_path = data.nsxt_policy_lb_app_profile.pas_lb_tcp_application_profile.path
  ip_address             = var.nsxt_lb_ssh_virtual_server_ip_address
  ports                  = ["2222"]
  pool_path                = nsxt_policy_lb_pool.pas-ssh.path
  service_path = nsxt_policy_lb_service.pas_lb.path

  tag {
    scope = "terraform"
    tag   = var.environment_name
  }
}

resource "nsxt_policy_lb_service" "pas_lb" {
  description  = "The Load Balancer for handling Web (HTTP(S)), TCP, and SSH traffic."
  display_name = "${var.environment_name}-pas-lb"
  enabled           = true
  connectivity_path = nsxt_policy_tier1_gateway.t1_deployment.path
  size              = "SMALL"
  depends_on = [
    nsxt_policy_segment.infrastructure_sg,
    nsxt_policy_segment.deployment_sg,
  ]

  tag {
    scope = "terraform"
    tag   = var.environment_name
  }
}


# certificate for TAS

resource "tls_private_key" "ca_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "ca_cert" {
  private_key_pem = tls_private_key.ca_key.private_key_pem

  subject {
    common_name  = "tpk.lvn.broadcom.net"
    organization = "Broadcom"
  }

  validity_period_hours = 87600 # 10 years
  is_ca_certificate      = true

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
  ]
}

resource "tls_private_key" "sys_server_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "sys_server_csr" {
  private_key_pem = tls_private_key.sys_server_key.private_key_pem

  subject {
    common_name  = "*.system-${var.environment_name}.tpk.lvn.broadcom.net"
    organization = "Broadcom"
  }

  dns_names = ["*.system-${var.environment_name}.tpk.lvn.broadcom.net"]
}

resource "tls_locally_signed_cert" "sys_server_cert" {
  cert_request_pem = tls_cert_request.sys_server_csr.cert_request_pem
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 8760  # 1 year
  allowed_uses = [
    "server_auth",
    "key_encipherment",
    "digital_signature",
  ]
}

resource "tls_private_key" "app_server_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "app_server_csr" {
  private_key_pem = tls_private_key.app_server_key.private_key_pem

  subject {
    common_name  = "*.app-${var.environment_name}.tpk.lvn.broadcom.net"
    organization = "Broadcom"
  }

  dns_names = ["*.app-${var.environment_name}.tpk.lvn.broadcom.net"]
}

resource "tls_locally_signed_cert" "app_server_cert" {
  cert_request_pem = tls_cert_request.app_server_csr.cert_request_pem
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 8760  # 1 year
  allowed_uses = [
    "server_auth",
    "key_encipherment",
    "digital_signature",
  ]
}


resource "tls_private_key" "login_server_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "login_server_csr" {
  private_key_pem = tls_private_key.login_server_key.private_key_pem

  subject {
    common_name  = "*.login.system-${var.environment_name}.tpk.lvn.broadcom.net"
    organization = "Broadcom"
  }

  dns_names = ["*.login.system-${var.environment_name}.tpk.lvn.broadcom.net"]
}

resource "tls_locally_signed_cert" "login_server_cert" {
  cert_request_pem = tls_cert_request.login_server_csr.cert_request_pem
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 8760  # 1 year
  allowed_uses = [
    "server_auth",
    "key_encipherment",
    "digital_signature",
  ]
}
