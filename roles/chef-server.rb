name 'chef-server'
description 'Chef server configuration'

run_list(
  'role[base]',
  'recipe[chef-server-populator]'
)

override_attributes(
  'chef-server' => {
    :configuration => {
      'chef-server-webui' => {
        :enable => false
      }
    }
  },
  :chef_server_populator => {
    :databag => 'users',
    :chef_server => {
      :configuration => {
        :erchef => {
          :s3_url_ttl => 7200
        }
      }
    }
  }
)
