resource "kubernetes_namespace" "metrics" {
	metadata {
		name = var.metrics_namespace
	}
}

resource "helm_release" "metrics" {
	name       = "metrics"
	repository = "https://prometheus-community.github.io/helm-charts"
	chart      = "kube-prometheus-stack"
	namespace  = var.metrics_namespace
}