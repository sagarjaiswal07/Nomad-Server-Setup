// jobs/final-app.nomad.hcl

job "final-app" {
  datacenters = ["dc1"]
  type        = "service"

  group "web" {
    count = 2

    network {
      port "http" {
        static = 8080 
      }
    }

    
   
    service {
      name = "final-app-web"
      port = "http"

     
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
