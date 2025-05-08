resource "kubernetes_network_policy" "allow_smtp_outbound" {
  metadata {
    name      = "allow-smtp-outbound"
    namespace = "re100-dev"
  }

  spec {
    pod_selector {
      match_labels = {
        app = "re100-eps-api" 
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