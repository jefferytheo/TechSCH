# Elastic Container Repository

resource "aws_ecr_repository" "capstone_ecr_repository" {
  name = var.prj_capstone_ecr_name
}

resource "aws_ecr_lifecycle_policy" "capstone_ecr_pol" {
  repository = aws_ecr_repository.capstone_ecr_repository.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 90 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 90
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

# IAM User
data "aws_iam_user" "user_adeolu" {
  user_name = "adeolu"
}

# IAM Policy for Repository
data "aws_iam_policy_document" "capstone_iam_repo_pol" {
  statement {
    sid    = "ecr repo policy"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_user.user_adeolu.id]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DeleteRepository",
      "ecr:BatchDeleteImage",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy",
    ]
  }
}

resource "aws_ecr_repository_policy" "capstone_ecr_pol" {
  repository = aws_ecr_repository.capstone_ecr_repository.name
  policy     = data.aws_iam_policy_document.capstone_iam_repo_pol.json
}

# ECS Task Role
data "aws_iam_role" "capstone_ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

# resource "aws_iam_role" "capstone_ecs_role" {
#   name = "capstone_ecs_role"

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   assume_role_policy = jsonencode({
#     Version: "2012-10-17",
#     Statement: [
#         {
#           Effect: "Allow",
#           Action: [
#               "ecr:GetAuthorizationToken",
#               "ecr:BatchCheckLayerAvailability",
#               "ecr:GetDownloadUrlForLayer",
#               "ecr:BatchGetImage",
#               "logs:CreateLogStream",
#               "logs:PutLogEvents"
#           ],
#           Resource: "*"
#         }
#       ]
#   })

#   tags = {
#     tag-key = "capstone-ecs-task-key"
#   }
# }

# Elastic Container Service Cluster
resource "aws_ecs_cluster" "capstone_ecs_cluster" {
  name = "capstone-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_cp" {
  cluster_name = aws_ecs_cluster.capstone_ecs_cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

#Task Definition
resource "aws_ecs_task_definition" "capstone_td" {
  family                   = "capstone_td"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = data.aws_iam_role.capstone_ecs_task_execution_role.arn
  cpu                      = 1024
  memory                   = 2048
  container_definitions    = <<TASK_DEFINITION
[
  {
    "name": "capstone-easy-school",
    "image": "${aws_ecr_repository.capstone_ecr_repository.repository_url}:latest",
    "cpu": 1024,
    "memory": 2048,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
  }
]
TASK_DEFINITION

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

# ECS Service

# data "aws_iam_policy" "example" {
#   name = "test_policy"
# }

resource "aws_ecs_service" "capstone_service" {
  name            = "easy-school"
  cluster         = aws_ecs_cluster.capstone_ecs_cluster.id
  task_definition = aws_ecs_task_definition.capstone_td.arn
  launch_type = "FARGATE"
  platform_version = "LATEST"
  desired_count   = 3
  #iam_role        = data.aws_iam_role.capstone_ecs_task_execution_role.arn
  #force_delete = true
  #depends_on      = [aws_iam_role_policy.capstone_ecs_role]

  network_configuration {
    subnets = [var.prj_capstone_sub_id, var.prj_capstone_sub_secondary_id]
    security_groups = [var.prj_capstone_sg_id]
    assign_public_ip = true
  }
  
  load_balancer {
    target_group_arn = var.prj_capstone_alb_tg_arn
    container_name   = "capstone-easy-school"
    container_port   = 80
  }

}