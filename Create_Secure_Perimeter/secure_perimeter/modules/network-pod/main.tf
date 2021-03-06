################################################################
#
# ©Copyright IBM Corporation 2018.
#
# LICENSE:Eclipse Public License, Version 2.0 - https://opensource.org/licenses/EPL-2.0
#
################################################################

provider "kubernetes" {
   config_path = "${var.cluster_config_path}"
   version = "~> 1.1"
}




resource "null_resource" "create_pvc" {
  provisioner "local-exec" {
        command = "kubectl --kubeconfig '${var.cluster_config_path}' apply -f ${path.module}/pvc.yaml"
     }
}



resource "kubernetes_pod" "network-pod" {
  metadata {
    name = "network-pod"

    labels {
      app = "network-pod"
    }
  }

  spec {
    container {
      image = "registry.bluemix.net/ibm/ibmcloud-secure-perimeter-network:1.0.0"
      name  = "network-pod"
      volume_mount {
        name = "network-vol"
        mount_path = "/opt/secure-perimeter"
      }
    }
    volume {
      name = "network-vol"
      persistent_volume_claim {
        claim_name = "network-pvc"
    }

    }
  }
}



#Copy in the ssh key file and the config.json file

resource "null_resource" "copy_files_to_network-pod" {
   depends_on = ["kubernetes_pod.network-pod"]

   provisioner "local-exec" {
        command = "kubectl  --kubeconfig=${var.cluster_config_path} cp  ${path.root}/keys network-pod:/opt/secure-perimeter/"
     }
   provisioner "local-exec" {
        command = "kubectl  --kubeconfig=${var.cluster_config_path} cp  ${path.root}/state.json network-pod:/opt/secure-perimeter/state.json"
     }
   provisioner "local-exec" {
        command = "kubectl  --kubeconfig=${var.cluster_config_path} cp ${path.root}/config.json network-pod:/opt/secure-perimeter/config.json"
     }
   provisioner "local-exec" {
        command = "kubectl  --kubeconfig=${var.cluster_config_path} cp ${path.root}/rules.conf network-pod:/opt/secure-perimeter/rules.conf"
     }

}
