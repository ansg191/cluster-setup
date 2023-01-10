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
	version    = "1.10.1"

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

resource "kubernetes_namespace" "step-ca" {
	metadata {
		name = "step-ca"
	}
}

resource "helm_release" "step-ca" {
	name  = "step-ca"
	repository = "https://smallstep.github.io/helm-charts/"
	chart = "step-certificates"
	version = "1.23.0"
	namespace = kubernetes_namespace.step-ca.metadata[0].name

	values = [
		sensitive(file("files/values.yaml"))
	]

	set_sensitive {
		name  = "inject.secrets.ca_password"
		value = base64encode(var.step_ci_password)
	}
	set_sensitive {
		name  = "inject.secrets.provisioner_password"
		value = base64encode(var.step_ci_password)
	}

	set {
		name  = "service.targetPort"
		value = "443"
	}
}

resource "kubernetes_manifest" "ca-ingress" {
	manifest = {
		"apiVersion" = "traefik.containo.us/v1alpha1"
		"kind"       = "IngressRouteTCP"
		"metadata" = {
			"name"      = "ca-ingress"
			"namespace" = kubernetes_namespace.step-ca.metadata[0].name
		}
		"spec" = {
			"entryPoints" = [
				"websecure"
			]
			"routes" = [{
				"match" = "HostSNI(`ca.anshulg.com`)"
				"services" = [{
					"name" = "step-ca-step-certificates"
					"port" = 443
				}]
			}]
			"tls" = {
				"passthrough" = true
			}
		}
	}
}

resource "helm_release" "step-issuer" {
	name  = "step-issuer"
	repository = "https://smallstep.github.io/helm-charts"
	chart = "step-issuer"
	version = "0.6.7"
	namespace = kubernetes_namespace.step-ca.metadata[0].name
}

resource "kubernetes_manifest" "step-issuer" {
	manifest = {
		"apiVersion" = "certmanager.step.sm/v1beta1"
		"kind"       = "StepClusterIssuer"
		"metadata" = {
			"name" = "step-anshulg-issuer"
		}
		"spec" = {
			"url" = "https://step-ca-step-certificates.step-ca.svc.cluster.local"
			"caBundle" = filebase64("files/ca.crt")
			"provisioner" = {
				"name" = "ansg191@anshulg.com"
				"kid" = var.step_ci_kid
				"passwordRef" = {
					"name" = "step-ca-step-certificates-provisioner-password"
					"namespace" = "step-ca"
					"key" = "password"
				}
			}
		}
	}

	depends_on = [
		helm_release.step-ca,
		helm_release.step-issuer
	]
}