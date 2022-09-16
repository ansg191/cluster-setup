resource "kubernetes_namespace" "gitea" {
	metadata {
		name = "gitea"
	}
}

resource "random_password" "gitea_admin_pwd" {
	length  = 24
	special = true
	override_special = "!#$%*()-_=+[]{}<>:?"
}

output "gitea_admin_password" {
	value     = random_password.gitea_admin_pwd.result
	sensitive = true
}

resource "helm_release" "gitea" {
	name       = "gitea"
	repository = "https://dl.gitea.io/charts/"
	chart      = "gitea"
	namespace  = "gitea"

	set {
		name  = "ingress.enabled"
		value = "true"
	}
	set {
		name  = "ingress.hosts[0].host"
		value = "git.anshulg.com"
	}
	set {
		name  = "ingress.hosts[0].paths[0].path"
		value = "/"
	}
	set {
		name  = "ingress.hosts[0].paths[0].pathType"
		value = "Prefix"
	}
	set {
		name  = "ingress.annotations.kubernetes\\.io/ingress\\.class"
		value = "traefik"
	}
	set {
		name  = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.entrypoints"
		value = "websecure"
	}
	set {
		name  = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.tls"
		value = "true"
		type  = "string"
	}
	set {
		name  = "ingress.tls[0].secretName"
		value = "git.anshulg.com"
	}
	set {
		name  = "ingress.tls[0].hosts"
		value = "{git.anshulg.com}"
	}

	set {
		name  = "gitea.admin.username"
		value = "ansg191"
	}
	set_sensitive {
		name  = "gitea.admin.password"
		value = random_password.gitea_admin_pwd.result
	}
	set {
		name  = "gitea.admin.email"
		value = "ansg191@yahoo.com"
	}

	set {
		name  = "signing.enabled"
		value = "true"
	}

	depends_on = [
		kubernetes_manifest.gitea_certificate
	]
}

resource "kubernetes_manifest" "gitea_ssh_ingress" {
	manifest = {
		"apiVersion" = "traefik.containo.us/v1alpha1"
		"kind"       = "IngressRouteTCP"
		"metadata"   = {
			"name"      = "gitea-ssh"
			"namespace" = "gitea"
		}
		"spec" = {
			"entryPoints" = ["gitea-ssh"]
			"routes"      = [
				{
					"match"    = "HostSNI(`*`)"
					"services" = [
						{
							"name" = "gitea-ssh"
							"port" = 22
						}
					]
				}
			]
		}
	}

	depends_on = [
		helm_release.traefik,
		helm_release.gitea
	]
}

resource "kubernetes_manifest" "gitea_certificate" {
	manifest = {
		"apiVersion" = "cert-manager.io/v1"
		"kind"       = "Certificate"
		"metadata"   = {
			"name"      = "git.anshulg.com"
			"namespace" = "gitea"
		}
		"spec" = {
			"secretName" = "git.anshulg.com"
			"issuerRef"  = {
				"name" = "letsencrypt-prod"
				"kind" = "ClusterIssuer"
			}
			"commonName" = "git.anshulg.com"
			"dnsNames"   = ["git.anshulg.com"]
		}
	}

	depends_on = [
		helm_release.cert_manager
	]
}