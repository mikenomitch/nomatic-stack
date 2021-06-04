locals {
  // general config values

  base_config_values = {
    use_docker           = var.use_docker
    use_nomad            = var.use_nomad
    use_consul           = var.use_consul
    use_consul_template  = var.use_consul_template
    use_vault            = var.use_vault
    datacenter           = var.region
    region               = var.region
    authoritative_region = var.authoritative_region
    replication_token    = var.replication_token
    retry_provider       = var.retry_join.provider
    retry_tag_key        = var.retry_join.tag_key
    retry_tag_value      = "${var.retry_join.tag_value_prefix}-${var.cluster_name}"
    rpc_port             = var.rpc_port
  }

  consul_base_config = merge(local.base_config_values, {
    desired_servers                = var.desired_servers
    consul_version                 = var.consul_version
    consul_template_service_config = local.consul_template_service_config
    consul_service_config          = local.consul_service_config
  })

  nomad_base_config = merge(local.base_config_values, {
    desired_servers      = var.desired_servers
    nomad_version        = var.nomad_version
    nomad_service_config = local.nomad_service_config
  })

  // serivce config files

  consul_service_config = templatefile(
    "${path.module}/templates/services/consul.service.tpl",
    {}
  )

  nomad_service_config = templatefile(
    "${path.module}/templates/services/nomad.service.tpl",
    {}
  )

  consul_template_service_config = templatefile(
    "${path.module}/templates/services/consul_template.service.tpl",
    {}
  )

  vault_service_config = templatefile(
    "${path.module}/templates/services/vault.service.tpl",
    {}
  )

  // serivce setup files

  docker_config = templatefile(
    "${path.module}/templates/docker.sh.tpl",
    {}
  )

  consul_server_config = templatefile(
    "${path.module}/templates/consul.sh.tpl",
    merge(local.consul_base_config, { is_server = true })
  )

  consul_client_config = templatefile(
    "${path.module}/templates/consul.sh.tpl",
    merge(local.consul_base_config, { is_server = false })
  )

  consul_template_config = templatefile(
    "${path.module}/templates/consul_template.sh.tpl",
    { consul_template_service_config = local.consul_template_service_config }
  )

  nomad_server_config = templatefile(
    "${path.module}/templates/nomad.sh.tpl",
    merge(local.nomad_base_config, { is_server = true })
  )

  nomad_client_config = templatefile(
    "${path.module}/templates/nomad.sh.tpl",
    merge(local.nomad_base_config, { is_server = false })
  )

  vault_config = templatefile(
    "${path.module}/templates/vault.sh.tpl",
    {
      vault_version        = var.vault_version
      vault_service_config = local.vault_service_config
    }
  )

  launch_base_user_data = merge(local.base_config_values, {
    consul_template_config         = local.consul_template_config
    docker_config                  = local.docker_config
    consul_template_service_config = local.consul_template_service_config
    vault_config                   = local.vault_config
  })
}

# VPC AND SUBNETS

resource "aws_vpc" "hashistack" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_classiclink   = false
  instance_tenancy     = "default"
}

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.hashistack.id
  cidr_block              = "10.0.10${count.index}.0/24"
  availability_zone       = var.availability_zones[var.region][count.index]
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "hashistack" {
  vpc_id = aws_vpc.hashistack.id
}

resource "aws_route_table" "hashistack" {
  vpc_id = aws_vpc.hashistack.id

  route {
    //associated subnet can reach everywhere
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hashistack.id
  }
}

resource "aws_route_table_association" "main" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.hashistack.id
}

# INSTANCES & CONFIG

