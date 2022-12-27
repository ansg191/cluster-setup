resource "kubernetes_namespace" "nfs" {
	metadata {
		name = "nfs"
	}
}

## NFS Server

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

## SSHFS Server

resource "kubernetes_deployment" "sshfs-server" {
	metadata {
		name      = "sshfs-server"
		namespace = kubernetes_namespace.nfs.metadata[0].name
		labels    = {
			"app.kubernetes.io/name" = "sshfs-server"
		}
	}
	spec {
		replicas = "1"
		selector {
			match_labels = {
				"app.kubernetes.io/name" = "sshfs-server"
			}
		}
		template {
			metadata {
				labels = {
					"app.kubernetes.io/name" = "sshfs-server"
				}
			}
			spec {
				container {
					name              = "server"
					image             = "linuxserver/openssh-server:latest"
					image_pull_policy = "Always"

					port {
						name           = "ssh"
						container_port = 2222
					}

					env {
						name  = "PUID"
						value = "1000"
					}
					env {
						name  = "PGID"
						value = "1000"
					}
					env {
						name  = "TZ"
						value = "America/Los_Angeles"
					}
					env {
						name  = "PUBLIC_KEY"
						value = file("files/sshfs_key.pub")
					}

					volume_mount {
						mount_path = "/exports"
						name       = "nfs"
					}
					volume_mount {
						mount_path = "/config"
						name       = "config"
					}
				}

				volume {
					name = "nfs"
					nfs {
						server = "${kubernetes_service.nfs.metadata[0].name}.${kubernetes_namespace.nfs.metadata[0].name}.svc.cluster.local"
						path   = "/exports"
					}
				}
				volume {
					name = "config"
					empty_dir {}
				}

				restart_policy = "Always"
			}
		}
	}
}

resource "kubernetes_service" "sshfs" {
	metadata {
		name      = "sshfs"
		namespace = kubernetes_namespace.nfs.metadata[0].name
	}
	spec {
		type     = "ClusterIP"
		selector = {
			"app.kubernetes.io/name" = "sshfs-server"
		}

		port {
			name        = "ssh"
			port        = 22
			target_port = "ssh"
		}
	}
}

resource "kubernetes_manifest" "sshfs_ssh_ingress" {
	manifest = {
		"apiVersion" = "traefik.containo.us/v1alpha1"
		"kind"       = "IngressRouteTCP"
		"metadata"   = {
			"name"      = "sshfs-ssh-ingress"
			"namespace" = kubernetes_namespace.nfs.metadata[0].name
		}
		"spec" = {
			"entryPoints" = ["sshfs"]
			"routes"      = [
				{
					"match"    = "HostSNI(`*`)"
					"services" = [
						{
							"name" = kubernetes_service.sshfs.metadata[0].name
							"port" = 22
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
