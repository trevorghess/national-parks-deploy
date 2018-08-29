output "instance_ips" {
  value = ["${azurerm_public_ip.pip.*.ip_address}"]
}

output "lb_ip" {
  value = ["${azurerm_public_ip.vmsspip.*.ip_address}"]
}
