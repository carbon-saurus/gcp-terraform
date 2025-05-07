project  = "carbon-re"
project_id  = "carbonsaurus-dev"
owner       = "kkardd"
env         = "test"
region      = "asia-northeast3"
zone        = "asia-northeast3-a"

db_instance_name  = "carbon-re-test-db"
db_name           = "track"
db_user           = "postgresql"
db_password       = "_0AA?>[*X80L*CKO<u{al|W]Ld>y"

domain_name = "test.carbontrack.app"

office_ip   = "58.123.54.42/32"

credentials_path = "../credentials.json"


applications = [
    "webapp", 
    "accounting-service",
    "auth-service"
]