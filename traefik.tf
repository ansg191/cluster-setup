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
	version    = "20.8.0"

	set {
		name  = "image.tag"
		value = "v2.9.6"
	}

	# http -> https redirect
	set {
		name  = "ports.web.redirectTo"
		value = "websecure"
	}

	# Git SSH entrypoint
	set {
		name  = "ports.gitea-ssh.port"
		value = "55222"
	}
	set {
		name  = "ports.gitea-ssh.expose"
		value = "true"
	}

	# FRPS entrypoint
	set {
		name  = "ports.frps.port"
		value = "58000"
	}
	set {
		name  = "ports.frps.expose"
		value = "true"
	}

	# SOCKS5 Proxy entrypoint
	set {
		name  = "ports.proxy.port"
		value = "51080"
	}
	set {
		name  = "ports.proxy.expose"
		value = "true"
	}

	# For TLS Verification: allows traefik to call services by their internal DNS name
	set {
		name  = "providers.kubernetesCRD.allowExternalNameServices"
		value = "true"
	}

	# Allows Cross Namespace References
	set {
		name  = "providers.kubernetesCRD.allowCrossNamespace"
		value = "true"
	}

	# Logging Level
	set {
		name  = "logs.general.level"
		value = "ERROR"
	}

	# DDog Metrics
	set {
		name  = "metrics.datadog.address"
		value = "datadog.ddog.svc.cluster.local:8125"
	}

	# DDog Tracing
	set {
		name  = "tracing.datadog.localAgentHostPort"
		value = "datadog.ddog.svc.cluster.local:8126"
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