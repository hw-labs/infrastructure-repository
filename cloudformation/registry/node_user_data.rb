SfnRegistry.register(:node_user_data) do |_name, _config={}|
  user_data(
    base64!(
      join!(
        "#!/bin/bash\n",
        "apt-get update\n",
        "apt-get -y install python-setuptools\n",
        "easy_install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz\n",
        '/usr/local/bin/cfn-init -v --region ',
        ref!('AWS::Region'),
        ' -s ',
        ref!('AWS::StackName'),
        " -r #{_process_key(_name.to_s + '_' + (_config[:node] ? 'node' : 'launch_configuration'))} --access-key ",
        ref!(:stack_iam_access_key),
        ' --secret-key ',
        attr!(:stack_iam_access_key, :secret_access_key),
        "\n",
        *(
          _config[:disable_wait] ? [] : [
            "cfn-signal -e $? -r 'Node provision completion signal' '",
            ref!("#{_name}_wait_condition_handle".to_sym),
            "'\n"
          ]
        )
      )
    )
  )
end
