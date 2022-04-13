terraform {
	required_providers {
		kubernetes = {
			source = "hashicorp/kubernetes"
			version = "2.10.0"
		}
		helm = {
			source = "hashicorp/helm"
			version = "2.5.1"
		}
	}
}

provider "kubernetes" {
	config_path = "~/.kube/config"
	config_context = "default"
}

provider "helm" {
	kubernetes {
		config_path = "~/.kube/config"
	}
}