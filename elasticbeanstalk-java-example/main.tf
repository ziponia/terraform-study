# Elasticbeanstalk
# see https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/command-options-general.html
provider "aws" {
  region                  = "ap-northeast-2"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = var.aws-profile
}

# 애플리케이션 설정
resource "aws_elastic_beanstalk_application" "app" {

  name        = var.app-name
  description = "application for ${var.app-name}"
}

# aws vpc 설정
# resource "aws_vpc" "main" {
#   cidr_block = "10.0.0.0/16"
# }

# 방화벽 설정
resource "aws_security_group" "app-server" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  # vpc_id      = aws_vpc.main.id

  ingress {
    description = "http port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "https port"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 로드 밸런서 설정
resource "aws_lb" "app-loadbalencer" {
  name               = var.loadbalencer-name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app-server.id]

  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}

# 환경 설정
resource "aws_elastic_beanstalk_environment" "app-env" {
  # 환경이름
  name = "${var.app-name}-env"
  # 종속된 애플리케이션
  application = aws_elastic_beanstalk_application.app.name

  # 솔루션 스택
  # https://docs.aws.amazon.com/cli/latest/reference/elasticbeanstalk/list-available-solution-stacks.html
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.10.10 running Java 8"



  # https://stackoverflow.com/a/51621116
  setting {
    name      = "IamInstanceProfile"
    namespace = "aws:autoscaling:launchconfiguration"
    value     = "aws-elasticbeanstalk-ec2-role"
  }

  # 로드밸런서
  setting {
    name      = "LoadBalancerType"
    namespace = "aws:elasticbeanstalk:environment"
    value     = "application"
  }

  # 인스턴스 타입
  setting {
    name      = "InstanceTypes"
    namespace = "aws:ec2:instances"
    value     = "t2.micro"
  }

  # helthcheck endpoint
  setting {
    name      = "Application Healthcheck URL"
    namespace = "aws:elasticbeanstalk:application"
    value     = "/actuator/health"
  }

  # setting {
  #   namespace = "aws:ec2:vpc"
  #   name      = "VPCId"
  #   value     = aws_vpc.main.id
  # }

  # spring boot env
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SPRING_PROFILES_ACTIVE"
    value     = "production"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SERVER_PORT"
    value     = "5000"
  }

  # 오토스케일링 (최대)
  setting {
    name      = "MaxSize"
    namespace = "aws:autoscaling:asg"
    value     = "10"
  }

  # 오토스케일링 (최소)
  setting {
    name      = "MinSize"
    namespace = "aws:autoscaling:asg"
    value     = "1"
  }
}
