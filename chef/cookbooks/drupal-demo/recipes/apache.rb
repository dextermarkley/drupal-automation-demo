
yum_package 'httpd24' do
  action :install
end

node['php']['packages'].each do |pkg|
  yum_package pkg do
    action :install
  end
end

# This is a basic httpd conf file.
# Created as a template so that settings can easily be overriden
template '/etc/httpd/conf/httpd.conf' do
  source 'httpd.conf.erb'
  owner 'root'
  group 'root'
  mode 0644
  action :create
  notifies :restart, 'service[httpd]'
end

# Vhost config for drupal. Bare necessities here.
template '/etc/httpd/conf.d/drupal.conf' do
  source 'drupal.conf.erb'
  owner 'root'
  group 'root'
  mode 0644
  action :create
  notifies :restart, 'service[httpd]'
end

service 'httpd' do
  supports [:start, :restart, :reload, :status]
  action [:enable, :start]
end