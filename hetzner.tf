locals {
  datacenter  = "fsn1-dc14"
  server_type = "cax11"
}

resource "hcloud_server" "node1" {
  name        = "cloudmax2"
  image       = data.hcloud_image.image_2.id
  server_type = local.server_type

  public_net {
    ipv4_enabled = true
    ipv4         = hcloud_primary_ip.primary1.id
    ipv6_enabled = true
  }

  ssh_keys   = [hcloud_ssh_key.edejong.id]
  datacenter = local.datacenter
}

resource "hcloud_primary_ip" "primary1" {
  datacenter    = local.datacenter
  type          = "ipv4"
  assignee_type = "server"
  auto_delete   = true
  name          = "primary1"
}

resource "hcloud_rdns" "primary1" {
  primary_ip_id = hcloud_primary_ip.primary1.id
  ip_address    = hcloud_primary_ip.primary1.ip_address
  dns_ptr       = "dejongsoftwareengineering.nl"
}

resource "hcloud_volume" "master_volume2" {
  name      = "volume_cloudmax3"
  size      = 50
  server_id = hcloud_server.node1.id
  automount = true
  format    = "ext4"
}

resource "hcloud_volume_attachment" "master_node1" {
  server_id = hcloud_server.node1.id
  volume_id = hcloud_volume.master_volume2.id
}

resource "hcloud_ssh_key" "edejong" {
  name       = "Edwin de Jong Public Key"
  public_key = file("${path.module}/ssh_keys/id_rsa.pub")
}

data "hcloud_image" "image_2" {
  name              = "debian-12"
  with_architecture = "arm"
}