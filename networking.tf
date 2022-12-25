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

resource "kubernetes_manifest" "default_cert" {
	manifest = {
		"apiVersion" = "cert-manager.io/v1"
		"kind"       = "Certificate"
		"metadata"   = {
			"name"      = "default-cert"
			"namespace" = "default"
		}
		"spec" = {
			"secretName" = "default-cert"
			"commonName" = "*.anshulg.com"
			"dnsNames"   = [
				"*.anshulg.com"
			]
			ipAddresses = [
				"34.27.178.15"
			]
			"duration"    = "24h0m0s"
			"renewBefore" = "8h0m0s"
			"privateKey"  = {
				"algorithm" = "ECDSA"
				"size"      = 256
			}
			"issuerRef" = {
				"group" = "certmanager.step.sm"
				"kind"  = "StepClusterIssuer"
				"name"  = "step-anshulg-issuer"
			}
		}
	}

	depends_on = [
		helm_release.traefik,
		helm_release.cert_manager
	]
}

resource "kubernetes_manifest" "default_cert_options" {
	manifest = {
		"apiVersion" = "traefik.containo.us/v1alpha1"
		"kind"       = "TLSStore"
		"metadata"   = {
			"name"      = "default"
			"namespace" = "default"
		}
		"spec" = {
			"defaultCertificate" = {
				"secretName" = "default-cert"
			}
		}
	}

	depends_on = [helm_release.traefik]
}

resource "kubernetes_manifest" "security_headers" {
	manifest = {
		"apiVersion" = "traefik.containo.us/v1alpha1"
		"kind"       = "Middleware"
		"metadata"   = {
			"name"      = "security-headers"
			"namespace" = "default"
		}
		"spec" = {
			"headers" = {
				"frameDeny"          = true
				"browserXssFilter"   = true
				"referrerPolicy"     = "no-referrer"
				"stsSeconds"         = 31536000
				"contentTypeNosniff" = true
			}
		}
	}

	depends_on = [helm_release.traefik]
}
