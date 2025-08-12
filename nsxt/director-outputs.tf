
locals {
  director_vars = {
    "bosh_disk_path"              = "${var.environment_name}_pcf_disk"
    "bosh_template_folder"        = "${var.environment_name}_pcf_templates"
    "bosh_vm_folder"              = "${var.environment_name}_pcf_vms"
    "datacenter"                  = "tpk_vc01_dc"
    "deploy_network_name"         = nsxt_policy_segment.deployment_sg.display_name
    "ephemeral_datastores_string" = "CL01_vsanDatastore"
    "iaas" = {
      "nsx_password" = "VMware12345!"
      "nsx_username" = "admin"
    }
    "infra_network_name" = nsxt_policy_segment.infrastructure_sg.display_name
    "nsx" = {
      "ca_cert"         = ""
      "cert_pem"        = ""
      "private_key_pem" = ""
      "url"             = "10.160.143.80"
    }
    "nsx_mode"                     = "nsx-t"
    "nsx_networking_enabled"       = true
    "ops_manager_dns"              = "${var.environment_name}-ops-manager.tpk.lvn.broadcom.net"
    "opsman_decryption_passphrase" = ""
    "opsman_url"                   = "${var.environment_name}-ops-manager.tpk.lvn.broadcom.net"
    "opsman_user" = {
      "password" = "<PASSWORD>"
      "username" = "admin"
    }
    "persistent_datastores_string" = "CL01_vsanDatastore"
    "pks_api_url"                  = ""
    "pks_tls" = {
      "cert_pem"        = ""
      "private_key_pem" = ""
    }
    "rsc_pool_name"            = "${var.environment_name}-rp"
    "service_network_name"     = nsxt_policy_segment.service_sg.display_name
    "ssl_verification_enabled" = false
    "vcenter_url"              = "tpe-tpk-vc01.lvn.broadcom.net"
    "vcenter_user" = {
      "password" = "<PASSWORD>"
      "username" = "tpk-eso@vsphere.local"
    }
  }
}


output "director_vars" {
  value = yamlencode(local.director_vars)
  sensitive = true
}
