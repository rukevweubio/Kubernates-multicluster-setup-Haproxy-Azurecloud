# 🌍 Public IP outputs
output "haproxy_public_ip" {
  value = azurerm_public_ip.haproxy_pip.ip_address
}

output "master_public_ips" {
  value = [for ip in azurerm_public_ip.masters_pip : ip.ip_address]
}

output "worker_public_ips" {
  value = [for ip in azurerm_public_ip.workers_pip : ip.ip_address]
}

# 🔒 Private IP outputs
output "haproxy_private_ip" {
  value = azurerm_network_interface.haproxy_nic.private_ip_address
}

output "master_private_ips" {
  value = [for nic in azurerm_network_interface.master_nic : nic.private_ip_address]
}

output "worker_private_ips" {
  value = [for nic in azurerm_network_interface.worker_nic : nic.private_ip_address]
}
