resource "google_compute_network" "nat-example" {
    project = "some-project-id"
    name = "nat-example"
    auto_create_subnetworks = false
    mtu = 1460
    routing_mode = "REGIONAL"
}
resource "google_compute_subnetwork" "some-subnet" {
    name = "some-subnet"
    network = "nat-example"
    ip_cidr_range = "10.0.1.0/24"
    region = "europe-west1"
}
resource "google_compute_firewall" "allow-internal-example" {
    name = "allow-internal-example"
    network = "nat-example"
    source_ranges = ["10.0.1.0/24"]

    allow {
    protocol = "udp"
    ports = ["1-65535"]
    }

    allow {
    protocol = "tcp"
    ports = ["1-65535"]
    }

    allow {
    protocol = "icmp"
    }

    priority = 65534
}
resource "google_compute_firewall" "allow-ssh-iap" {
    name = "allow-ssh-iap"
    network = "nat-example"
    direction = "INGRESS"
    source_ranges = ["35.235.240.0/20"]

    allow {
    protocol = "tcp"
    ports = ["22"]
}

target_tags = ["allow-ssh"]
}
resource "google_compute_instance" "example-instance" {
    name = "example-instance"
    zone = "europe-west1-b"
    machine_type = "e2-micro"

    tags = ["no-ip", "allow-ssh"]

    boot_disk {
        initialize_params {
            image = "centos-cloud/debian-7"
        }
    }

    network_interface {
        subnetwork = "some-subnet"

        access_config {

        }
    }
}
resource "google_compute_instance" "nat-gateway" {
    name = "nat-gateway"
    zone = "europe-west1-b"
    can_ip_forward = true
    machine_type = "e2-micro"

    tags = ["nat", "allow-ssh"]

    boot_disk {
        initialize_params {
        image = "centos-cloud/debian-7"
        }
    }

    network_interface {
        subnetwork = "some-subnet"

        access_config {

        }
    }
    metadata_startup_script = "#! /bin/bash sudo sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward' sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE"
}
resource "google_compute_route" "no-ip-internet-route" {
    name = "no-ip-internet-route"
    network = "nat-example"
    dest_range = "0.0.0.0/0"
    next_hop_instance = "nat-gateway"
    next_hop_instance_zone = "europe-west1-b"
    priority = 800
}
