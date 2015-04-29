SparkleFormation.dynamic(:load_balancer) do |_name, _config={}|
  _config[:parameters] ||= {}
  _config[:p] = {}
  {
    :load_balancer_port => 80,
    :instance_port => 80,
    :instance_protocol => 'HTTP',
    :load_balancer_protocol => 'HTTP',
    :load_balancer_hc_threshold => '2',
    :load_balancer_hc_interval => '30',
    :load_balancer_hc_check_path => '/',
    :load_balancer_hc_timeout => '2',
    :load_balancer_hc_unhealthy_threshold => '2'
  }.each do |_key, _value|
    unless(_config[:disable_parameters])
      parameters.set!("#{_name}_#{_key}".to_sym) do
        type _value.class.to_s == 'String' ? 'String' : 'Number'
        default _config[:parameters].fetch(_key, _value)
      end
      _config[:p][_key] = ref!("#{_name}_#{_key}".to_sym)
    else
      _config[:p][_key] = _config[:parameters].fetch(_key, _value)
    end
  end

  conditions.set!(
    "#{_name}_healthcheck_path".to_sym,
    not!(equals!(_config[:p][:instance_protocol], 'TCP'))
  )

  _lb_resource = dynamic!(:elastic_load_balancing_load_balancer, _name, :resource_name_suffix => :load_balancer) do
    properties do
      availability_zones azs!
      listeners array!(
        ->{
          protocol _config[:p][:load_balancer_protocol]
          load_balancer_port _config[:p][:load_balancer_port]
          instance_port _config[:p][:instance_port]
          instance_protocol _config[:p][:instance_protocol]
        }
      )
      health_check do
        healthy_threshold _config[:p][:load_balancer_hc_threshold]
        interval _config[:p][:load_balancer_hc_interval]
        target if!(
          "#{_name}_healthcheck_path".to_sym,
          join!(
            _config[:p][:instance_protocol],
            ':',
            _config[:p][:instance_port],
            _config[:p][:load_balancer_hc_check_path]
          ),
          join!(
            _config[:p][:instance_protocol],
            ':',
            _config[:p][:instance_port]
          )
        )
        timeout _config[:p][:load_balancer_hc_timeout]
        unhealthy_threshold _config[:p][:load_balancer_hc_unhealthy_threshold]
      end
    end
  end

  outputs do
    set!("#{_name}_load_balancer_id".to_sym) do
      value ref!("#{_name}_load_balancer".to_sym)
      description 'Internal ID of load balancer'
    end
    set!("#{_name}_load_balancer_port".to_sym) do
      value _config[:p][:load_balancer_port]
      description 'Load balancer port'
    end
    set!("#{_name}_load_balancer_instance_port".to_sym) do
      value _config[:p][:instance_port]
      description 'Instance port'
    end
    set!("#{_name}_load_balancer_security_name".to_sym) do
      value attr!("#{_name}_load_balancer".to_sym, 'SourceSecurityGroup.GroupName')
      description 'Security group source name of load balancer'
    end
    set!("#{_name}_load_balancer_security_id".to_sym) do
      value attr!("#{_name}_load_balancer".to_sym, 'SourceSecurityGroup.OwnerAlias')
      description 'Security group source ID of load balancer'
    end
    set!("#{_name}_load_balancer_public_ip".to_sym) do
      value attr!("#{_name}_load_balancer".to_sym, 'DNSName')
      description 'Public IPv4 address of load balancer'
    end
  end

  # ensure we return resource for direct overrides
  _lb_resource
end

SparkleFormation.dynamic_info(:load_balancer).tap do |metadata|
  metadata[:parameters] = {
  }
end
