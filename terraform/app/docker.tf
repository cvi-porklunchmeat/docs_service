data "aws_ecr_repository" "this" {
  name       = "${lower(var.namespace)}-${lower(var.reponame)}"
  depends_on = [aws_ecr_repository.this]
}

resource "docker_image" "this" {
  name         = "${data.aws_ecr_repository.this.repository_url}:${var.git_sha}"
  keep_locally = false
  force_remove = true
  build {
    context  = "../../"
    platform = "linux/amd64"
    remove   = false
    tag = [
      "${data.aws_ecr_repository.this.name}:latest"
    ]
    cache_from = ["${data.aws_ecr_repository.this.repository_url}:latest"]
  }
  depends_on = [aws_ecr_repository.this]
}

# Push image to ECR
resource "docker_registry_image" "this" {
  name          = docker_image.this.name
  keep_remotely = false
  depends_on    = [aws_ecr_repository.this]
}
