SparkleFormation.build do

  set!('AWSTemplateFormatVersion', '2010-09-09')

  description 'Default stack description'

  parameters do

    creator do
      default ENV.fetch('KNIFE_USER', ENV.fetch('USER', 'unknown'))
      description 'Creator of stack'
      type 'String'
      disable_apply true
    end

    infrastructure_bucket do
      description 'Infrastructure files bucket'
      default "infra_repo_#{ENV['USER']}"
      type 'String'
      disable_apply true
    end

  end

  mappings.platforms('us-west-2'._no_hump) do
    _camel_keys_set(:auto_disable)
    set!('ubuntu1204', 'ami-ad42009d')
    set!('ubuntu1404', 'ami-a94e0c99')
  end

  dynamic!(:iam_user, :stack) do
    properties do
      path '/'
      policies array!(
        -> {
          policy_name 'stack_description_access'
          policy_document.statement array!(
            -> {
              effect 'Allow'
              action 'cloudformation:DescribeStackResource'
              resource '*'
            }
          )
        },
        ->{
          policy_name 'infrastructure_bucket_access'
          policy_document.statement array!(
            ->{
              effect 'Allow'
              action 's3:GetObject'
              resource join!('arn:aws:s3:::', ref!(:infrastructure_bucket), '/*')
            }
          )
        }
      )
    end
  end

  dynamic!(:iam_access_key, :stack) do
    properties.user_name ref!(:stack_iam_user)
  end

  outputs do
    stack_creator do
      description 'Stack creator'
      value ref!(:creator)
    end
  end

end
