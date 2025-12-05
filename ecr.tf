resource "aws_ecr_repository" "app_repo" {
  name                 = "my-3-tier-app-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Allows destroying repo even if it has images

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Output the URL so GitHub Actions knows where to push
output "ecr_repository_url" {
  value = aws_ecr_repository.app_repo.repository_url
}
