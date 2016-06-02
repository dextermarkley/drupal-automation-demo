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

cat > ~/.ssh/id_rsa << EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA6uLmjIzHjZVxxFopkMffaEiTOkeW6Um/N51IbTHafHerpfIO
3OagNiNhTmE4w68sY/OTSHi/TVg3fvcgCdBQCDsqqq1qaO93iA9ArpdMKFScTQZI
OQ2Utka61wMEDk3X1r/xTbo1mDckfl1P0CABlcbEjVxDg6gfYAZ/1FMcJTZNd/8b
iPQEvq0nF+9bVvOC3fmeEaXSl2iEARn5ViknaI/xgCuAyhN0UkKyfybPK0icr+gF
1JWskCtXLyfzHs+wTAGtvndkvN7Fr/Xj1/I3Or1hTDSo/ZbFawmUarUzXN1FzgZU
SdoK1gGoQmdZPzIbhu0T3ezZtb1Gv8AbcrdlUQIDAQABAoIBAF8ZOsrQ/MJgLU2Y
S5fotJUePS2tanZNe3Pi5D4BnzohoYdwd4AMh/UjYfQ//KGNvOVC6vC+ooWIH//x
wjD2/FA41E+CIsEVo0mdE00cyKLTjuzIjFk9HGaoQGFpQS0hay/xSptztttICCh5
UyUqsDmZ3l51aohVe05/kyW9+Hk/uoroYiVoKkmFhd6ajyPQLagSi0j8jbe/65Ns
snmf6ZMrd1FMmxWDI+Aebeo2RNuLN64pWgo0QNNIFeyoottx0pJrDMkgs0OWXm69
289x5JtnnqTC8E5PQev63LepAvtju1X56Q/vpo+GitndhyTDU0fzpeCajvd8I6bC
AEAAv6ECgYEA+SBE/e9XhUQk0OExiAPxTqXbQhvHKh6Cnx4VaP33JpFDVrFUKBAV
YlPrgxZH+HelU8uUi4MiFtG2MfAEXmRCS/FOZsGV0xCHdLlafOwwNVbWEePV5XP+
WTz+35rrrcXeY8RbeYZ4x5nGTd9C+No3CHXkle2Lv8xFoUmjlOIhNHUCgYEA8V4M
Eym1+Lza0FFTxvOxZb/nECamzwXR98O8g3iR/ULElSCoLvgG5PusvkpSuFnVYncP
66rKBWUlnXQZ4TefVk3zBQhKPvyxcprVHG0BWwtmeGhzjfqitII0Efe7hqqhz7Wa
HWm+PsktsBieBy+uQbZBfnUhre5gjq719meD4e0CgYEAlzdDKW/yC+5E+pT2X70k
57w8zm/WAHbsinDURhqBvmNGIIUatAavNDQELFmF7geRzr8vt08tjfRVRxKNVE4+
/6HFGRJAQxExZ2RqzJEA4h+HaOyGlPRHWxtvCYMbsyr7xksVyzoYbe+lMvdly2+J
IBWPXoIF5bG0QiZUqLZpuVECgYEAj+6eUrsX2bl83qbwx35AtkVmm7oA1QlKeW5O
tzOqExXCto8f28pqChiOnXcitu5TEgGgC8/v4qG7eZZnbGdH7CZVmhWkeMUlaAsu
tGHIYit9MqZO6kagyfWu6VwKhrawAXXw7kNFgJllVlKHwg9L4cG2cpuUtuykxdFN
uV9nRM0CgYBqb0Iy0mc/by/lrq5k/Tlv+kDpnq7lvTB8rmO9jWcOckhTIY1rxEzg
9ySR0q4bhRentGe8I0FUJrhS6tcZnwFwowTjLhxdCi8keRJUt1BHtJHYRQRnIM05
k6sqaTwAdphe17CqKUtvUffmlL4dp9RFT4O82zyCkpB8w88EdkFz7Q==
-----END RSA PRIVATE KEY-----
EOF

chmod 400 ~/.ssh/id_rsa

scp -i ~/.ssh/id_rsa ec2-user@{{get_att('InstanceCM', 'PrivateDnsName')}}:/home/ec2-user/validation.pem /etc/chef/validation.pem
while [ $? -ne 0 ]; do sleep 5 && scp -i ~/.ssh/id_rsa ec2-user@{{get_att('InstanceCM', 'PrivateDnsName')}}:/home/ec2-user/validation.pem /etc/chef/validation.pem; done

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