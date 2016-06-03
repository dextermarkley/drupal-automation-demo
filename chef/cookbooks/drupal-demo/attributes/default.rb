

default['drupal-demo']['drupal_version'] = '7.x'
default['drupal-demo']['mysql_drupal_user'] = 'drupal-user'
default['drupal-demo']['mysql_drupal_database'] = 'drupal-database'
default['drupal-demo']['www_dir'] = '/var/www/drupal'

# This should be overridden by roles.json file
default['cloud']['mysql_root_password'] = 'change_me'
default['cloud']['mysql_drupal_password'] = 'change_me_drupal'

node.override['mysql']['server_root_password'] = node['cloud']['mysql_root_password']

default['php']['packages'] = [
  'php56',
  'php56-gd',
  'php56-pdo',
  'php56-mysqlnd'
]