SfnRegistry.register(:instance_parameters) do |_name, _config={}|

  set!("#{_name}_instance_size".to_sym) do
    allowed_values [
      'm3.large',
      'm3.medium',
      't2.medium',
      't2.small',
      'm1.small'
    ]
    default 'm1.small'
    description 'Size of created instance'
    type 'String'
  end

  set!("#{_name}_instance_image_type".to_sym) do
    default 'ubuntu1204'
    allowed_values ['ubuntu1404', 'ubuntu1204']
    description 'Instance platform'
    type 'String'
  end

end
