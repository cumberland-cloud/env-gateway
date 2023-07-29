# Environment: Gateway

[![terraform workflows](https://github.com/cumberland-cloud/env-gateway/actions/workflows/action.yaml/badge.svg)](https://github.com/cumberland-cloud/env-gateway/actions/workflows/action.yaml)

[![pages-build-deployment](https://github.com/cumberland-cloud/env-gateway/actions/workflows/pages/pages-build-deployment/badge.svg)](https://github.com/cumberland-cloud/env-gateway/actions/workflows/pages/pages-build-deployment)

A Terraform project for deploying the infrastructure that supports the [Cumberland Cloud Gateway]().

Refer to [hosted docs](https://cumberland-cloud.github.io/env-gateway/) for more information regarding this project.

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
