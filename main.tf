#----------------------------- networks
resource "lxd_network" "tdp" {
  name = "tdpbr0"

  config = {
    "ipv4.address" = "192.168.57.1/24"
    "ipv4.nat"     = "true"
    "ipv6.address" = "none"
  }
}
#----------------------------- pools
resource "lxd_storage_pool" "tdp_worker_pool" {
  name   = "tdp_worker_pool"
  driver = "dir"
}

#----------------------------- volumes
resource "lxd_volume" "tdp_worker_volume" {
  count = 3
  name  = format("tdp_worker_volume-%02s", count.index + 1)
  pool  = lxd_storage_pool.tdp_worker_pool.name
}

#----------------------------- profiles
resource "lxd_profile" "tdp" {
  name = "tdp"

  config = {
    "user.user-data" = file("cloud-init.yml")
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      nictype = "bridged"
      parent  = lxd_network.tdp.name
    }
  }

  device {
    type = "disk"
    name = "root"

    properties = {
      pool = "default"
      path = "/"
    }
  }
}

#----------------------------- containers
resource "lxd_container" "masters" {

  count = 3

  name     = format("master-%02s", count.index + 1)
  image    = "images:rockylinux/8/cloud"
  profiles = [lxd_profile.tdp.name]

  limits = {
    cpu    = 2
    memory = "2048MB"
  }
}

resource "lxd_container" "workers" {

  count = 3

  name     = format("worker-%02s", count.index + 1)
  image    = "images:rockylinux/8/cloud"
  profiles = [lxd_profile.tdp.name]

  device {
    type = "disk"
    name = "data_volume"

    properties = {
      pool   = lxd_storage_pool.tdp_worker_pool.name
      source = lxd_volume.tdp_worker_volume[count.index].name
      path   = "/data"
    }
  }

  limits = {
    cpu    = 2
    memory = "2048MB"
  }
}

resource "lxd_container" "edge" {

  count = 1

  name     = format("edge-%02s", count.index + 1)
  image    = "images:rockylinux/8/cloud"
  profiles = [lxd_profile.tdp.name]

  limits = {
    cpu    = 2
    memory = "2048MB"
  }
}
