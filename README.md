# Environment: Gateway

A Terraform project for deploying the infrastructure that supports the [Cumberland Cloud Gateway]().

Refer to [hosted docs]() for more information regarding this project.

## Quickstart

```shell
terraform init -upgrade -backend-config="key=gateway/terraform.tfstate"
terraform plan 
terraform apply
```

### Build the Docs

```shell
cd docs
pip install -r requirements.txt
make html
```