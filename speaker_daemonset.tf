# Create Speaker DaemonSet
resource "kubernetes_daemonset" "speaker" {
  metadata {
    labels = {
      app = "metallb"
      component = "speaker"
    }
    name      = "speaker"
    namespace = kubernetes_namespace.metallb_system.metadata.0.name
  }

  spec {
    selector {
      match_labels = {
        app = "metallb"
        component = "speaker"
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
          component = "speaker"
        }
      }

      spec {

        automount_service_account_token = true # override Terraform's default false - https://github.com/kubernetes/kubernetes/issues/27973#issuecomment-462185284
        service_account_name = "speaker"
        termination_grace_period_seconds = 2
        host_network = true
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        toleration {
          key = "node-role.kubernetes.io/master"
          effect = "NoSchedule"
        }

        container {
          name  = "speaker"
          image = "metallb/speaker:v${var.metallb_version}"
          image_pull_policy = "Always"

          args = [
            "--port=7472",
            "--config=config",
          ]

          env {
            name = "METALLB_NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }

          env {
            name = "METALLB_HOST"
            value_from {
              field_ref {
                field_path = "status.hostIP"
              }
            }
          }

          env {
            name = "METALLB_ML_BIND_ADDR"
            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }

          env {
            name = "METALLB_ML_LABELS"
            value = "app=metallb,component=speaker"
          }

          env {
            name = "METALLB_ML_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          env {
            name = "METALLB_ML_SECRET_KEY"
            value_from {
              secret_key_ref {
                name = "memberlist"
                key = "secretkey"
              }
            }
          }

          port {
            name = "monitoring"
            container_port = 7472
          }

          resources {
            requests {
              cpu    = "100m"
              memory = "100Mi"
            }
          }

          security_context {
            allow_privilege_escalation = false
            capabilities {
              add = ["NET_ADMIN", "NET_RAW", "SYS_ADMIN"]
              drop = ["ALL"]
            }
            read_only_root_filesystem = true
          }

        }
      }
    }
  }
}