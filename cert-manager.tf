resource "kubernetes_namespace" "cert_manager" {
	metadata {
		name = var.cert_manager_namespace
	}
}

resource "helm_release" "cert_manager" {
	name       = "cert-manager"
	repository = "https://charts.jetstack.io"
	chart      = "cert-manager"
	namespace  = var.cert_manager_namespace

	set {
		name  = "installCRDs"
		value = "true"
	}

	depends_on = [
		kubernetes_namespace.cert_manager
	]
}

resource "kubernetes_manifest" "letsencrypt" {
	manifest = {
		"apiVersion" = "cert-manager.io/v1"
		"kind"       = "ClusterIssuer"
		"metadata" = {
			"name" = "letsencrypt-staging"
		}
		"spec" = {
			"acme" = {
				"email" = "ansg191@gmail.com"
				"server" = "https://acme-staging-v02.api.letsencrypt.org/directory"
				"privateKeySecretRef" = {
					"name" = "letsencrypt-staging"
				}
				"solvers" = [{
					"http01" = {
						"ingress" = {
							"class" = "traefik"
						}
					}
				}]
			}
		}
	}

	depends_on = [
		helm_release.cert_manager
	]
}

resource "kubernetes_manifest" "letsencrypt_prod" {
	manifest = {
		"apiVersion" = "cert-manager.io/v1"
		"kind"       = "ClusterIssuer"
		"metadata" = {
			"name" = "letsencrypt-prod"
		}
		"spec" = {
			"acme" = {
				"email" = "ansg191@gmail.com"
				"server" = "https://acme-v02.api.letsencrypt.org/directory"
				"privateKeySecretRef" = {
					"name" = "letsencrypt-prod"
				}
				"solvers" = [{
					"http01" = {
						"ingress" = {
							"class" = "traefik"
						}
					}
				}]
			}
		}
	}

	depends_on = [
		helm_release.cert_manager
	]
}