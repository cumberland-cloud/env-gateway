locals {
    # lambda execution environments
        # note: these are separated from the rest of the configuration to 
        #       prevent dependency cycles.
    system_environment                      = {
        ACCOUNT_ID                          = data.aws_caller_identity.current.account_id
        API_ID                              = aws_api_gateway_rest_api.this.id
        CLIENT_ID                           = module.cognito.user_pool.client_id
        GROUP                               = "TODO"
        USERPOOL_ID                         = module.cognito.user_pool.id
        REGION                              = data.aws_region.current.name
    }

}