# The Provider block sets up the vSphere provider - How to connect to vCenter. Note the use of
# variables to avoid hardcoding credentials here

provider "vsphere" {
  user           = "${var.vsphere_user}"
  password       = "${var.vsphere_password}"
  vsphere_server = "${var.vsphere_server}"
  allow_unverified_ssl = true
}

# The Data sections are about determining where the virtual machine will be placed. 
# Here we are naming the vSphere DC, the cluster, datastore, virtual network and the template
# name. These are called upon later when provisioning the VM resource

data "vsphere_datacenter" "dc" {
  name = "DC"
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = var.network
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

//  This is to find out the UUId of the VM tempalte used to deploy the VM

data "vsphere_virtual_machine" "template" {
  name          = var.templatename
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

# The Resource section creates the virtual machine, in this case 
# from a template

resource "vsphere_virtual_machine" "vm" {
  name             = "${var.servername}"
  resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus = 2
  memory   = 4096
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"
  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      windows_options {
        computer_name  = "terraform-test"
        workgroup      = "test"
        admin_password = "VMw4re1234###"
        //join_domain - (Optional) The domain to join for this virtual machine. One of this or workgroup must be included.
       // https://www.terraform.io/docs/providers/vsphere/r/virtual_machine.html#creating-a-virtual-machine-from-a-template
      }


      network_interface {}
    }
  }
}

# This resource exists to call the file and remote-exec Terraform provisioners. This runs after
# the virtual machine resource has been created. It uses the file provisioner to copy a .rpm file stored
# locally to the newly created server, then uses the remote exec provisioner to run the commands necessary
# to install the rpm



# Finally, we're outputting the IP address of the new VM

output "my_ip_address" {
 value = "${vsphere_virtual_machine.vm.default_ip_address}"
}