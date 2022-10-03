resource "kubernetes_namespace" "datadog" {
	metadata {
		name = "ddog"
	}
}

resource "kubernetes_secret" "ddog_api_key" {
	metadata {
		name      = "ddog-api-key"
		namespace = "ddog"
	}

	data = {
		"api-key" = var.datadog_api_key
	}

	depends_on = [
		kubernetes_namespace.datadog
	]
}

resource "helm_release" "datadog" {
	name       = "datadog"
	repository = "https://helm.datadoghq.com"
	chart      = "datadog"
	namespace  = "ddog"

	set {
		name  = "datadog.apiKeyExistingSecret"
		value = "ddog-api-key"
	}

	set {
		name  = "datadog.logs.enabled"
		value = "true"
	}
	set {
		name  = "datadog.logs.containerCollectAll"
		value = "true"
	}

	set {
		name  = "datadog.networkMonitoring.enabled"
		value = "true"
	}

	depends_on = [
		kubernetes_namespace.datadog,
		kubernetes_secret.ddog_api_key
	]
}