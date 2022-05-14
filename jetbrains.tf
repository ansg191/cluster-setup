resource "kubernetes_namespace" "jetbrains" {
	metadata {
		name = local.jb_namespace
	}
}

locals {
	jb_namespace = var.jetbrains_namespace
}

resource "helm_release" "teamcity" {
	name       = "teamcity"
	repository = "oci://anshulg.registry.jetbrains.space/p/shared/charts"
	chart      = "teamcity"
	namespace = local.jb_namespace

	repository_username = var.oci_repo_username
	repository_password = var.oci_repo_password

	set {
		name  = "ingress.env"
		value = "prod"
	}

	depends_on = [
		kubernetes_namespace.jetbrains
	]
}