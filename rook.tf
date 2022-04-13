resource "kubernetes_namespace" "rook" {
	metadata {
		name = var.rook_namespace
	}
}

resource "helm_release" "rook" {
	name       = "rook-ceph"
	repository = "https://charts.rook.io/release"
	chart      = "rook-ceph"
	namespace  = var.rook_namespace

	depends_on = [
		kubernetes_namespace.rook
	]
}

resource "helm_release" "rook_ceph_cluster" {
	name       = "rook-ceph-cluster"
	repository = "https://charts.rook.io/release"
	chart      = "rook-ceph-cluster"
	namespace  = var.rook_namespace

	set {
		name  = "operatorNamespace"
		value = var.rook_namespace
	}

	set {
		name  = "toolbox.enabled"
		value = "true"
	}

	depends_on = [
		kubernetes_namespace.rook,
		helm_release.rook
	]
}