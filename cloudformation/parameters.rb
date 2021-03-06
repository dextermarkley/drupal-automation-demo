
parameter 'Environment',
          Default: 'development',
          Description: 'The environment where the nodes should register',
          Type: 'String',
          AllowedValues: %w(development production),
          ConstraintDescription: 'development, production'

parameter 'AllowedIP',
          Type: 'String',
          Default: '71.93.54.37/32',
          Description: 'The IP address that will have public access.'

parameter 'AmiId',
          Type: 'String',
          Default: 'ami-d0f506b0',
          Description: 'The AMI you would like to start with.'

parameter 'InstanceType',
          Type: 'String',
          Default: 't2.small',
          Description: 'The size of the instances.'

parameter 'SSHKey',
          Type: 'String',
          Default: 'your-ssh-key',
          Description: 'The ssh key to install on the instance.'

parameter 'ChefPassword',
          Type: 'String',
          Default: ']Mi>ME9gJnfG+B4cUFjk',
          Description: 'The password to use on the chef-server.'

parameter 'AvailabilityZone',
          Type: 'String',
          Default: 'us-west-2a',
          Description: 'The AZ to run the instances in.'

parameter 'GitRepo',
          Type: 'String',
          Default: 'dextermarkley/drupal-automation-demo',
          Description: 'This is the source location for the chef cookbooks.'

parameter 'MysqlRootPassword',
          Type: 'String',
          Default: 'eLaqerws0KLLJELjdKKEIL',
          Description: 'The password to use on the mysql root password.'

parameter 'MysqlDrupalPassword',
          Type: 'String',
          Default: 'aQfRwEryeqradsfvvcQERR',
          Description: 'The password to use for the mysql drupal user.'

parameter 'DrupalAdminPass',
          Type: 'String',
          Default: 'letmeindrupal',
          Description: 'The password to use for the drupal admin.'


