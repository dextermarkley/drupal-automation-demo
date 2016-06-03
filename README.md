drupal-demo Cloudformation and Cookbook
=====================

This cloudformation-ruby template and chef cookbook should serve as an example of a fully automated deployment of a drupal website.
This package will:
Create an AWS VPC with required NAT Gateway, Internet Gateway, subnets, and routing tables
Create two EC2 Instances running amazon linux: a Chef server, and an instance with Drupal/Mysql

The Quick Way
-------------

Copy the generated cloudformation json template to launch your stack. This is great if you just want to test things out. If you need to do actual development on the stack you will need to use the slow way.

The Slow Way
----------

Execute the scripts to build what you need.

Start with the create_ssh_key script. This script will create an ssh key for you to be able to log into the instances. Review required parameters before getting started.

After the create_ssh script has been run you can choose to use the generated .json to launch the cloudformation template or execute the ruby script.

Requirements
----------

 You are required to have AWS credential installed on our machined as ENV variables or a credential file with abilities to create and edit:
 - VPCs (subnets, routing tables, etc)
 - EC2 Instances

 You are also required to have a unix based machine with ruby 2.x installed with these gems
 - thor
 - aws-sdk-core
 - cloudformation-ruby-dsl

 All other requirements are self contained in source code here.

Attributes / Parameters
----------

CREATE SSH KEY SCRIPT PARAMETERS

ssh_key - The ssh key pair to create in AWS. This value must match Cloudformation Parameter - SSHKey
ssh_key_store - When an ssh key pair is created it will be written to this location
region - The AWS region to create the desired resources
profile - optional - The aws credentials profile

CLOUDFORMATION PARAMETERS

Environment - This is the chef environment the instance will use. In this demo there is no impact when switching between dev and prd, but this servers as a place holder for further development if required.

AllowedIP - Use this to control who initially has access to the instance, ie '71.93.54.37/32'

AmiId - This is the amazon AMI to use for the two instances. As of writing this, the latest ami 'ami-d0f506b0' should be fully functional

InstanceType - This is the instance size for both instances. Further work could be done to split this into two different parameters, but for demonstrative purposes t2.small is sufficient.

SSHKey - The ssh key that will be used to log into the instances if necessary. Note: This should be the same key you created using the setup script.

AvailabilityZone - For this demo only a single AZ is used, specify the one you want to use here: ie 'us-west-2a'

GitRepo - This should be the git repo that contains all the cookbooks the stack is going to use.

MysqlRootPassword - Do you really want to provision the root mysql password as a cf parameter? This is how you would do it if you did.

MysqlDrupalPassword - This is the password that will be created for the drupal database.

DrupalAdminPass - This is the password that will be set for the drupal admin user.

ChefPassword - The password you would use to log into the chef server if needed.

Usage
-----
# First run the create_ssh_key.rb script to get your ssh key to log into the instance
1. ./create_ssh_key.rb \
--ssh_key dmarkley-ssh \
--ssh_key_store ~/.ssh/dmarkley-ssh.pem \
--region us-west-2 \
--profile my_profile \

# Use drupal-demo.json to launch the stack OR us ruby cloudformation
2. cd cloudformation

./drupal-demo.rb create dmarkley-drupal-demo \
--region us-west-2 \
--parameters "AllowedIP=71.93.54.37/32;SSHKey=dmarkley-drupal-demo;S3CookbookBucket=dmarkley-drupal-demo;DrupalAdminPass=letmein123drupal" \
--disable-rollback \
--profile my_profile

If all went well the stack will transition to "CREATION_COMPLETE".

Navigate to ec2 and get the public IP of the web instance. Try to load it in your browser. Does it work?

If you make developmental improvements create a new json by executing expand.

./drupal-demo.rb expand > ../drupal-demo.json

License and Authors
-------------------
Authors: Dexter Markley - dextermarkley@gmail.com
Special thanks to contributers and maintainers of:
Cloudformation-Ruby - https://github.com/bazaarvoice/cloudformation-ruby-dsl
Thor - http://whatisthor.com/
chef mysql - https://github.com/chef-cookbooks/mysql