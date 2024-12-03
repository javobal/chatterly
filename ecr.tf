resource "aws_ecr_repository" "chatterly" {
  name                 = "chatterly/service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
