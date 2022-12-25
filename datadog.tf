resource "kubernetes_namespace" "datadog" {
	metadata {
		name = "ddog"
	}
}

resource "kubernetes_manifest" "ddog_api_key" {
	manifest = {
		"apiVersion" = "onepassword.com/v1"
		"kind" = "OnePasswordItem"
		"metadata" = {
			"name" = "ddog-api-key"
			"namespace" = "ddog"
		}
		spec = {
			"itemPath" = "vaults/Dev/items/DataDog K8 API Key"
		}
	}

	depends_on = [
		helm_release.one_password,
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

	# APM
	set {
		name  = "datadog.apm.portEnabled"
		value = "true"
	}

	depends_on = [
		kubernetes_namespace.datadog,
		kubernetes_manifest.ddog_api_key
	]
}