
# build packages required for mysql2
yum_package 'gcc' do
  action :nothing
end.run_action(:install)


# mysql-devel packages required for mysql2
yum_package 'mysql-community-devel' do
  action :nothing
end.run_action(:install)

# mysql2 gem required for mysql and database cookbooks
chef_gem 'mysql2' do
  action :install
end

mysql_client 'default' do
  action :create
end

mysql_service 'default' do
  action [:create, :start]
  port '3306'
  initial_root_password node['cloud']['mysql_root_password']
end

mysql_config 'default' do
  instance 'default'
  source 'extra_mysql_settings.erb'
  action :create
  notifies :restart, 'mysql_service[default]'
end

mysql_database 'drupal' do
  connection(
    :host     => '127.0.0.1',
    :username => 'root',
    :password => node['cloud']['mysql_root_password']
  )
  action :create
end

mysql_database_user node['drupal-demo']['mysql_drupal_user'] do
  connection(
    :host     => '127.0.0.1',
    :username => 'root',
    :password => node['cloud']['mysql_root_password']
  )
  password      node['cloud']['mysql_drupal_password']
  database_name 'drupal'
  host          '127.0.0.1'
  privileges    [:select, :update,:insert, :alter, :index, :drop, :delete, :create ] # permissions required by drupal documentation
  action        :grant
end
