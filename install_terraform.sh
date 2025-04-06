#!/bin/bash

# 현재 테라폼 버전 확인
current_version=$(terraform version | head -n1 | cut -d 'v' -f2)
required_version="1.11.0"

# 버전 비교 함수
version_compare() {
    echo "$1 $2" | awk '{
        split($1, a, ".")
        split($2, b, ".")
        for (i=1; i<=3; i++) {
            if (a[i] < b[i]) exit 1
            if (a[i] > b[i]) exit 0
        }
        exit 0
    }'
}

echo "현재 Terraform 버전: v${current_version}"
echo "필요한 Terraform 버전: v${required_version}"

if version_compare "$current_version" "$required_version"; then
    echo "현재 버전이 이미 요구사항을 충족합니다."
else
    echo "Terraform 업그레이드가 필요합니다..."
    echo "Terraform 업그레이드를 시작합니다..."
    
    # HashiCorp GPG 키 다운로드 및 설치
    if ! wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg; then
        echo "GPG 키 다운로드 실패"
        return 1
    fi
    
    # apt 저장소 추가
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
    
    # apt 업데이트 및 Terraform 설치
    sudo apt-get update
    sudo apt-get install -y terraform

    # 설치 후 버전 확인
    new_version=$(terraform version | head -n1 | cut -d 'v' -f2)
    echo "업그레이드된 Terraform 버전: v${new_version}"    
fi    

export GOOGLE_CREDENTIALS="/home/youngbae_kwon/carbon_dev/credentials.json" # 실제 경로로 변경
echo "GOOGLE_CREDENTIALS 환경 변수가 설정되었습니다."
