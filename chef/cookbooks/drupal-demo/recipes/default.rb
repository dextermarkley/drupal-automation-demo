
include_recipe 'yum-mysql-community::mysql55'
include_recipe 'drupal-demo::mysql'
include_recipe 'drupal-demo::apache'

remote_file '/usr/local/bin/drush' do
  source 'http://files.drush.org/drush.phar'
  mode 0755
  action :create
  not_if { File.exists?('/usr/local/bin/drush') }
end

execute 'drush download' do
  command 'cd /var/www/ && /usr/local/bin/drush dl drupal-7.x --drupal-project-rename=drupal'
end

drupal_install_command = '/usr/local/bin/drush -y site-install standard'
drupal_install_command += " --db-url='mysql://#{node['drupal-demo']['mysql_drupal_user']}:#{node['cloud']['mysql_drupal_password']}@127.0.0.1/drupal'"
drupal_install_command += ' --site-name=drupal'
drupal_install_command += " --account-name=admin --account-pass=#{node['cloud']['drupal_admin_pass']} --clean-url=0"

execute 'drush install' do
  command drupal_install_command
  cwd node['drupal-demo']['www_dir']
end

execute 'change drupal files owenership' do
  command "chown apache #{node['drupal-demo']['www_dir']}/sites/default/files"
end
