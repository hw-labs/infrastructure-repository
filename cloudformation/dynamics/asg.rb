SparkleFormation.dynamic(:asg) do |_name, _config={}|

  parameters do

    registry!(:instance_parameters, _name, _config)

    set!("#{_name}_min_nodes".to_sym) do
      default _config.fetch(:min_nodes, 1).to_s
      description 'Minimum number of nodes'
      type 'String'
      stack_unique true
    end

    set!("#{_name}_max_nodes".to_sym) do
      default _config.fetch(:max_nodes, 1).to_s
      description 'Maximum number of nodes'
      type 'String'
      stack_unique true
    end

    set!("#{_name}_key_name".to_sym) do
      default 'default'
      description 'SSH key name'
      type 'String'
    end

  end

  dynamic!(:security_group, _name) do
    properties do
      group_description "ASG instances group (#{_name})"
      security_group_ingress array!(
        -> {
          ip_protocol 'tcp'
          from_port '22'
          to_port '22'
          cidr_ip '0.0.0.0/0'
        }
      )
    end
  end

  dynamic!(:wait_condition_handle, _name)

  dynamic!(:wait_condition, _name) do
    depends_on process_key!("#{_name}_auto_scaling_group".to_sym)
    properties do
      count ref!("#{_name}_min_nodes".to_sym)
      handle ref!("#{_name}_wait_condition_handle".to_sym)
      timeout 3600
    end
  end

  dynamic!(:launch_configuration, _name) do
    properties do
      image_id map!(:platforms, 'AWS::Region', ref!("#{_name}_instance_image_type".to_sym))
      instance_type ref!("#{_name}_instance_size".to_sym)
      key_name ref!("#{_name}_key_name".to_sym)
      security_groups [attr!("#{_name}_security_group".to_sym, 'GroupId')]
      registry!(:node_user_data, _name, _config)
    end
    registry!(:chef_metadata, _name, _config)
  end

  dynamic!(:auto_scaling_group, _name) do
    properties do
      availability_zones azs!
      min_size ref!("#{_name}_min_nodes".to_sym)
      max_size ref!("#{_name}_max_nodes".to_sym)
      if(_config[:load_balancers])
        load_balancer_names _config[:load_balancers]
      end
      cooldown 90
      launch_configuration_name ref!("#{_name}_launch_configuration".to_sym)
    end
    if(_config[:depends])
      depends_on [_config[:depends]].flatten.compact
    end
  end

end

# Add metadata
SparkleFormation.dynamic_info(:asg).tap do |metadata|
  metadata[:parameters] = {
    :min_nodes => {
      :type => 'String', # crappy type handling hack
      :description => 'Minimum number of nodes in ASG'
    },
    :max_nodes => {
      :type => 'String',
      :description => 'Maximum number of nodes in ASG'
    },
    :depends => {
      :type => 'Array',
      :description => 'Resources this ASG depends on'
    }
  }
end
