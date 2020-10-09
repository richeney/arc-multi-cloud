output "workspace_id" {
  value = azurerm_log_analytics_workspace.arc.workspace_id
}

output "workspace_key" {
  value = azurerm_log_analytics_workspace.arc.primary_shared_key
}

/*
output "public_ip" {
  value = concat(module.aws[*].public_ip, module.gcp[*].public_ip)
}
*/


output "test" {
  value = module.aws["aws-arc-01"]
}
