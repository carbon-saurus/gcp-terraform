project  = "carbon-re"
project_id  = "carbonsaurus-dev"
owner       = "youngbae_kwon"
env         = "test"
region      = "asia-northeast3"
zone        = "asia-northeast3-a"
# cluster_name      = "hello-gke-cluster"
db_instance_name  = "carbon-re-dev-db"
db_name           = "scrap"
db_user           = "postgresql"
db_password       = "_0AA?>[*X80L*CKO<u{al|W]Ld>y"
domain_name = "test.carbontrack.app"
office_ip   = "165.225.229.31/32"
# office_ip   = "58.151.93.2/32"

credentials_path = "/home/youngbae_kwon/carbon_dev/credentials.json"


applications = [
    "webapp", 
    "accounting-service",
    "auth-service"
]