// jobs/final-app.nomad.hcl

job "final-app" {
  datacenters = ["dc1"]
  type        = "service"

  group "web" {
    count = 2

    network {
      port "http" {
        static = 8080 # The ALB is configured to check this port
      }
    }

    # This service block makes the job visible to Consul if you add it later,
    # but most importantly, it's where the health check is defined.
    service {
      name = "final-app-web"
      port = "http"

      # This check is used by Nomad itself. If the task fails this,
      # Nomad will restart it.
      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "server" {
      driver = "docker"

      config {
        image = "hashicorp/http-echo:latest"
        ports = ["http"]

        # Arguments for the http-echo server.
        # It will listen on port 8080 inside the container and
        # respond with the specified text.
        args = [
          "-listen",
          ":8080",
          "-text",
          "Hello World!!! This is Sagar",
        ]
      }

      resources {
        cpu    = 100 # MHz
        memory = 64  # MB
      }
    }
  }
}