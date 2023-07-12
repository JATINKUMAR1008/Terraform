terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {}

resource "digitalocean_ssh_key" "ssh-droplet-key" {
  name       = "Terraform created SSH key"
  public_key =  file("${path.module}/files/id_rsa.pub")
}

resource "digitalocean_droplet" "web" {
  count              = 3
  image              = "ubuntu-22-10-x64"
  name               = "web-${count.index}"
  region             = "nyc1"
  size               = "s-1vcpu-1gb"
  private_networking = true
  monitoring         = true
  ssh_keys = [
    digitalocean_ssh_key.ssh-droplet-key.id
  ]
  user_data = file("${path.module}/files/user_data.sh")
}


resource "digitalocean_loadbalancer" "web" {
  name   = "web-lb"
  region = "nyc1"
  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"
  }
  
 
  healthcheck {
    port     = 22
    protocol = "tcp"
  }
  droplet_ids = digitalocean_droplet.web.*.id
}

resource "digitalocean_firewall" "web" {
  name = "web-droplet-firewall"
  droplet_ids = digitalocean_droplet.web.*.id

  inbound_rule {
    protocol = "tcp"
    port_range = "22"
    
    source_load_balancer_uids = [digitalocean_loadbalancer.web.id]
  }
  inbound_rule {
    protocol = "tcp"
    port_range = "80"
    source_load_balancer_uids = [digitalocean_loadbalancer.web.id]
  }
  outbound_rule {
    protocol = "tcp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
