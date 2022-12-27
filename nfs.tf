resource "kubernetes_namespace" "nfs" {
	metadata {
		name = "nfs"
	}
}

resource "kubernetes_persistent_volume_claim" "nfs_backing_disk" {
	metadata {
		name      = "nfs-backing-disk"
		namespace = kubernetes_namespace.nfs.metadata[0].name
	}
	spec {
		access_modes = ["ReadWriteOnce"]
		resources {
			requests = {
				storage = "128Gi"
			}
		}
	}
}

resource "kubernetes_deployment" "nfs-server" {
	metadata {
		name      = "nfs-server"
		namespace = kubernetes_namespace.nfs.metadata[0].name
		labels    = {
			"app.kubernetes.io/name" = "nfs-server"
		}
	}
	spec {
		replicas = "1"
		selector {
			match_labels = {
				"app.kubernetes.io/name" = "nfs-server"
			}
		}
		template {
			metadata {
				labels = {
					"app.kubernetes.io/name" = "nfs-server"
				}
			}
			spec {
				container {
					name              = "nfs-server"
					image             = "gcr.io/google_containers/volume-nfs:0.8"
					image_pull_policy = "IfNotPresent"

					port {
						name           = "nfs"
						container_port = 2049
					}
					port {
						name           = "mountd"
						container_port = 20048
					}
					port {
						name           = "rpcbind"
						container_port = 111
					}

					security_context {
						privileged = true
					}

					volume_mount {
						mount_path = "/exports"
						name       = "nfs-pvc"
					}
				}

				volume {
					name = "nfs-pvc"
					persistent_volume_claim {
						claim_name = kubernetes_persistent_volume_claim.nfs_backing_disk.metadata[0].name
					}
				}

				restart_policy = "Always"
			}
		}
	}
}

resource "kubernetes_service" "nfs" {
	metadata {
		name      = "nfs"
		namespace = kubernetes_namespace.nfs.metadata[0].name
	}
	spec {
		type     = "ClusterIP"
		selector = {
			"app.kubernetes.io/name" = "nfs-server"
		}

		port {
			name = "nfs"
			port = 2049
		}
		port {
			name = "mountd"
			port = 20048
		}
		port {
			name = "rpcbind"
			port = 111
		}
	}
}
