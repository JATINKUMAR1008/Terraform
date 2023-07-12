terraform {
  

  required_providers {
    digitalocean={
        source = "digitalocean/digitalocean"
        version = "~> 2.0"
    }
  }
}

provider "digitalocean" {}

resource "digitalocean_ssh_key" "web" {
  name = "Terraform created SSH key"
  public_key = file("${path.module}/files/id_rsa.pub")
}

resource "digitalocean_droplet" "web" {
  image = "ubuntu-22-10-x64"
  name = "web-1"
  region = "nyc1"
  size = "s-1vcpu-1gb"
  ssh_keys = [ 
    digitalocean_ssh_key.web.id
   ]
   user_data = file("${path.module}/files/user_data.sh")
}