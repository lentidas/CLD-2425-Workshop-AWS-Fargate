# Create an ECS cluster to run the containers.
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.name_prefix}-ecs-cluster"
}

# Create an IAM role for the ECS task execution.
# This role allows the ECS tasks to pull images from ECR and write logs to CloudWatch.
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.name_prefix}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

# Attach the necessary policies to the ECS task execution role, to allow ECS to contact other AWS services.
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_cloudwatch" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# Create a task definition for the container we will be running in ECS using Fargate compute.
resource "aws_ecs_task_definition" "task_definition" {
  family                   = "${var.name_prefix}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.name_prefix}-container"
      image     = var.container_image
      essential = true
      command = [
        "--verbose", # Enable verbose logging for the container to see the requests on the logs, to demonstrate the logging capabilities of the service.
      ]
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.name_prefix}-log-group"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
          "mode"                  = "non-blocking"
          "max-buffer-size"       = "25m"
        }
      }
    }
  ])
}

# Create a service in the ECS cluster to run the task definition created above.
resource "aws_ecs_service" "ecs_service" {
  name            = "${var.name_prefix}-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  availability_zone_rebalancing = "ENABLED"

  network_configuration {
    subnets          = data.aws_subnets.default_subnets.ids
    security_groups  = [aws_security_group.ec2_security_group.id]
    assign_public_ip = true
  }

  # Attach the load balancer target group to the ECS service.
  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "${var.name_prefix}-container"
    container_port   = 80
  }

  propagate_tags = "SERVICE"

  depends_on = [
    aws_lb_listener.http_listener,
  ]

  lifecycle {
    ignore_changes = [
      desired_count, # Ignore changes to desired count because it may be auto-scaled.
    ]
  }
}

# Create an Application Auto Scaling target for the ECS service.
resource "aws_appautoscaling_target" "autoscaling_target" {
  max_capacity       = 32
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Create an Application Auto Scaling policy for the ECS service to scale based on container's average used CPU.
# resource "aws_appautoscaling_policy" "autoscaling_target_policy_cpu" {
#   name               = "${var.name_prefix}-autoscaling-policy-cpu"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.autoscaling_target.resource_id
#   scalable_dimension = aws_appautoscaling_target.autoscaling_target.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.autoscaling_target.service_namespace

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageCPUUtilization"
#     }

#     target_value = 70
#   }
# }

# Create an Application Auto Scaling policy for the ECS service to scale based on container's average used memory.
# resource "aws_appautoscaling_policy" "autoscaling_target_policy_memory" {
#   name               = "${var.name_prefix}-autoscaling-policy-memory"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.autoscaling_target.resource_id
#   scalable_dimension = aws_appautoscaling_target.autoscaling_target.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.autoscaling_target.service_namespace

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageMemoryUtilization"
#     }

#     target_value = 80
#   }
# }

# Create an Application Auto Scaling policy for the ECS service to scale based on the average number of requests per target.
# This policy uses the Application Load Balancer's request count per target as the scaling metric and could even be
# used to scale the service to zero if desired.
# See: https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-target-tracking.html#target-tracking-choose-metrics
resource "aws_appautoscaling_policy" "autoscaling_target_policy_request_count" {
  name               = "${var.name_prefix}-autoscaling-policy-request-count"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.autoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.autoscaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.autoscaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    # https://registry.terraform.io/providers/hashicorp/aws/5.99.1/docs/resources/appautoscaling_policy#resource_label-2
    # https://docs.aws.amazon.com/autoscaling/plans/APIReference/API_PredefinedScalingMetricSpecification.html
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      # Please ignore the complex string manipulation below, but AWS requires the resource label to be in a very 
      # specific format that is not given by the other resources...
      resource_label = "${split("loadbalancer/", aws_lb.load_balancer.id)[1]}/${aws_lb_target_group.target_group.arn_suffix}"
    }

    # These autoscaling values are ridiculously low for a production service. They are set low to ensure that the 
    # service scales up quickly during the demonstration. Note that there is not even a scale-out/in cooldown period!
    target_value       = 10
    scale_in_cooldown  = 0
    scale_out_cooldown = 0
  }
}