resource "aws_launch_configuration" "hashistack_server_launch" {
  name_prefix   = "hashistack-server"
  image_id      = var.base_amis[var.region]
  instance_type = var.server_instance_type
  key_name      = var.key_name

  security_groups             = [aws_security_group.hashistack.id]
  associate_public_ip_address = var.associate_public_ip_address

  iam_instance_profile = aws_iam_instance_profile.auto-join.name

  user_data = templatefile(
    "${path.module}/templates/startup.sh.tpl",
    merge(local.launch_base_user_data, {
      consul_config = local.consul_server_config
      nomad_config  = local.nomad_server_config
      is_server     = true
    })
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "hashistack_client_launch" {
  name_prefix   = "hashistack-client"
  image_id      = var.base_amis[var.region]
  instance_type = var.client_instance_type
  key_name      = var.key_name

  security_groups             = [aws_security_group.hashistack.id]
  associate_public_ip_address = var.associate_public_ip_address

  iam_instance_profile = aws_iam_instance_profile.auto-join.name

  user_data = templatefile(
    "${path.module}/templates/startup.sh.tpl",
    merge(local.launch_base_user_data, {
      consul_config = local.consul_client_config
      nomad_config  = local.nomad_client_config
      is_server     = false
    })
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "hashistack_server_asg" {
  # availability_zones = var.availability_zones[var.region]
  desired_capacity = var.desired_servers
  max_size         = var.max_servers
  min_size         = var.min_servers

  tags = [
    {
      key                 = "Name"
      value               = "${var.cluster_name}-server"
      propagate_at_launch = true
    },
    {
      key                 = var.retry_join.tag_key
      value               = "${var.retry_join.tag_value_prefix}-${var.cluster_name}"
      propagate_at_launch = true
    }
  ]

  launch_configuration = aws_launch_configuration.hashistack_server_launch.name
  vpc_zone_identifier  = aws_subnet.public.*.id
}

resource "aws_autoscaling_group" "hashistack_client_asg" {
  # availability_zones = var.availability_zones[var.region]
  desired_capacity = var.desired_clients
  max_size         = var.max_servers
  min_size         = var.min_servers

  tags = [
    {
      key                 = "Name"
      value               = "${var.cluster_name}-client"
      propagate_at_launch = true
    },
    {
      key                 = var.retry_join.tag_key
      value               = "${var.retry_join.tag_value_prefix}-${var.cluster_name}"
      propagate_at_launch = true
    }
  ]

  launch_configuration = aws_launch_configuration.hashistack_client_launch.name
  vpc_zone_identifier  = aws_subnet.public.*.id
}

# LOAD BALANCING

# LOAD BALANCING - SERVERS

resource "aws_lb" "nomad_servers" {
  name            = "${var.cluster_name}-nomad-servers"
  security_groups = [aws_security_group.hashistack.id]
  subnets         = aws_subnet.public.*.id
  internal        = false
  idle_timeout    = 60
}

resource "aws_alb_target_group" "nomad_servers" {
  name     = "${var.cluster_name}-nomad-servers"
  port     = 4646
  protocol = "HTTP"
  vpc_id   = aws_vpc.hashistack.id

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 1800
    enabled         = true
  }

  # # TODO: CHANGE HC PATH
  # health_check {
  #   healthy_threshold   = 3
  #   unhealthy_threshold = 10
  #   timeout             = 5
  #   interval            = 10
  #   path                = "/"
  #   port                = 4646
  # }
}

resource "aws_lb_listener" "alb_listener_server" {
  load_balancer_arn = aws_lb.nomad_servers.arn
  port              = 4646
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.nomad_servers.arn
    type             = "forward"
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_server" {
  autoscaling_group_name = aws_autoscaling_group.hashistack_server_asg.id
  alb_target_group_arn   = aws_alb_target_group.nomad_servers.arn
}

# LOAD BALANCING - CLIENTS

resource "aws_lb" "nomad_clients" {
  name            = "${var.cluster_name}-nomad-clients"
  security_groups = [aws_security_group.hashistack.id]
  subnets         = aws_subnet.public.*.id
  internal        = false
  idle_timeout    = 60
}

resource "aws_alb_target_group" "nomad_clients" {
  name     = "${var.cluster_name}-nomad-clients"
  port     = 4646
  protocol = "HTTP"
  vpc_id   = aws_vpc.hashistack.id

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 1800
    enabled         = true
  }

  # # TODO: CHANGE HC PATH
  # health_check {
  #   healthy_threshold   = 3
  #   unhealthy_threshold = 10
  #   timeout             = 5
  #   interval            = 10
  #   path                = "/"
  #   port                = 4646
  # }
}

resource "aws_lb_listener" "alb_listener_client" {
  load_balancer_arn = aws_lb.nomad_clients.arn
  port              = 4646
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.nomad_clients.arn
    type             = "forward"
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_clients" {
  autoscaling_group_name = aws_autoscaling_group.hashistack_client_asg.id
  alb_target_group_arn   = aws_alb_target_group.nomad_clients.arn
}
