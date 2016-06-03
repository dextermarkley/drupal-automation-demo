
# As of writing this mysql57 has issues with setting the root password. Sticking with the old for now.
# https://github.com/chef-cookbooks/mysql/issues/410
include_recipe 'yum-mysql-community::mysql55'
include_recipe 'drupal-demo::mysql'
include_recipe 'drupal-demo::apache'

# This will install the latest version of drush.
# Drush makes it easy to install drupal
remote_file '/usr/local/bin/drush' do
  source 'http://files.drush.org/drush.phar'
  mode 0755
  action :create
  not_if { File.exists?('/usr/local/bin/drush') }
end

execute 'drush download' do
  command "cd /var/www/ && /usr/local/bin/drush dl drupal-#{node['drupal-demo']['drupal_version']} --drupal-project-rename=drupal"
end

drupal_install_command = '/usr/local/bin/drush -y site-install standard'
drupal_install_command += " --db-url='mysql://#{node['drupal-demo']['mysql_drupal_user']}:#{node['cloud']['mysql_drupal_password']}@127.0.0.1/drupal'"
drupal_install_command += ' --site-name=drupal'
drupal_install_command += " --account-name=admin --account-pass=#{node['cloud']['drupal_admin_pass']} --clean-url=0"

execute 'drush install' do
  command drupal_install_command
  cwd node['drupal-demo']['www_dir']
end

# Drupal will complain about file permissions if this is not owned by apache
execute 'change drupal files ownership' do
  command "chown apache #{node['drupal-demo']['www_dir']}/sites/default/files"
end
