#!/bin/bash

VERSION="12.6.0-1"
curl -L "https://packages.chef.io/stable/el/6/chef-server-core-$VERSION.el6.x86_64.rpm" -o chef-install && rpm -Uvh chef-install
DKVERSION="0.14.25-1"
curl -L "https://packages.chef.io/stable/el/6/chefdk-$DKVERSION.el6.x86_64.rpm" -o chef-dk-install && rpm -Uvh chef-dk-install

mkdir /etc/chef
chef-server-ctl reconfigure
chef-server-ctl user-create rean-demo-user Rean Demo dextermarkley@gmail.com '{{parameters['ChefPassword']}}' --filename /etc/chef/reandemouser.pem
chef-server-ctl org-create rean-demo-org 'Rean Demo Org' --association_user rean-demo-user --filename /etc/chef/validation.pem



mkdir -p ~/chef-repo/
mkdir -p ~/chef-repo/.chef
mkdir -p ~/chef-repo/environments/

cd ~/chef-repo
hostname=$(curl 169.254.169.254/latest/meta-data/local-hostname)

cat > ~/chef-repo/.chef/knife.rb << EOF
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

cat > ~/chef-repo/environments/production.json << EOF
{
  "name": "production",
  "description": "Environment for Production",
  "cookbook_versions": {
    "drupal-rean": "> 0.0.0"
  },
  "json_class": "Chef::Environment",
  "chef_type": "environment",
  "default_attributes": {},
  "override_attributes": {}
}
EOF

knife environment from file ~/chef-repo/environments/production.json

cat > ~/chef-repo/environments/development.json << EOF
{
  "name": "development",
  "description": "Environment for Development",
  "cookbook_versions": {
    "drupal-rean": "> 0.0.0"
  },
  "json_class": "Chef::Environment",
  "chef_type": "environment",
  "default_attributes": {},
  "override_attributes": {}
}
EOF

knife environment from file ~/chef-repo/environments/development.json

cat > ~/chef-repo/sync.sh << EOF
#!/bin/bash

aws s3 sync s3://{{parameters['S3CookbookBucket']}}/cookbooks/ ~/chef-repo/cookbooks/ --region {{aws_region}}

cookbook_dir=\$(readlink -f ~/chef-repo/cookbooks)
cookbooks=\$(echo \$(find \$cookbook_dir -maxdepth 1 ! -wholename \$cookbook_dir -type d -exec echo {} \;) | tr " " "\n" |awk 'BEGIN { FS = "/"  } { print \$(NF) }')
knife cookbook upload \$cookbooks
EOF

chmod +x ~/chef-repo/sync.sh
~/chef-repo/sync.sh

aws --region {{aws_region}} s3 cp /etc/chef/validation.pem s3://{{ref('StackBucket')}}/chef/validation.pem
aws --region {{aws_region}} s3 cp /etc/chef/reandemouser.pem s3://{{ref('StackBucket')}}/chef/reandemouser.pem

# All is well so signal success
/opt/aws/bin/cfn-signal -e 0 -r "Server setup complete" '{{ref('WaitHandleCM')}}'
