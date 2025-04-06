##############################
### Bastion 서버 (Compute Instance) ###
##############################
# # Console에서 고정 IP를 생성한 경우
# data "google_compute_address" "existing_static_ip" {
#   name    = "${var.instance_name}-static-ip}" # 콘솔에서 확인한 고정 IP 주소의 이름
#   project = var.project_id                    # 해당 IP가 있는 프로젝트 ID
# }

# # 테라폼에서 고정 외부 IP 주소 예약
# resource "google_compute_address" "static_external_ip" {
#   name    = "${var.instance_name}-external-ip"

#   lifecycle {
#     prevent_destroy = true # 이 IP 리소스는 destroy 시 삭제하지 않음
#   }
# }


# GCP에서는 instance의 network_interface 내 access_config 블럭을 사용하면 외부 IP가 자동 할당됩니다.
resource "google_compute_instance" "vm" {
  name         = var.instance_name
  machine_type = var.machine_type     # AWS의 t3.micro와 유사한 머신 타입 선택
  zone         = var.zone # 첫 번째 가용영역 사용

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  network_interface {
    network = var.network_id
    subnetwork = var.subnet_id
    # network_ip = "10.0.3.100"
    access_config {}  # 외부 IP 자동 할당

    # 고정 IP 사용시 주석 제거
    # access_config {
    #   nat_ip = data.google_compute_address.existing_static_ip.address   // console static ip
    #   nat_ip = google_compute_address.static_external_ip.address        // terraform static ip
    # }

  }
  # SSH Public Key를 메타데이터에 등록 (var.ssh_public_key 는 로컬 파일 경로로 지정)
  metadata = merge(

    var.install_gcloud ? {
      # 올바른 키: startup-script
      startup-script = <<-EOT
        #!/bin/bash
        echo "Starting gcloud, kubectl, and Terraform installation..."
        # 패키지 목록 업데이트
        sudo apt-get update -y

        # Google Cloud SDK 저장소 키 및 소스 목록 추가 (최신 방식 권장)
        sudo apt-get install -y apt-transport-https ca-certificates gnupg curl
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list

        # Terraform 설치를 위한 HashiCorp GPG 키 추가 및 저장소 추가
        curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

        # 저장소 추가 후 패키지 목록 다시 업데이트
        sudo apt-get update -y

        # 필요한 패키지 설치
        sudo apt-get install -y google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin kubectl terraform

        echo "Installation complete."
      EOT
    } : {
      # var.install_gcloud가 false일 때의 startup-script (선택 사항)
      startup-script = "#!/bin/bash\n echo 'gcloud, kubectl, and Terraform installation skipped.'"
    },
    var.install_gcloud ? {
      ssh-keys = join("\n", [
        for dev_id in var.developer_ids :
        format("%s:%s", dev_id, var.ssh_pub_key)
      ])
    } : {} 
  )

  tags = ["${var.project}-${var.env}-general-fw"]

}