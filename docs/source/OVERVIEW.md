# Terraform Modules: KMS

This module is maintained as part of the open-source [cumberland-cloud Github project](). This module is simple and straightforward. It will provision a **AWS KMS** key with a default policy that allows the administrator full read-write access to the key and all **IAM** users in the caller account to use the key for standard cryptographic operations. Additional statements can be merged into this default policy by passing in a secondary policy document. See table below for more information.

<!-- BEGIN_TF_DOCS -->
Terraform Docs Placeholder
<!-- END_TF_DOCS -->  