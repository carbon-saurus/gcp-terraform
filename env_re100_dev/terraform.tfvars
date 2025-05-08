project  = "re100"
project_id  = "re100-dev"
owner       = "tkkim"
env         = "dev"
region      = "asia-northeast3"
zone        = "asia-northeast3-a"

db_instance_name  = "re100-dev-db"
db_name           = "re100"
db_user           = "postgres"
# db_password는 환경 변수 TF_VAR_db_password로 제공

domain_name = "re100-dev.carbonsaurus.net"

office_ip   = "58.123.54.42/32"

# credentials_path는 환경 변수 TF_VAR_credentials_path로 제공
# 또는 GOOGLE_APPLICATION_CREDENTIALS 환경 변수 사용


applications = []