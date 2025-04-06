resource "google_secret_manager_secret" "secret" {
  secret_id = var.secret_id

  replication {
    auto {}
  }

  # replication {
  #   user_managed {
  #     replicas {
  #       location = var.region # 원하는 리전으로 변경
  #     }
  #   }
  # }
}

resource "google_secret_manager_secret_version" "secret_version" {
  secret      = google_secret_manager_secret.secret.id
  secret_data = var.secret_data
}



