#resource "kubernetes_pod_disruption_budget" "kube_dns" {
#	metadata {
#		labels = {
#			"k8s-app" = "kube-dns"
#		}
#		name = "kube-dns-bbc"
#		namespace = "kube-system"
#	}
#	spec {
#		max_unavailable = "1"
#		selector {
#			match_labels = {
#				"k8s-app" = "kube-dns"
#			}
#		}
#	}
#}
#
#resource "kubernetes_pod_disruption_budget" "kube_dns_autoscaler" {
#	metadata {
#		labels = {
#			"k8s-app" = "kube-dns-autoscaler"
#		}
#		name = "kube-dns-autoscaler-bbc"
#		namespace = "kube-system"
#	}
#	spec {
#		max_unavailable = "1"
#		selector {
#			match_labels = {
#				"k8s-app" = "kube-dns-autoscaler"
#			}
#		}
#	}
#}