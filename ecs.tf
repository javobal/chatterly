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

resource "aws_ecs_task_definition" "service" {
  family = "chatterly"
  execution_role_arn = "arn:aws:iam::655757912437:role/ecsTaskExecutionRole"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512

  runtime_platform {
      cpu_architecture = "X86_64"
      operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name      = "chatterly-service"
      image     = "655757912437.dkr.ecr.us-east-1.amazonaws.com/chatterly/service:1"
      cpu       = 256
      memory    = 512
      essential = true
      memoryReservation = 512
      portMappings = [
        {
            name= "chatterly-service-80-tcp"
            containerPort= 80
            hostPort= 80
            protocol= "tcp"
            appProtocol= "http"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
            awslogs-group= "/ecs/chatterly"
            mode= "non-blocking"
            awslogs-create-group= "true"
            max-buffer-size= "25m"
            awslogs-region= "us-east-1"
            awslogs-stream-prefix= "ecs"
        }
      },
    }
  ])
}