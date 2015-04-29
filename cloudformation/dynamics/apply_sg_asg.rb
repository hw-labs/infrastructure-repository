SparkleFormation.dynamic(:apply_sg_asg) do |_name, _config={}|

  parameters do
    set!("#{_name}_security_group_id".to_sym) do
      type 'String'
      description 'Security group ID'
    end
  end

  resources("#{_config[:asg_prefix]}_launch_configuration".to_sym) do
    properties do |current_properties|
      security_groups current_properties.security_groups.push(
        ref!("#{_name}_security_group_id".to_sym)
      )
    end
  end

end
