resource "kubernetes_namespace" "one_password" {
	metadata {
		name = var.one_password_namespace
	}
}

resource "helm_release" "one_password" {
	name       = "connect"
	repository = "https://1password.github.io/connect-helm-charts"
	chart      = "connect"
	namespace  = var.one_password_namespace

	set {
		name  = "operator.create"
		value = "true"
	}

	set_sensitive {
		name  = "connect.credentials_base64"
		value = filebase64(var.one_password_credentials_file)
		type  = "string"
	}

	set_sensitive {
		name  = "operator.token.value"
		value = var.one_password_operator_token
	}

	depends_on = [
		kubernetes_namespace.one_password
	]
}