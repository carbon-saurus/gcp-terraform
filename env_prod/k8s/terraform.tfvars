project  = "carbon-re"
project_id  = "carbonsaurus-prod"
owner       = "youngbae.kwon"
env         = "prod"
region      = "asia-northeast3"
db_user           = "testuser"
db_password       = "passwd!!@@33"
domain_name = "carbonsaurus.net"
gcr_server = "https://gcr.io"
# office_ip   = "58.123.54.42/32"
admin_email = "youngbae.kwon@bespinglobal.com"

credentials_path = "../../credentials-prod.json"

applications = [
    "account-api",
    "scrap-api",
    "track-api",
    "carbontrack-fe",
    "admin-fe",
]