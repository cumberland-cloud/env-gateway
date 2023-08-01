locals {
    # Configuration derived from static properties, parsed into a form that 
    #   will easily integrate with Terraform macros

    # ECR access policy configuration
        # Generate a map where each key corresponds to an array of endpoints 
        #   that require access to the key's ECR.
    ecr_endpoint_access                     = {
        for ecr_key, ecr in local.ecrs:
            ecr_key                         => [
                for index, endpoint in local.endpoints: 
                    endpoint.path if ecr.name == "${endpoint.image}"
            ]
    }
    # API Method, Resource, Integration and Lambda configuration
    endpoints                               = flatten([
        for namespace_key, namespace in local.cumberland_cloud:[
            for subspace_key, subspace in namespace: [
                for endpoint in subspace.endpoints: {
                    authorization           = endpoint.authorization
                        # note: `dot_identifier` is used as the key when projecting the `flatten` list 
                        #           output back into a map
                    dot_identifier          = "${local.root_namespace}.${namespace_key}.${subspace_key}.${endpoint.image}"
                    environment             = try(endpoint.environment, null)
                        # note: `image` is needed for other calculations, so it must be separated
                        #           from `image_path`.
                    image                   = endpoint.image
                        # note: tenant images are not tenant specific, i.e. all tenants use the 
                        #           same images with different environments
                    image_path              = namespace_key == local.tenant_namespace ? (
                                                "${local.root_namespace}/${namespace_key}/"
                                            ): (
                                                "${local.root_namespace}/${namespace_key}/${subspace_key}/"
                                            )
                    method                  = endpoint.method
                    namespace               = namespace_key
                    path                    = "${local.root_namespace}/${namespace_key}/${subspace_key}/${endpoint.image}"
                    request_model           = try(endpoint.request_model, null)
                    subspace                = subspace_key
            }]
        ]
    ])
        # note: project into iterable map with unique, logical key.
    endpoints_map                           = {
        for endpoint in local.endpoints:
            endpoint.dot_identifier         => endpoint
    }
    # trigger for Gateway reployment
    redeploy_hash                  = sha1(jsonencode(aws_api_gateway_rest_api.this.body))
}