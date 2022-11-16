resource "kubernetes_namespace" "traefik" {
	metadata {
		name = "traefik"
	}
}

resource "helm_release" "traefik" {
	name       = "traefik"
	repository = "https://helm.traefik.io/traefik"
	chart      = "traefik"
	namespace  = "traefik"
	version    = "20.2.0"

	set {
		name  = "image.tag"
		value = "v2.9.4"
	}

	set {
		name  = "ports.web.redirectTo"
		value = "websecure"
	}

	set {
		name  = "ports.gitea-ssh.port"
		value = "55222"
	}
	set {
		name  = "ports.gitea-ssh.expose"
		value = "true"
	}
}

resource "kubernetes_service" "traefik_api" {
	metadata {
		name      = "traefik-api"
		namespace = "traefik"
	}
	spec {
		type = "ClusterIP"

		selector = {
			"app.kubernetes.io/instance" = "traefik-traefik"
			"app.kubernetes.io/name"     = "traefik"
		}

		port {
			port        = 9000
			name        = "traefik"
			target_port = 9000
			protocol    = "TCP"
		}
	}
}