variable "cluster_context" {
	type = string
}

variable "oci_repo_username" {
	type = string
}
variable "oci_repo_password" {
	type      = string
	sensitive = true
}

variable "one_password_operator_token" {
	type      = string
	sensitive = true
}

variable "one_password_credentials_file" {
	type        = string
	description = "Path to 1password credentials file"
}

variable "one_password_namespace" {
	type        = string
	description = "1password namespace"
	default     = "onepassword"
}


variable "cert_manager_namespace" {
	type        = string
	description = "cert-manager namespace"
	default     = "cert-manager"
}


variable "rook_namespace" {
	type        = string
	description = "rook-ceph namespace"
	default     = "rook-ceph"
}


variable "metrics_namespace" {
	type        = string
	description = "prometheus metrics namespace"
	default     = "metrics"
}


variable "jetbrains_namespace" {
	type        = string
	description = "Jetbrains namespace"
	default     = "jetbrains"
}