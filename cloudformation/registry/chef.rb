# Used for ec2 instance or launch config resources to provide chef metadata
SfnRegistry.register(:chef_metadata) do |_name, _config={}|
  metadata('AWS::CloudFormation::Authentication') do
    infrastructure_bucket_credentials do
      _camel_keys_set(:auto_disable)
      type 'S3'
      accessKeyId ref!(:stack_iam_access_key)
      secretKey attr!(:stack_iam_access_key, :secret_access_key)
      buckets ref!(:infrastructure_bucket)
    end
  end
  metadata('AWS::CloudFormation::Init') do
    _camel_keys_set(:auto_disable)
    config do
      files('/etc/chef/validator.pem') do
        source join!(
          'https://', ref!(:infrastructure_bucket), '.s3.amazonaws.com/', 'validator.pem'
        )
        mode '000400'
        owner 'root'
        group 'root'
        authentication 'InfrastructureBucketCredentials'
      end
      files('/etc/chef/encrypted_data_bag_secret') do
        source join!(
          'https://', ref!(:infrastructure_bucket), '.s3.amazonaws.com/', 'encrypted_data_bag_secret'
        )
        mode '000400'
        owner 'root'
        group 'root'
        authentication 'InfrastructureBucketCredentials'
      end
      files('/etc/chef/first_run.json') do
        content do
          run_list _config[:run_list] ? _config[:run_list] : ref!("#{_name}_run_list".to_sym)
          stack do
            name ref!('AWS::StackName')
            id ref!('AWS::StackId')
            region ref!('AWS::Region')
            creator ref!(:creator)
          end
        end
        mode '000644'
        owner 'root'
        group 'root'
      end
      files('/etc/chef/client.rb') do
        content join!(
          "log_level :info\n",
          "log_location '/var/log/chef/client.log'\n",
          "chef_server_url '",
          ref!(:chef_server_url),
          "'\n", "environment '",
          ref!(:environment),
          "'\n",
          "validation_key '/etc/chef/validator.pem'\n",
          "validation_client_name 'chef-validator'\n"
        )
        mode '000644'
        owner 'root'
        client 'root'
      end
      commands('01_ntp_sync_apt') do
        command '/usr/bin/apt-get install ntpdate -y && /usr/sbin/ntpdate -b -s 0.us.pool.ntp.org'
        test 'test -e /usr/bin/apt-get'
      end
      commands('02_software_properties_old') do
        command 'apt-get install -yq python-software-properties'
        ignoreErrors 'true'
      end
      commands('02_software_properties_new') do
        command 'apt-get install -yq software-properties-common'
        ignoreErrors 'true'
      end
      commands('03_add_repository') do
        command 'apt-add-repository ppa:brightbox/ruby-ng -y'
      end
      commands('04_apt_reupdate') do
        command 'apt-get update'
      end
      commands('05_ruby_install') do
        command 'apt-get install ruby2.2 ruby2.2-dev libyajl-dev build-essential -qy'
      end
      commands('06_install_chef') do
        command join!(
          'gem install chef --version ',
          ref!(:chef_client_version),
          ' --no-ri --no-rdoc'
        )
      end
      commands('03_log_dir') do
        command 'mkdir -p /var/log/chef'
        test 'test ! -e /var/log/chef'
      end
      commands('99_chef_first_run') do
        command 'chef-client -j /etc/chef/first_run.json'
        test 'test -e /etc/chef/validator.pem'
      end
    end
  end
end
