resource "kubernetes_namespace" "proxy" {
	metadata {
		name = "proxy"
	}
}

resource "kubernetes_manifest" "gke_proxy_login" {
	manifest = {
		"apiVersion" = "onepassword.com/v1"
		"kind"       = "OnePasswordItem"
		"metadata"   = {
			"name"      = "gke-proxy-login"
			"namespace" = kubernetes_namespace.proxy.metadata[0].name
		}
		"spec" = {
			"itemPath" = "vaults/Dev/items/GKE Socks5 Proxy"
		}
	}

	depends_on = [helm_release.one_password]
}

resource "kubernetes_deployment" "proxy" {
	metadata {
		name      = "proxy"
		namespace = kubernetes_namespace.proxy.metadata[0].name
		labels    = {
			"app.kubernetes.io/name" = "proxy"
		}
	}
	spec {
		replicas = "1"
		selector {
			match_labels = {
				"app.kubernetes.io/name" = "proxy"
			}
		}
		template {
			metadata {
				name   = "proxy"
				labels = {
					"app.kubernetes.io/name" = "proxy"
				}
			}
			spec {
				restart_policy = "Always"
				container {
					name              = "proxy"
					image             = "serjs/go-socks5-proxy"
					image_pull_policy = "IfNotPresent"

					port {
						name           = "proxy"
						container_port = 1080
						protocol       = "TCP"
					}

					env {
						name = "PROXY_USER"
						value_from {
							secret_key_ref {
								name = "gke-proxy-login"
								key  = "username"
							}
						}
					}
					env {
						name = "PROXY_PASSWORD"
						value_from {
							secret_key_ref {
								name = "gke-proxy-login"
								key  = "password"
							}
						}
					}
					env {
						name  = "PROXY_PORT"
						value = "1080"
					}
				}
			}
		}
	}

	depends_on = [kubernetes_manifest.gke_proxy_login]
}

resource "kubernetes_service" "proxy" {
	metadata {
		name      = "proxy"
		namespace = kubernetes_namespace.proxy.metadata[0].name
		labels    = {
			"app.kubernetes.io/name" = "proxy"
		}
	}
	spec {
		selector = {
			"app.kubernetes.io/name" = "proxy"
		}
		port {
			name        = "proxy"
			port        = 1080
			target_port = "proxy"
			protocol    = "TCP"
		}
	}
}

resource "kubernetes_manifest" "proxy_ingress" {
	manifest = {
		"apiVersion" = "traefik.containo.us/v1alpha1"
		"kind"       = "IngressRouteTCP"
		"metadata"   = {
			"name"      = "proxy"
			"namespace" = kubernetes_namespace.proxy.metadata[0].name
		}
		"spec" = {
			entryPoints = ["proxy"]
			routes      = [
				{
					match    = "HostSNI(`*`)"
					services = [
						{
							name = kubernetes_service.proxy.metadata[0].name
							port = kubernetes_service.proxy.spec[0].port[0].port
						},
					]
				},
			]
		}
	}

	depends_on = [helm_release.traefik]
}