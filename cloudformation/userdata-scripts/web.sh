#!/bin/bash

VERSION="12.9.41-1"
curl -L "https://packages.chef.io/stable/el/6/chef-$VERSION.el6.x86_64.rpm" -o chef-install && rpm -Uvh chef-install

mkdir -p /etc/chef

INSTANCEID=$(curl 169.254.169.254/latest/meta-data/instance-id/)

cat > /etc/chef/client.rb << EOF
ssl_verify_mode :verify_none
verify_api_cert false
log_level        :info
log_location     "/var/log/chef-client.log"

chef_server_url  "https://{{get_att('InstanceCM', 'PrivateDnsName')}}/organizations/rean-demo-org"
environment "{{ref('Environment')}}"
node_name  "{{aws_stack_name()}}-$INSTANCEID"
validation_client_name "rean-demo-user"
file_backup_path   "/var/chef/backup"
file_cache_path    "/var/chef/cache"
pid_file           "/var/chef/cache/client.pid"
EOF

aws --region {{aws_region}} s3 cp s3://{{ref('StackBucket')}}/chef/reandemouser.pem /etc/chef/validation.pem
while [ $? -ne 0 ]; do sleep 5 && aws --region us-west-2 s3 cp s3://{{ref('StackBucket')}}/chef/reandemouser.pem /etc/chef/validation.pem; done

# Ohai hint to detect as EC2 node in VPC (on first run as opposed to second)
mkdir -p /etc/chef/ohai/hints
touch /etc/chef/ohai/hints/ec2.json

cat > /etc/chef/roles.json << EOF
{
  "run_list": ["drupal-demo"],
  "cloud": {
    "allowed_ip": "{{parameters['AllowedIP']}}",
    "mysql_root_password": "{{parameters['MysqlRootPassword']}}",
    "mysql_drupal_password": "{{parameters['MysqlDrupalPassword']}}",
    "drupal_admin_pass": "{{parameters['DrupalAdminPass']}}"
  }
}
EOF

# Chef firstrun
chef-client -j /etc/chef/roles.json 2>&1 || exit 1

# All is well so signal success
/opt/aws/bin/cfn-signal -e 0 -r "Server setup complete" '{{ref('WaitHandleWeb')}}'