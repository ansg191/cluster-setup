resource "kubernetes_namespace" "ci" {
	metadata {
		name = "ci"
	}
}

resource "random_password" "drone_rpc" {
	length  = 16
	special = false
}

resource "helm_release" "drone" {
	name       = "drone"
	repository = "https://charts.drone.io"
	chart      = "drone"
	namespace  = "ci"

	set {
		name  = "ingress.enabled"
		value = "true"
	}
	set {
		name  = "ingress.hosts[0].host"
		value = "ci.anshulg.com"
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
		value = "ci.anshulg.com"
	}
	set {
		name  = "ingress.tls[0].hosts"
		value = "{ci.anshulg.com}"
	}

	set {
		name  = "env.DRONE_SERVER_HOST"
		value = "ci.anshulg.com"
	}
	set {
		name  = "env.DRONE_SERVER_PROTO"
		value = "https"
	}
	set_sensitive {
		name  = "env.DRONE_RPC_SECRET"
		value = random_password.drone_rpc.result
	}

	set {
		name  = "env.DRONE_GITEA_CLIENT_ID"
		value = var.gitea_drone_client_id
	}
	set_sensitive {
		name  = "env.DRONE_GITEA_CLIENT_SECRET"
		value = var.gitea_drone_client_secret
	}
	set {
		name  = "env.DRONE_GITEA_SERVER"
		value = "https://git.anshulg.com"
	}

	depends_on = [
		kubernetes_namespace.ci,
		kubernetes_manifest.ci_certificate,
	]
}

resource "kubernetes_manifest" "ci_certificate" {
	manifest = {
		"apiVersion" = "cert-manager.io/v1"
		"kind"       = "Certificate"
		"metadata"   = {
			"name"      = "ci.anshulg.com"
			"namespace" = "ci"
		}
		"spec" = {
			"secretName" = "ci.anshulg.com"
			"issuerRef"  = {
				"name" = "letsencrypt-prod"
				"kind" = "ClusterIssuer"
			}
			"commonName" = "ci.anshulg.com"
			"dnsNames"   = ["ci.anshulg.com"]
		}
	}

	depends_on = [
		kubernetes_namespace.ci,
		helm_release.cert_manager
	]
}

resource "helm_release" "drone-kube" {
	name       = "drone-runner-kube"
	repository = "https://charts.drone.io"
	chart      = "drone-runner-kube"
	namespace  = "ci"

	set {
		name  = "rbac.buildNamespaces"
		value = "{ci}"
	}
	set {
		name  = "env.DRONE_NAMESPACE_DEFAULT"
		value = "ci"
	}
	set_sensitive {
		name  = "env.DRONE_RPC_SECRET"
		value = random_password.drone_rpc.result
	}
	set {
		name  = "env.DRONE_RPC_HOST"
		value = "ci.anshulg.com"
	}
	set {
		name  = "env.DRONE_RPC_PROTO"
		value = "https"
	}

	depends_on = [
		helm_release.drone
	]
}