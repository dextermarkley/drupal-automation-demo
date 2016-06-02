#!/bin/bash

VERSION="12.6.0-1"
curl -L "https://packages.chef.io/stable/el/6/chef-server-core-$VERSION.el6.x86_64.rpm" -o chef-install && rpm -Uvh chef-install
DKVERSION="0.14.25-1"
curl -L "https://packages.chef.io/stable/el/6/chefdk-$DKVERSION.el6.x86_64.rpm" -o chef-dk-install && rpm -Uvh chef-dk-install

mkdir /etc/chef
chef-server-ctl reconfigure
chef-server-ctl user-create rean-demo-user Rean Demo dextermarkley@gmail.com '{{parameters['ChefPassword']}}' --filename /home/ec2-user/reandemouser.pem
chef-server-ctl org-create rean-demo-org 'Rean Demo Org' --association_user rean-demo-user --filename /home/ec2-user/validation.pem

chown ec2-user /home/ec2-user/*.pem
cd ~/
git clone https://github.com/{{parameters['GitRepo']}}.git
cd ~/drupal-automation-demo/chef/
mkdir -p ~/drupal-automation-demo/chef/.chef
hostname=$(curl 169.254.169.254/latest/meta-data/local-hostname)

cat > ~/drupal-automation-demo/chef/.chef/knife.rb << EOF
current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                'rean-demo-user'
client_key               "/etc/chef/reandemouser.pem"
validation_client_name   'rean-demo-org'
validation_key           "/etc/chef/validation.pem"
chef_server_url          'https://$hostname/organizations/rean-demo-org'
cache_type               'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )
cookbook_path            ["#{current_dir}/../cookbooks"]
EOF

knife ssl fetch --server-url https://$hostname/organizations/rean-demo-org

chmod +x ~/drupal-automation-demo/chef/sync.sh
~/drupal-automation-demo/chef/sync.sh

echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDq4uaMjMeNlXHEWimQx99oSJM6R5bpSb83nUhtMdp8d6ul8g7c5qA2I2FOYTjDryxj85NIeL9NWDd+9yAJ0FAIOyqqrWpo73eID0Cul0woVJxNBkg5DZS2RrrXAwQOTdfWv/FNujWYNyR+XU/QIAGVxsSNXEODqB9gBn/UUxwlNk13/xuI9AS+rScX71tW84Ld+Z4RpdKXaIQBGflWKSdoj/GAK4DKE3RSQrJ/Js8rSJyv6AXUlayQK1cvJ/Mez7BMAa2+d2S83sWv9ePX8jc6vWFMNKj9lsVrCZRqtTNc3UXOBlRJ2grWAahCZ1k/MhuG7RPd7Nm1vUa/wBtyt2VR drupa-automation-demo@chef' >> /home/ec2-user/.ssh/authorized_keys
echo ' ' >> /home/ec2-user/.ssh/authorized_keys

# All is well so signal success
/opt/aws/bin/cfn-signal -e 0 -r "Server setup complete" '{{ref('WaitHandleCM')}}'
