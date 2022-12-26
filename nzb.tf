resource "kubernetes_namespace" "nzb" {
	metadata {
		name = "nzb"
	}
}

resource "kubernetes_deployment" "sabnzbd" {
	metadata {
		name      = "sabnzbd"
		namespace = kubernetes_namespace.nzb.metadata[0].name
		labels    = {
			"app.kubernetes.io/name" = "sabnzbd"
		}
	}
	spec {
		replicas = "1"
		selector {
			match_labels = {
				"app.kubernetes.io/name" = "sabnzbd"
			}
		}
		template {
			metadata {
				labels = {
					"app.kubernetes.io/name" = "sabnzbd"
				}
			}
			spec {
				container {
					name              = "sabnzbd"
					image             = "linuxserver/sabnzbd:latest"
					image_pull_policy = "Always"

					port {
						container_port = 8080
					}

					resources {
						requests = {
							cpu    = "100m"
							memory = "256Mi"
						}

						limits = {
							cpu    = "1"
							memory = "4Gi"
						}
					}

					env {
						name  = "PUID"
						value = "1000"
					}
					env {
						name  = "GUID"
						value = "1000"
					}
					env {
						name  = "TZ"
						value = "America/Los_Angeles"
					}

					volume_mount {
						mount_path = "/config"
						name       = "config"
					}
					volume_mount {
						mount_path = "/downloads"
						name       = "downloads"
						sub_path   = "sabnzbd/downloads"
					}
					volume_mount {
						mount_path = "/incomplete-downloads"
						name       = "downloads"
						sub_path   = "sabnzbd/incomplete-downloads"
					}
				}

				volume {
					name = "config"
					persistent_volume_claim {
						claim_name = kubernetes_persistent_volume_claim.sabnzbd_config.metadata[0].name
					}
				}

				volume {
					name = "downloads"
					nfs {
						path   = "/exports"
						server = "nfs.nfs.svc.cluster.local"
					}
				}
			}
		}
	}
}

resource "kubernetes_persistent_volume_claim" "sabnzbd_config" {
	metadata {
		name      = "sabnzbd-config"
		namespace = kubernetes_namespace.nzb.metadata[0].name
	}
	spec {
		access_modes = ["ReadWriteOnce"]
		resources {
			requests = {
				storage = "1Gi"
			}
		}
	}
}

resource "kubernetes_service" "nzb" {
	metadata {
		name      = "nzb"
		namespace = kubernetes_namespace.nzb.metadata[0].name
	}
	spec {
		type     = "ClusterIP"
		selector = {
			"app.kubernetes.io/name" = "sabnzbd"
		}
		port {
			name        = "http"
			port        = 80
			target_port = 8080
		}
	}
}

resource "kubernetes_manifest" "nzb-ingress" {
	manifest = {
		"apiVersion" = "traefik.containo.us/v1alpha1"
		"kind"       = "IngressRoute"
		"metadata"   = {
			"name"      = "nzb"
			"namespace" = kubernetes_namespace.nzb.metadata[0].name
		}
		"spec" = {
			"entryPoints" = ["websecure"]
			"routes"      = [
				{
					"kind"     = "Rule"
					"match"    = "Host(`nzb.anshulg.com`)"
					"services" = [
						{
							"name" = kubernetes_service.nzb.metadata[0].name
							"port" = 80
						},
					]
					"middlewares" = [
						{
							"name"      = "security-headers"
							"namespace" = "default"
						},
					]
				}
			]
			"tls" = {
				"secretName" = "nzb.anshulg.com"
			}
		}
	}

	depends_on = [helm_release.traefik]
}

resource "kubernetes_manifest" "nzb-cert" {
	manifest = {
		"apiVersion" = "cert-manager.io/v1"
		"kind"       = "Certificate"
		"metadata"   = {
			"name"      = "nzb.anshulg.com"
			"namespace" = kubernetes_namespace.nzb.metadata[0].name
		}
		"spec" = {
			"secretName" = "nzb.anshulg.com"
			"commonName" = "nzb.anshulg.com"
			"dnsNames"   = ["nzb.anshulg.com"]
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

	depends_on = [helm_release.cert_manager]
}