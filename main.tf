provider "digitalocean" {
  token = var.TIENDA_TOKEN
}

terraform {
    required_providers {
      digitalocean = {
        source = "digitalocean/digitalocean"
        version = "~> 2.0"
      }
    }
    backend "s3" {
    endpoints = {
      s3 = "https://sfo3.digitaloceanspaces.com"
    }
    bucket = "proyecto000001"
    key = "terraform.tfstate"
    skip_credentials_validation = true
    skip_requesting_account_id = true
    skip_metadata_api_check = true
    skip_s3_checksum = true
    region = "us-east-1"
  }
}

resource "digitalocean_project" "tienda_server_project" {
  name = "tienda_server_project"
  description = "Un servidor para el proyecto"
  resources = [digitalocean_droplet.tienda_server_droplet.urn]
}

resource "digitalocean_ssh_key" "tienda_server_ssh_key" {
  name = "tienda_server_key"
  public_key = file("./keys/tiendaVideojuegos.pub")
}

resource "digitalocean_droplet" "tienda_server_droplet" {
  name = "tiendaserver"
  size = "s-2vcpu-4gb-120gb-intel"
  image = "ubuntu-24-04-x64"
  region = "sfo3"
  ssh_keys = [digitalocean_ssh_key.tienda_server_ssh_key.id]
  user_data = file("./docker-install.sh")

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /projects",
      "mkdir -p /volumes/nginx/html",
      "mkdir -p /volumes/nginx/certs",
      "mkdir -p /volumes/nginx/vhostd",
      "touch /projects/.env",
      "echo \"DB_NAME=${var.DB_NAME}\" >> /projects/.env",
      "echo \"DB_USER=${var.DB_USER}\" >> /projects/.env",
      "echo \"DB_CLUSTER=${var.DB_CLUSTER}\" >> /projects/.env",
      "echo \"DB_PASSWORD=${var.DB_PASSWORD}\" >> /projects/.env",
      "echo \"DOMAIN=${var.DOMAIN}\" >> /projects/.env",
      "echo \"USER_EMAIL=${var.USER_EMAIL}\" >> /projects/.env"
    ]
    connection {
      type = "ssh"
      user = "root"
      private_key = file("./keys/tiendaVideojuegos")
      host = self.ipv4_address
    }
  }

  provisioner "file" {
    source = "./containers/docker-compose.yml"
    destination = "/projects/docker-compose.yml"
    connection {
      type = "ssh"
      user = "root"
      private_key = file("./keys/tiendaVideojuegos")
      host = self.ipv4_address
    }
  }
}

output "ip" {
  value = digitalocean_droplet.tienda_server_droplet.ipv4_address
}