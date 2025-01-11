terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {
  host = "unix:///Users/ahmadharkous/.docker/run/docker.sock"
}

#docker network
resource "docker_network" "gitea_network" {
  name = "gitea_network"
}

# Traefik Service
resource "docker_image" "traefik" {
  name = "traefik"
}

resource "docker_container" "traefik" {
  name  = "tp1_traefik"
  image = docker_image.traefik.image_id
  restart = "unless-stopped"
  networks_advanced {
    name = docker_network.gitea_network.name
  }

  ports {
    internal = 80
    external = 80
  }
  ports {
    internal = 443
    external = 443
  }
  ports {
    internal = 8080
    external = 8080
  }
  ports {
    internal = 2222
    external = 2222
  }

  volumes {
    host_path      = "${abspath(path.module)}/../traefik/traefik.yml"
    container_path = "/etc/traefik/traefik.yml"
  }
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }
  labels {
    label = "traefik.enable"
    value = "false"
  }
}

# Database Service
resource "docker_image" "mysql" {
  name = "mysql:8"
}

resource "docker_volume" "database_data" {}

resource "docker_container" "database" {
  name  = "tp1_gitea_db"
  image = docker_image.mysql.image_id
  restart = "unless-stopped"
  networks_advanced {
    name = docker_network.gitea_network.name
  }

  env = [
    "MYSQL_ROOT_PASSWORD=/run/secrets/gitea_db_root_passwd",
    "MYSQL_USER=${var.gitea_admin}",
    "MYSQL_PASSWORD=/run/secrets/gitea_db_passwd",
    "MYSQL_DATABASE=${var.gitea_db_name}"
  ]


  volumes {
    volume_name    = docker_volume.database_data.name
    container_path = "/var/lib/mysql"
  }

  labels {
    label = "traefik.enable"
    value = "false"
  }
}

# Gitea Service
resource "docker_image" "gitea" {
  name = "gitea/gitea:latest-rootless"
}

resource "docker_volume" "gitea_data" {}
resource "docker_volume" "gitea_config" {}

resource "docker_container" "gitea" {
  name  = "tp1_gitea"
  image = docker_image.gitea.image_id
  restart = "unless-stopped"
  networks_advanced {
    name = docker_network.gitea_network.name
  }

  env = [
    "GITEA__database__DB_TYPE=mysql",
    "GITEA__database__HOST=tp1_gitea_db:3306",
    "GITEA__database__NAME=${var.gitea_db_name}",
    "GITEA__database__USER=${var.gitea_admin}",
    "GITEA__database__PASSWD=/run/secrets/gitea_db_passwd",
    "GITEA__server__ROOT_URL=https://${var.gitea_hostname_env}"
  ]

  volumes {
    volume_name    = docker_volume.gitea_data.name
    container_path = "/var/lib/gitea"
  }
  volumes {
    volume_name    = docker_volume.gitea_config.name
    container_path = "/etc/gitea"
  }

  depends_on = [docker_container.database]

  labels {
    label = "traefik.enable"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.gitea.rule"
    value = "Host(`${var.gitea_hostname_env}`)"
  }
  labels {
    label = "traefik.http.routers.gitea.tls"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.gitea.entrypoints"
    value = "websecure"
  }
  labels {
    label = "traefik.http.services.gitea.loadbalancer.server.port"
    value = "3000"
  }
  labels {
    label = "traefik.tcp.routers.gitea-ssh.rule"
    value = "HostSNI(`*`)"
  }
  labels {
    label = "traefik.tcp.routers.gitea-ssh.entrypoints"
    value = "ssh"
  }
  labels {
    label = "traefik.tcp.services.gitea-ssh.loadbalancer.server.port"
    value = "2222"
  }
}

# Gitea Runners
resource "docker_image" "gitea_runner" {
  name = "gitea/act_runner"
}

resource "docker_container" "runner1" {
  name  = "gitea-runner-1"
  image = docker_image.gitea_runner.image_id
  restart = "unless-stopped"
  networks_advanced {
    name = docker_network.gitea_network.name
  }

  env = [
    "RUNNER_NAME=gitea-runner-1",
    "GITEA_URL=https://${var.gitea_instance_url} ",
  ]

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  depends_on = [docker_container.gitea]

  labels {
    label = "traefik.enable"
    value = "false"
  }
}
resource "docker_container" "runner2" {
  name  = "gitea-runner-2"
  image = docker_image.gitea_runner.image_id
  restart = "unless-stopped"
  networks_advanced {
    name = docker_network.gitea_network.name
  }

  env = [
    "RUNNER_NAME=gitea-runner-1",
    "GITEA_URL=https://${var.gitea_instance_url}",
  ]

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  depends_on = [docker_container.gitea]

  labels {
    label = "traefik.enable"
    value = "false"
  }
}
resource "docker_container" "runner3" {
  name  = "gitea-runner-3"
  image = docker_image.gitea_runner.image_id
  restart = "unless-stopped"
  networks_advanced {
    name = docker_network.gitea_network.name
  }

  env = [
    "RUNNER_NAME=gitea-runner-1",
    "GITEA_URL=https://${var.gitea_instance_url}",
  ]

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  depends_on = [docker_container.gitea]

  labels {
    label = "traefik.enable"
    value = "false"
  }
}