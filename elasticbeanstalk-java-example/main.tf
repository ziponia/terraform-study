# Elasticbeanstalk
# see https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/command-options-general.html
provider "aws" {
  region = "ap-northeast-2"
  shared_credentials_file = "~/.aws/credentials"
  profile = var.aws-profile
}

# 애플리케이션 설정
resource "aws_elastic_beanstalk_application" "app" {

  name = var.app-name
  description = "application for ${var.app-name}"
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
    name = "IamInstanceProfile"
    namespace = "aws:autoscaling:launchconfiguration"
    value = "aws-elasticbeanstalk-ec2-role"
  }

  # 로드밸런서
  setting {
    name = "LoadBalancerType"
    namespace = "aws:elasticbeanstalk:environment"
    value = "application"
  }

  # 인스턴스 타입
  setting {
    name = "InstanceTypes"
    namespace = "aws:ec2:instances"
    value = "t2.micro"
  }

  # helthcheck endpoint
  setting {
    name = "Application Healthcheck URL"
    namespace = "aws:elasticbeanstalk:application"
    value = "/actuator/health"
  }
}