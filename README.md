<!-- BEGIN_TF_DOCS -->
# EKS with Windows Terraform module

![ci workflow](https://github.com/1nval1dctf/terraform-aws-eks-windows/actions/workflows/ci.yml/badge.svg)
Terraform module to deploy EKS with Windows support


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.38 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.12.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.26.0 |
## Providers

No providers.
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | Region to deploy EKS Cluster into | `string` | `"us-east-1"` | no |
| <a name="input_eks_autoscaling_group_linux_desired_capacity"></a> [eks\_autoscaling\_group\_linux\_desired\_capacity](#input\_eks\_autoscaling\_group\_linux\_desired\_capacity) | Desired capacity for Linux nodes for the EKS. | `number` | `1` | no |
| <a name="input_eks_autoscaling_group_linux_max_size"></a> [eks\_autoscaling\_group\_linux\_max\_size](#input\_eks\_autoscaling\_group\_linux\_max\_size) | Minimum number of Linux nodes for the EKS. | `number` | `2` | no |
| <a name="input_eks_autoscaling_group_linux_min_size"></a> [eks\_autoscaling\_group\_linux\_min\_size](#input\_eks\_autoscaling\_group\_linux\_min\_size) | Minimum number of Linux nodes for the EKS. | `number` | `1` | no |
| <a name="input_eks_autoscaling_group_windows_desired_capacity"></a> [eks\_autoscaling\_group\_windows\_desired\_capacity](#input\_eks\_autoscaling\_group\_windows\_desired\_capacity) | Desired capacity for Windows nodes for the EKS. | `number` | `1` | no |
| <a name="input_eks_autoscaling_group_windows_max_size"></a> [eks\_autoscaling\_group\_windows\_max\_size](#input\_eks\_autoscaling\_group\_windows\_max\_size) | Maximum number of Windows nodes for the EKS. | `number` | `2` | no |
| <a name="input_eks_autoscaling_group_windows_min_size"></a> [eks\_autoscaling\_group\_windows\_min\_size](#input\_eks\_autoscaling\_group\_windows\_min\_size) | Minimum number of Windows nodes for the EKS | `number` | `1` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | Name for the EKS Cluster | `string` | `"eks"` | no |
| <a name="input_eks_cluster_version"></a> [eks\_cluster\_version](#input\_eks\_cluster\_version) | Kubernetes version for the EKS cluster | `string` | `"1.29"` | no |
| <a name="input_eks_linux_instance_type"></a> [eks\_linux\_instance\_type](#input\_eks\_linux\_instance\_type) | Instance size for EKS worker nodes. | `string` | `"m5.large"` | no |
| <a name="input_eks_users"></a> [eks\_users](#input\_eks\_users) | Additional AWS users to add to the EKS aws-auth configmap. | <pre>list(object({<br>    userarn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_eks_windows_instance_type"></a> [eks\_windows\_instance\_type](#input\_eks\_windows\_instance\_type) | Instance size for EKS windows worker nodes. | `string` | `"m5.large"` | no |
| <a name="input_enable_cloudwatch_exported"></a> [enable\_cloudwatch\_exported](#input\_enable\_cloudwatch\_exported) | Enable cloudwatch exporter | `bool` | `true` | no |
| <a name="input_enable_cluster_autoscaler"></a> [enable\_cluster\_autoscaler](#input\_enable\_cluster\_autoscaler) | Enable cluster autoscaler | `bool` | `true` | no |
| <a name="input_enable_loadbalancer_controler"></a> [enable\_loadbalancer\_controler](#input\_enable\_loadbalancer\_controler) | Enable ALB load Balancer controller | `bool` | `true` | no |
| <a name="input_enable_metrics_server"></a> [enable\_metrics\_server](#input\_enable\_metrics\_server) | Install metrics server into the cluster | `bool` | `true` | no |
| <a name="input_external_dns_support"></a> [external\_dns\_support](#input\_external\_dns\_support) | Setup IAM, service accounts and cluster role for external\_dns in EKS | `bool` | `false` | no |
| <a name="input_vpc_cidr_private_subnets"></a> [vpc\_cidr\_private\_subnets](#input\_vpc\_cidr\_private\_subnets) | private subnets in the main CIDR block for the VPC. | `list(string)` | <pre>[<br>  "10.0.1.0/24",<br>  "10.0.2.0/24",<br>  "10.0.3.0/24"<br>]</pre> | no |
| <a name="input_vpc_cidr_public_subnets"></a> [vpc\_cidr\_public\_subnets](#input\_vpc\_cidr\_public\_subnets) | private subnets in the main CIDR block for the VPC. | `list(string)` | <pre>[<br>  "10.0.4.0/24",<br>  "10.0.5.0/24",<br>  "10.0.6.0/24"<br>]</pre> | no |
| <a name="input_windows_ami_type"></a> [windows\_ami\_type](#input\_windows\_ami\_type) | AMI type for the Windows Nodes. | `string` | `"WINDOWS_CORE_2022_x86_64"` | no |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks_cluster_certificate_authority_data"></a> [eks\_cluster\_certificate\_authority\_data](#output\_eks\_cluster\_certificate\_authority\_data) | EKS cluster CA |
| <a name="output_eks_cluster_endpoint"></a> [eks\_cluster\_endpoint](#output\_eks\_cluster\_endpoint) | EKS cluster endpoint |
| <a name="output_eks_cluster_name"></a> [eks\_cluster\_name](#output\_eks\_cluster\_name) | EKS cluster ID |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | kubeconfig for the AWS EKS cluster |
| <a name="output_load_balancer_controller_helm_release_version"></a> [load\_balancer\_controller\_helm\_release\_version](#output\_load\_balancer\_controller\_helm\_release\_version) | Load Balancer controller helm release version. Depend on this in your kubernetes deployments if you use services with load balacers and want to be able to destroy from a single terraform deploymemt |
| <a name="output_network_polices_enabled"></a> [network\_polices\_enabled](#output\_network\_polices\_enabled) | Denotes if network policies where enabled |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | List of private subnets that contain backend infrastructure (RDS, ElastiCache, EC2) |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | List of public subnets that contain frontend infrastructure (ALB) |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | Id for the VPC created for CTFd |

## Examples
### Simple

```hcl
terraform {
  required_version = ">= 1.7.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.38"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "eks_windows" {
  source = "../../" # Actually set to "1nval1dctf/eks-windows/aws"
}
```

## Building / Contributing

### Install prerequisites

#### Golang

```bash
wget https://go.dev/dl/go1.22.0.darwin-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.22.0.darwin-amd64.tar.gz
rm go1.22.0.darwin-amd64.tar.gz
```
Add /usr/local/go/bin to the PATH environment variable

#### Terraform

```bash
LATEST_URL=$(curl https://releases.hashicorp.com/terraform/index.json | jq -r '.versions[].builds[].url | select(.|test("alpha|beta|rc")|not) | select(.|contains("linux_amd64"))' | sort -t. -k 1,1n -k 2,2n -k 3,3n | tail -1)
curl ${LATEST_URL} > /tmp/terraform.zip
(cd /tmp && unzip /tmp/terraform.zip && chmod +x /tmp/terraform && sudo mv /tmp/terraform /usr/local/bin/)
```

#### Pre-commit and tools

Follow: https://github.com/antonbabenko/pre-commit-terraform#how-to-install

### Run tests

Default tests will deploy to AWS.
```bash
make
```

> :warning: **Warning**: This will spin up EKS and other services in AWS which will cost you some money.
<!-- END_TF_DOCS -->
