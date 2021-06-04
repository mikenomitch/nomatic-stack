data "aws_instances" "server_meta" {
  instance_tags = {
    Name = "${var.cluster_name}-server"
  }
}

data "aws_instances" "client_meta" {
  instance_tags = {
    Name = "${var.cluster_name}-client"
  }
}

output "consul-server-addr" {
  value = "http://${element(data.aws_instances.server_meta.public_ips, 0)}:8500"
}

output "nomad-server-addr" {
  value = "http://${element(data.aws_instances.server_meta.public_ips, 0)}:4646"
}

output "nomad-client-addr" {
  value = "http://${element(data.aws_instances.client_meta.public_ips, 0)}"
}
