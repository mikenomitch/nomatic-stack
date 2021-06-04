# Terraform AWS Hashistack

This is a terraform module for setting up a Hashistack on AWS.

The HashiStack consists of Consul, Vault, and Nomad on infrastructure
launched by Terraform.

After a short initial setup a user is able to deploy
containerized applications to a Nomad cluster.

### Usage

- Get credentials for an AWS account.
- `export AWS_ACCESS_KEY_ID=${YOUR_ACCESS_KEY}`
- `export AWS_SECRET_ACCESS_KEY=${YOUR_SECRET_KEY}`
- `terraform apply` (this will take several minutes)
- Access your Hashistack via EC2.
- If running in production, ensure that security groups are restricted beyond the default setup.

### Dependencies

- Terraform 12+
- AWS Account Key and Secret

### Remaining Todos

- Write out How to Use Docs
  - Variables necessary
  - Commands for ssh-ing
  - Commands for accessing
  - Commands for running nomad
  - Use TF output if possible
- Ensure vault and nomad integration works properly
- Config Audit

### ~~Plagiarized from~~ Inspired By

- https://github.com/hashicorp/nomad/tree/master/terraform
- https://github.com/nicholasjackson/terraform-aws-hashicorp-suite
- https://github.com/hashicorp/terraform-guides/tree/master/infrastructure-as-code/hashistack
