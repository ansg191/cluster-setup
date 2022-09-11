resource "kubernetes_namespace" "verdaccio" {
	metadata {
		name = "verdaccio"
	}
}

resource "random_password" "verdaccio_pwd" {
	length  = 24
	special = false
}

output "verdaccio_password" {
	value     = random_password.verdaccio_pwd.result
	sensitive = true
}

resource "helm_release" "verdaccio" {
	name       = "verdaccio"
	repository = "https://charts.verdaccio.org"
	chart      = "verdaccio"
	namespace  = "verdaccio"

	set {
		name  = "ingress.enabled"
		value = "true"
	}
	set {
		name  = "ingress.hosts"
		value = "{npm.anshulg.com}"
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
		value = "npm.anshulg.com"
	}
	set {
		name  = "ingress.tls[0].hosts"
		value = "{npm.anshulg.com}"
	}

	set {
		name  = "extraEnvVars[0].name"
		value = "VERDACCIO_PORT"
	}
	set {
		name  = "extraEnvVars[0].value"
		value = "4873"
		type  = "string"
	}

	set {
		name  = "secrets.htpasswd[0].username"
		value = "ansg191"
	}
	set_sensitive {
		name  = "secrets.htpasswd[0].password"
		value = random_password.verdaccio_pwd.result
	}

	depends_on = [
		kubernetes_manifest.verdaccio_certificate
	]
}

resource "kubernetes_manifest" "verdaccio_certificate" {
	manifest = {
		"apiVersion" = "cert-manager.io/v1"
		"kind"       = "Certificate"
		"metadata"   = {
			"name"      = "npm.anshulg.com"
			"namespace" = "verdaccio"
		}
		"spec" = {
			"secretName" = "npm.anshulg.com"
			"issuerRef"  = {
				"name" = "letsencrypt-prod"
				"kind" = "ClusterIssuer"
			}
			"commonName" = "npm.anshulg.com"
			"dnsNames"   = ["npm.anshulg.com"]
		}
	}
}