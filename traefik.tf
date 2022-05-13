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
}