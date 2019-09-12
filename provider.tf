#parte en la que configuramos el contenedor
provider "google" {
  credentials = "${file("master-devops-5114db387441.json")}"
  project     = "master-devops"
  region      = "europe-west2"
}

#red padre  mysql
resource "google_compute_network" "red-mysql" {
  name = "networkmysql"
  auto_create_subnetworks = false
}

#red padre  wordpress
resource "google_compute_network" "red-wordpress" {
  name = "networkwordpress"
  auto_create_subnetworks = false
}

#conexion de nuestras redes
resource "google_compute_network_peering" "peeringdevops1" {
  name = "peeringdevops1"
  network = "${google_compute_network.red-wordpress.self_link}"
  peer_network = "${google_compute_network.red-mysql.self_link}"
  auto_create_routes = true
}
resource "google_compute_network_peering" "peeringdevops2" {
  name = "peeringdevops2"
  network = "${google_compute_network.red-mysql.self_link}"
  peer_network = "${google_compute_network.red-wordpress.self_link}"
  auto_create_routes = true
}

#subred
resource "google_compute_subnetwork" "network-for-mysql" {
  name          = "test-subnetwork-mysql"
  #rango subred
  ip_cidr_range = "10.1.1.0/24"
  #region
  region        = "europe-west2"
  network       = "${google_compute_network.red-mysql.self_link}"
}

resource "google_compute_subnetwork" "network-for-wordpress" {
  name          = "test-subnetwork-wordpress"
  #rango subred
  ip_cidr_range = "10.2.1.0/24"
  #region
  region        = "europe-west2"
  network       = "${google_compute_network.red-wordpress.self_link}"
}



#configuracion de firewall para el acceso  externo
resource "google_compute_firewall" "allow-http" {
  name    = "openportsforwordpress"
  network = "${google_compute_network.red-wordpress.self_link}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    #puertos en los que se aceptan peticiones (ssh y html)
    ports    = ["80","22"]
  }
  #rango en las peticiones seran aceptadas
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow-mysql" {
  name    = "openportsformysql"
  network = "${google_compute_network.red-mysql.self_link}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    #puertos en los que se aceptan peticiones (ssh y html)
    ports    = ["3306","22"]
  }
  #rango en las peticiones seran aceptadas
  source_ranges = ["10.2.1.0/24"]
}


#configuracion de la instancia de mysql
resource "google_compute_instance" "mysql" {
    #nombre
    name = "mysql-devops"
    #zona en la que se desplegara la maquina
    zone = "europe-west2-c"
    #tipo de maquina en google cloud, sirve para la capacidad (ram y micro)
    machine_type = "f1-micro"
    #indicamos parametros para iniciar nuestra maquina con imagenes (que hemos creado con packer)
    boot_disk {
        initialize_params {
            image = "mysql"
        }
    }
    #seleccionamos la la interfaz de red de la maquina
    network_interface {
        network = "${google_compute_network.red-mysql.self_link}"
   	    network_ip =  "10.1.1.5"
        subnetwork = "test-subnetwork-mysql"
    }
}
#maquina  wordpress
resource "google_compute_instance" "wordpress" {
    name = "wordpress-devops"
    zone = "europe-west2-c"
    machine_type = "f1-micro"

    boot_disk {
        initialize_params {
            image = "wordpress"
        }
    }

    network_interface {
        network = "${google_compute_network.red-wordpress.self_link}"
        subnetwork = "test-subnetwork-wordpress"
        #indicamos que necesitamos una ip experna
        access_config {

        }
    }
}
