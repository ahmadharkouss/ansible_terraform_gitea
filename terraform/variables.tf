variable "gitea_admin" {
  type        = string
  description = "Admin username for Gitea"
}

variable "gitea_db_name" {
  type        = string
  description = "Database name for Gitea"
}

variable "gitea_hostname_env" {
  type        = string
  description = "Hostname for Gitea (used for Traefik routing)"
}

variable "gitea_instance_url" {
  type        = string
  description = "URL for Gitea Container instance"
}