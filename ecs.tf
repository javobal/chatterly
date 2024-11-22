resource "aws_ecs_cluster" "chatterly" {
  name = "chatterly"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "chatterly" {
  cluster_name = aws_ecs_cluster.chatterly.name
}
