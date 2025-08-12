terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
      version = "3.8.1"
    }
    tls = {
      source = "hashicorp/tls"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
  required_version = ">= 0.13"
}
