terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
  }
}

provider "openstack" {
  auth_url    = "https://192.168.1.201:5000/v3"
  user_name   = "admin"
  password    = "TOVbofyzC22S2BfQDGTPLUW3eKzGrEGB"
  tenant_name = "admin"
  user_domain_name = "default"
  project_domain_name = "default"
  region      = "microstack"
  insecure    = true
}

# Create Network
resource "openstack_networking_network_v2" "demo_network" {
  name           = "demo-network"
  admin_state_up = "true"
}

# Create Subnet
resource "openstack_networking_subnet_v2" "demo_subnet" {
  name            = "demo-subnet"
  network_id      = openstack_networking_network_v2.demo_network.id
  cidr            = "10.0.1.0/24"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# Get External Network
data "openstack_networking_network_v2" "external" {
  name = "external"
}

# Create Router
resource "openstack_networking_router_v2" "demo_router" {
  name                = "demo-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
}

# Create Router Interface
resource "openstack_networking_router_interface_v2" "demo_router_interface" {
  router_id = openstack_networking_router_v2.demo_router.id
  subnet_id = openstack_networking_subnet_v2.demo_subnet.id
}

# Create Security Group
resource "openstack_networking_secgroup_v2" "demo_secgroup" {
  name        = "demo-secgroup"
  description = "Security group for demo instance"
}

# Allow ICMP (ping)
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_icmp" {
  direction         = "ingress"
  ethertype        = "IPv4"
  protocol         = "icmp"
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.demo_secgroup.id
}

# Allow SSH
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_ssh" {
  direction         = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 22
  port_range_max   = 22
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.demo_secgroup.id
}

# Allow K3S API Server
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_k3s" {
  direction         = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 6443
  port_range_max   = 6443
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.demo_secgroup.id
}

# Allow WordPress HTTP
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_wordpress" {
  direction         = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 30080
  port_range_max   = 30080
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.demo_secgroup.id
}

# Create Key Pair
resource "openstack_compute_keypair_v2" "demo_keypair" {
  name       = "demo-keypair"
  public_key = file("/root/.ssh/id_rsa.pub")
}

# Create Instance
resource "openstack_compute_instance_v2" "demo_instance" {
  name            = "demo-instance"
  image_name      = "ubuntu-22.04"
  flavor_name     = "m2.bigger"
  key_pair        = openstack_compute_keypair_v2.demo_keypair.name
  security_groups = [openstack_networking_secgroup_v2.demo_secgroup.name]

  network {
    uuid = openstack_networking_network_v2.demo_network.id
  }
}

# Create and Associate Floating IP
resource "openstack_networking_floatingip_v2" "demo_floating_ip" {
  pool = "external"  # This will use the default external network pool
}

resource "openstack_compute_floatingip_associate_v2" "demo_floating_ip_associate" {
  floating_ip = openstack_networking_floatingip_v2.demo_floating_ip.address
  instance_id = openstack_compute_instance_v2.demo_instance.id
}

# Output the Floating IP
output "floating_ip" {
  value = openstack_networking_floatingip_v2.demo_floating_ip.address
}