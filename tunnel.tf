resource "kubernetes_config_map" "frps_config" {
	metadata {
		name      = "frps-config"
		namespace = kubernetes_namespace.traefik.metadata[0].name
	}

	data = {
		"frps.ini" = <<-EOF
[common]
bind_port = 7000
dashboard_port = 7500
EOF
	}
}

resource "kubernetes_deployment" "frps" {
	metadata {
		name      = "frps"
		namespace = kubernetes_namespace.traefik.metadata[0].name
	}
	spec {
		replicas = "1"
		selector {
			match_labels = {
				"app.kubernetes.io/name" = "frps"
			}
		}
		template {
			metadata {
				labels = {
					"app.kubernetes.io/name" = "frps"
				}
			}
			spec {
				container {
					name  = "frps"
					image = "fatedier/frps:v0.46.0"

					command = ["frps", "-c", "/etc/frp/frps.ini"]

					port {
						name           = "bind-port"
						container_port = 7000
					}
					port {
						name           = "dashboard-port"
						container_port = 7500
					}

					port {
						name           = "webssl"
						container_port = 443
					}

					volume_mount {
						mount_path = "/etc/frp"
						name       = "frps-config"
					}
				}

				volume {
					name = "frps-config"
					config_map {
						name = kubernetes_config_map.frps_config.metadata[0].name
					}
				}
			}
		}
	}
}

resource "kubernetes_service" "frps" {
	metadata {
		name      = "frps"
		namespace = kubernetes_namespace.traefik.metadata[0].name
	}
	spec {
		type = "ClusterIP"

		selector = {
			"app.kubernetes.io/name" = "frps"
		}

		port {
			name        = "bind-port"
			port        = 7000
			target_port = "bind-port"
		}

		port {
			name        = "dashboard-port"
			port        = 7500
			target_port = "dashboard-port"
		}

		port {
			name        = "webssl"
			port        = 443
			target_port = "webssl"
		}
	}
}

resource "kubernetes_manifest" "tunnel" {
	manifest = {
		apiVersion = "traefik.containo.us/v1alpha1"
		kind       = "IngressRouteTCP"
		metadata   = {
			name      = "frps-bind-ingress"
			namespace = kubernetes_namespace.traefik.metadata[0].name
		}
		spec = {
			entryPoints = ["frps"]
			routes      = [
				{
					match    = "HostSNI(`*`)"
					services = [
						{
							name = kubernetes_service.frps.metadata[0].name
							port = 7000
						},
					]
				},
			]
		}
	}

	depends_on = [
		helm_release.traefik
	]
}

resource "kubernetes_service" "frps-external" {
	metadata {
		name      = "frps-external"
		namespace = kubernetes_namespace.traefik.metadata[0].name
	}
	spec {
		type          = "ExternalName"
		external_name = "${kubernetes_service.frps.metadata[0].name}.${kubernetes_namespace.traefik.metadata[0].name}.svc.cluster.local"
		port {
			name        = "webssl"
			port        = 443
			target_port = "webssl"
		}
	}
}

resource "kubernetes_manifest" "internal_transport" {
	manifest = {
		"apiVersion" = "traefik.containo.us/v1alpha1"
		"kind"       = "ServersTransport"
		"metadata"   = {
			"name"      = "internal-transport"
			"namespace" = kubernetes_namespace.traefik.metadata[0].name
		}
		"spec" = {
			"rootCAsSecrets" = [
				"ca-cert"
			]
		}
	}

	depends_on = [
		helm_release.traefik
	]
}

resource "kubernetes_secret" "ca-cert" {
	metadata {
		name      = "ca-cert"
		namespace = kubernetes_namespace.traefik.metadata[0].name
	}
	data = {
		"ca.crt" = file("files/ca.crt")
	}
}

resource "kubernetes_manifest" "frps-webssl-ingress" {
	manifest = {
		"apiVersion" = "traefik.containo.us/v1alpha1"
		"kind"       = "IngressRoute"
		"metadata"   = {
			"name"      = "frps-webssl-ingress"
			"namespace" = kubernetes_namespace.traefik.metadata[0].name
		}
		"spec" = {
			"entryPoints" = [
				"websecure"
			]
			"routes" = [
				{
					"match"    = "Host(`frp.anshulg.com`, `home.media.anshulg.com`)"
					"kind"     = "Rule"
					"services" = [
						{
							"name"             = kubernetes_service.frps-external.metadata[0].name
							"port"             = 443
							"passHostHeader"   = true
							"scheme"           = "https"
							"serversTransport" = "internal-transport"
						},
					]
				},
			]
			"tls" = {
				"secretName" = "frps-webssl-tls"
			}
		}
	}

	depends_on = [
		helm_release.traefik
	]
}

resource "kubernetes_manifest" "frps-cert" {
	manifest = {
		"apiVersion" = "cert-manager.io/v1"
		"kind"       = "Certificate"
		"metadata"   = {
			"name"      = "frps-webssl-cert"
			"namespace" = kubernetes_namespace.traefik.metadata[0].name
		}
		"spec" = {
			"secretName" = "frps-webssl-tls"
			"commonName" = "frp.anshulg.com"
			"dnsNames"   = [
				"frp.anshulg.com",
				"home.media.anshulg.com"
			]
			"privateKey" = {
				"algorithm" = "ECDSA"
				"size"      = 256
			}
			"issuerRef" = {
				"name" = "letsencrypt-prod"
				"kind" = "ClusterIssuer"
			}
		}
	}

	depends_on = [
		helm_release.cert_manager
	]
}