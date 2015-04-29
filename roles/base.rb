name 'base'

run_list(
  'recipe[chef-client::cron]',
  'recipe[chef-client::config]',
  'recipe[users::sysadmins]'
)

default_attributes(
  :chef_client => {
    :log_dir => '/var/log/chef',
    :log_file => 'client.log',
    :cron => {
      :hour => '*',
      :minute => '*/30'
    },
    :config => {
      :verify_api_cert => false
    }
  }
)
