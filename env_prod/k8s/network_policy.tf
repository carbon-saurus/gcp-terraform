resource "kubernetes_network_policy" "allow_smtp_outbound" {
  metadata {
    name      = "allow-smtp-outbound"
    namespace = "carbon-re"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "carbontrack-account-api-gcp"
      }
    }

    policy_types = ["Egress"]

    egress {
      ports {
        port     = "587"
        protocol = "TCP"
      }
    }
  }
} 