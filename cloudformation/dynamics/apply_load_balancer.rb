SparkleFormation.dynamic(:apply_load_balancer) do |_name, _config={}|

  parameters do
    set!("#{_name}_load_balancer_id".to_sym) do
      description 'Load Balancer ID fronting ASG'
      type 'String'
    end
    set!("#{_name}_load_balancer_port".to_sym) do
      type 'String'
      description 'Load balancer port'
    end
    set!("#{_name}_load_balancer_instance_port".to_sym) do
      type 'String'
      description 'Instance port'
    end
    set!("#{_name}_load_balancer_security_name".to_sym) do
      type 'String'
      description 'Security group source name of load balancer'
    end
    set!("#{_name}_load_balancer_security_id".to_sym) do
      type 'String'
      description 'Security group source ID of load balancer'
    end

  end

  dynamic!(:ec2_security_group_ingress, _name) do
    properties do
      group_id attr!("#{_name}_security_group".to_sym, 'GroupId')
      ip_protocol 'tcp'
      from_port ref!("#{_name}_load_balancer_instance_port".to_sym)
      to_port ref!("#{_name}_load_balancer_instance_port".to_sym)
      source_security_group_name ref!("#{_name}_load_balancer_security_name".to_sym)
      source_security_group_owner_id ref!("#{_name}_load_balancer_security_id".to_sym)
    end
  end

end
