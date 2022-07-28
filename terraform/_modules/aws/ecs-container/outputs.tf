output "json_map_object" {
  description = "JSON map encoded container definition"
  value       = jsondecode(local.json_map)
}