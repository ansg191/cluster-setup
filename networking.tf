resource "kubernetes_manifest" "tls_options" {
	manifest = {
		"apiVersion" = "traefik.containo.us/v1alpha1"
		"kind"       = "TLSOption"
		"metadata"   = {
			"name"      = "default"
			"namespace" = "default"
		}
		"spec" = {
			"minVersion"   = "VersionTLS12"
			"cipherSuites" = [
				"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256",
				"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
				"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384",
				"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
				"TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305",
				"TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
			]
		}
	}

	depends_on = [
		helm_release.traefik
	]
}