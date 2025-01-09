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

resource "aws_ecs_task_definition" "chatterly" {
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

resource "aws_ecs_service" "chatterly" {
  # From AWS's Console - ECS create service
  # Service Type (scheduling_strategy) : console defaults to "REPLICA"
  # deployment failure detection: console defaults to circuit breaker with rollback
  # deployment (deployment_controller): console defaults to rolling update, option blue green with code deploy.
  # load balancer (optional)
  # service discovery with route 53 or service connect (optional)

  name            = "chatterly"
  cluster         = aws_ecs_cluster.chatterly.id
  task_definition = aws_ecs_task_definition.chatterly.arn
  desired_count   = 1

  launch_type = "FARGATE"
  platform_version = "LATEST"

  scheduling_strategy = "REPLICA"

  network_configuration {
    subnets = data.aws_subnets.chatterly-private.ids
    #security_groups = 
    assign_public_ip = false
  }

  # If using awsvpc network mode, do not specify this role. 
  # If your account has already created the Amazon ECS service-linked role, 
  # that role is used by default for your service unless you specify a role her
  # iam_role        = aws_iam_role.foo.arn
  # depends_on      = [aws_iam_role_policy.foo]

  # has some conditions to work: REPLICA - FARGATE - placement strategy not set or first az based
  # more info: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-rebalancing.html?icmpid=docs_ecs_hp-service-rebalancing
  availability_zone_rebalancing = "ENABLED"

  deployment_controller {
    type = "ECS" # ECS uses CodePipeline, CODE_DEPLOY
  }
  
}
