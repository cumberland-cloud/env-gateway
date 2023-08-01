# Environment: API Gateway

This project encompasses the backend system deployment for the [Cumberland Cloud](). The resources which are deployed mainly support an [API gateway]() with [Lambda function integrations](). This includes all of the **IAM** roles and policies, artifact repositories and other various components that are required for a complete environment.

## Namespaces

The actual application components (i.e. **Lambda**, **API Gateway** resource and gateways, etc.) are configured using the dictionary in `local_namespace.tf`. This data structure acts as the master configuration. All the `resource` blocks are set up to iterate over predefined patterns in the keys. This was done so new application components could be added simply by appending new definitions to this file. The schema of the data structure is given below,

```tcl
"<namespace>"               = {
    "<namespace-1>"         = {
        "<subspace-1a>"     = {
            authorization   = bool
            image           = string
            method          = string
            environment     = optional(map(string), null)
            request_model   = optional(map(any), null)
        }
        # etc.
    }
    # etc.
}
```

New namespaces, subspacse and endpoints can be added by inserting the appropriate blocks into this file according to this schema given. **NOTE**: the root node name `<namespace>` will always be `cumberland-cloud` for this project.  