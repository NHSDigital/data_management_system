packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "vpc_tag_name" {
  type    = string
  default = "vpc-eu-west-2-development-dms-network"
}

variable "base_image_id" {
  type    = string
  default = "ami-01561389f1ce8bf53"
}

variable "subnet_tier" {
  type    = string
  default = "private"
}

variable "security_group_filter" {
  type    = string
  default = "vpc-eu-west-2-development-dms-network"
}

variable "ami_prefix" {
  type    = string
  default = "dms"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "commit_hash" {
  type    = string
  default = "-----no commit----"
}

variable "root_volume_size_gb" {
  type = number
  default = 10
}


variable "xvdb_volume_size_gb" {
  type = number
  default = 40
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "linux2" {
  ami_name      = "${var.ami_prefix}-${local.timestamp}"
  instance_type = "t2.medium"
  region        = "${var.aws_region}"

  launch_block_device_mappings {
    device_name = "/dev/xvda"
    volume_size = "${var.root_volume_size_gb}"
    volume_type = "gp3"
    iops = 3000
    throughput = 125
    delete_on_termination = true
    encrypted = true
  }

  launch_block_device_mappings {
    device_name = "/dev/xvdb"
    encrypted = true
    volume_size = "${var.xvdb_volume_size_gb}"
    volume_type = "gp3"
    iops = 3000
    throughput = 125
    delete_on_termination = true
  }
/*
  ami_block_device_mappings {
    device_name  = "/dev/xvdc"
    virtual_name = "ephemeral0"
    volume_size  = "${var.sdb_volume_size_gb}"
  } */

  vpc_filter {
    filters = {
      "tag:Name"  = "${var.vpc_tag_name}",
      "isDefault" = "false"
    }
  }

  subnet_filter {
    filters = {
      "state" : "available",
      "tag:Role" : "${var.subnet_tier}"
    }
    random = true
  }

  security_group_filter {
    filters = {
      "tag:Name" : "${var.security_group_filter}"
    }
  }

  source_ami_filter {
    filters = {
      image-id            = "${var.base_image_id}"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["self"]
  }

  source_ami     = "${var.base_image_id}"

  communicator   = "ssh"
  ssh_username   = "ec2-user"
  ssh_interface  = "session_manager"
  iam_instance_profile = "ssm-iam-dms-eu-west-2-development-instance"

  tags = {
    Environment     = "dev"
    Name            = "DmsImage"
    PackerBuilt     = "true"
    PackerTimestamp = regex_replace(timestamp(), "[- TZ:]", "")
    Service         = "DMS"
    Version         = "latest"
    CommitHash      = "${var.commit_hash}"
    BaseImage       = "${var.base_image_id}"
  }

  aws_polling {
    delay_seconds = 60
    max_attempts = 60
  }
}

build {
  name = "packer-dms-build"
  sources = [
    "source.amazon-ebs.linux2"
  ]

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install ruby -y",
      "sudo yum install wget -y",
      "wget https://aws-codedeploy-eu-west-2.s3.eu-west-2.amazonaws.com/latest/install",
      "chmod +x ./install",
      "sudo ./install auto"
    ]
  }

  provisioner "ansible" {
      playbook_file = "ansible/setup-server.yml"
      extra_arguments = ["-v", "--ssh-extra-args", "-o IdentitiesOnly=yes -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa"]
  }
}