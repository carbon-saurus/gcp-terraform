variable "secret_id" {
  type = string
  description = "Secret Manager에 저장될 Secret의 ID"
}

variable "secret_data" {
  type = string
  description = "Secret Manager에 저장될 Secret 데이터"
  sensitive = true
}