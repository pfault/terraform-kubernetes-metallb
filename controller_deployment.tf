# Create Controller Deployment
resource "kubernetes_deployment" "controller" {
  metadata {
    labels = {
      app = "metallb"
      component = "controller"
    }
    name      = "controller"
    namespace = kubernetes_namespace.metallb_system.metadata.0.name
  }

  spec {
    revision_history_limit = 3

    selector {
      match_labels = {
        app = "metallb"
        component = "controller"
      }
    }

    template {
      metadata {
        annotations = {
          "prometheus.io/port" = "7472"
          "prometheus.io/scrape" = "true"
        }
        labels = {
          app = "metallb"
          component = "controller"
        }
      }

      spec {

        automount_service_account_token = true # override Terraform's default false - https://github.com/kubernetes/kubernetes/issues/27973#issuecomment-462185284
        service_account_name = "controller"
        termination_grace_period_seconds = 0
        node_selector = {
          "kubernetes.io/os" = "linux"
        }
        security_context {
            run_as_non_root = true
            run_as_user = 65534
        }

        container {
          name  = "controller"
          image = "metallb/controller:v${var.metallb_version}"
          image_pull_policy = "Always"

          args = [
            "--port=7472",
            "--config=config",
          ]

          resources {
            requests {
              cpu    = "100m"
              memory = "100Mi"
            }
          }

          port {
            name = "monitoring"
            container_port = 7472
          }

          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
            read_only_root_filesystem = true
          }
        }
      }
    }
  }
}