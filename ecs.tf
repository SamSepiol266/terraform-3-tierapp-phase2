# --- 1. ECS Cluster ---
resource "aws_ecs_cluster" "main" {
  name = "my-3-tier-app-cluster"

  tags = {
    Environment = "Test-GitOps"
  }
}

# --- 2. IAM Roles (Permissions) ---
# Role for the ECS Agent (to pull images from ECR and send logs)
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- 3. Security Groups ---
# ALB Security Group: Allow traffic from the world on port 80
resource "aws_security_group" "lb_sg" {
  name        = "load-balancer-sg"
  description = "Allow port 80"
  # CHECK THIS REFERENCE: Must match your VPC resource name
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Task Security Group: Allow traffic ONLY from the ALB
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "ecs-tasks-sg"
  description = "Allow traffic from ALB"
  # CHECK THIS REFERENCE
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- 4. Load Balancer (ALB) ---
resource "aws_lb" "main" {
  name               = "my-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  # CHECK THIS REFERENCE: Must match your public subnets
  subnets = module.vpc.public_subnet_ids
}

resource "aws_lb_target_group" "app_tg" {
  name        = "my-app-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  # CHECK THIS REFERENCE
  vpc_id = module.vpc.vpc_id

  health_check {
    path = "/"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# --- 5. Task Definition (The Blueprint) ---
resource "aws_ecs_task_definition" "app" {
  family                   = "my-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name = "my-app-container"
    # Requires ecr.tf to exist
    image     = "${aws_ecr_repository.app_repo.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}

# --- 6. ECS Service (The Running App) ---
resource "aws_ecs_service" "main" {
  name            = "my-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    # Using public subnets for simpler demo connectivity
    subnets          = module.vpc.public_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "my-app-container"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.front_end]
}
