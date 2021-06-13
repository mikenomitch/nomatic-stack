// == TOOLS ==

variable "use_docker" {
  type    = bool
  default = true
}

variable "use_consul" {
  type    = bool
  default = true
}

variable "use_consul_template" {
  type    = bool
  default = true
}

variable "use_nomad" {
  type    = bool
  default = true
}

variable "use_vault" {
  type    = bool
  default = true
}

// == VERSIONS ==

variable "consul_version" {
  type    = string
  default = "1.9.5"
}

variable "nomad_version" {
  type    = string
  default = "1.1.1"
}

variable "vault_version" {
  type    = string
  default = "1.7.1"
}

// == HIGH LEVEL AWS INFO ==

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "authoritative_region" {
  type    = string
  default = "us-east-1"
}

variable "replication_token" {
  type    = string
  default = ""
}

variable "availability_zones" {
  type = map(any)

  default = {
    "us-east-1" = ["us-east-1a", "us-east-1b"],
    "us-west-2" = ["us-west-2a"]
  }

  description = "The id of the machine image (AMI) to use for the server. Ubuntu 20.04 LTS AMD 64"
}

// PORTS

variable "serf_port" {
  type    = string
  default = "4648"
}

variable "ssh_port" {
  type    = string
  default = "22"
}

variable "rpc_port" {
  type    = string
  default = "8502"
}

variable "http_port_from" {
  type    = string
  default = "80"
}

variable "http_port_to" {
  type    = string
  default = "65535"
}

// CIDR

variable "whitelist_ip" {
  type    = string
  default = "0.0.0.0/0"
}

// == ALB ==

variable "base_amis" {
  type = map(any)

  default = {
    "us-east-1" = "ami-0745d55d209ff6afd"
    "us-west-2" = "ami-089668cd321f3cf82"
  }

  description = "The id of the machine image (AMI) to use for the server. Ubuntu 20.04 LTS AMD 64"
}

variable "key_name" {
  type    = string
  default = "nomad"
}

variable "server_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "client_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "desired_servers" {
  type    = number
  default = 1
}

variable "desired_clients" {
  type    = number
  default = 1
}

variable "max_servers" {
  type    = number
  default = 3
}

variable "min_servers" {
  type    = number
  default = 0
}

variable "cluster_name" {
  type    = string
  default = "hashistack"
}

variable "associate_public_ip_address" {
  type    = bool
  default = true
}

// == SERVER DATA ==

variable "retry_join" {
  type = map(any)

  default = {
    provider  = "aws"
    tag_key   = "ConsulAutoJoin"
    tag_value_prefix = "auto-join"
  }
}

// == SERVER DATA ==

variable "ecs_task_definition_file" {
  description = "The file that contains the ECS task definition, used as a deployment/update trick."
  type        = string
  default     = "./ecs/base.json"
}
