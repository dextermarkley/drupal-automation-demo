tiers = %w(
  pub
  app
)
### Mappings
mapping 'TierToSubnetIp',
        pub:    { ip: '10.16.0.0/26' },
        app:    { ip: '10.16.128.0/26'  }

mapping 'TierToRouteTable',
        pub:    { table: 'pub' },
        app:    { table: 'main'  }

resource 'VPC', Type: 'AWS::EC2::VPC', Properties: {
  CidrBlock: '10.16.0.0/16',
  EnableDnsSupport: true,
  EnableDnsHostnames: true,
  InstanceTenancy: 'default'
}

resource 'InternetGateway', Type: 'AWS::EC2::InternetGateway'

resource 'InternetGatewayAttach', Type: 'AWS::EC2::VPCGatewayAttachment', Properties: {
  InternetGatewayId: ref('InternetGateway'),
  VpcId: ref('VPC')
}

%w(main pub).each do |route_table|
  resource route_table.to_s, Type: 'AWS::EC2::RouteTable', Properties: {
    VpcId: ref('VPC'),
    Tags: [
      { Key: 'Environment', Value: ref('Environment') },
      { Key: 'CreatedBy', Value: 'drupal-demo' },
      { Key: 'Name', Value: 'drupal-automation-demo' }
    ]
  }
end

resource 'pubDefaultRoute', Type: 'AWS::EC2::Route', Properties: {
  DestinationCidrBlock: '0.0.0.0/0',
  GatewayId: ref('InternetGateway'),
  RouteTableId: ref('pub')
}

resource 'mainDefaultRoute', Type: 'AWS::EC2::Route', Properties: {
  DestinationCidrBlock: '0.0.0.0/0',
  NatGatewayId: ref('NatGateway'),
  RouteTableId: ref('main')
}

resource 'NatEIP', Type: 'AWS::EC2::EIP', Properties: {
  Domain: 'vpc'
}


resource 'NatGateway', Type: 'AWS::EC2::NatGateway', Properties: {
  AllocationId: get_att('NatEIP', 'AllocationId'),
  SubnetId: ref('pubsubnet')
}

resource 'pubsubnet', Type: 'AWS::EC2::Subnet', Properties: {
  CidrBlock: find_in_map('TierToSubnetIp', 'pub', 'ip'),
  AvailabilityZone: ref('AvailabilityZone'),
  MapPublicIpOnLaunch: true,
  VpcId: ref('VPC'),
  Tags: [
    { Key: 'Environment', Value: ref('Environment') },
    { Key: 'CreatedBy', Value: 'drupal-demo' },
    { Key: 'Name', Value: join('-', 'drupal-demo', ref('AvailabilityZone')) },
    { Key: 'Tier', Value: 'pub' }
  ]
}

resource 'PubSubnetAssociation', Type: 'AWS::EC2::SubnetRouteTableAssociation', Properties: {
  RouteTableId: ref(find_in_map('TierToRouteTable', 'pub', 'table')),
  SubnetId: ref('pubsubnet')
}

resource 'appsubnet', Type: 'AWS::EC2::Subnet', Properties: {
  CidrBlock: find_in_map('TierToSubnetIp', 'app', 'ip'),
  AvailabilityZone: ref('AvailabilityZone'),
  MapPublicIpOnLaunch: false,
  VpcId: ref('VPC'),
  Tags: [
    { Key: 'Environment', Value: ref('Environment') },
    { Key: 'CreatedBy', Value: 'drupal-demo' },
    { Key: 'Tier', Value: 'app' },
    { Key: 'Name', Value: join('-', 'drupal-demo', ref('AvailabilityZone')) },
  ]
}

resource 'AppSubnetAssociation', Type: 'AWS::EC2::SubnetRouteTableAssociation', Properties: {
  RouteTableId: ref(find_in_map('TierToRouteTable', 'app', 'table')),
  SubnetId: ref('appsubnet')
}


