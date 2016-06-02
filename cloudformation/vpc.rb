tiers = %w(
  pub
  app
)
### Mappings
mapping 'TierToSubnetIp',
        pub:    { ip: '0' },
        app:    { ip: '128'  }

mapping 'TierToRouteTable',
        pub:    { table: 'pub' },
        app:    { table: 'main'  }

vpc_resource = "#{parameters['Environment']}VPC#{parameters['VpcNumber']}"
resource vpc_resource, Type: 'AWS::EC2::VPC', Properties: {
  CidrBlock: "10.#{parameters['VpcNumber']}.0.0/16",
  EnableDnsSupport: true,
  EnableDnsHostnames: true,
  InstanceTenancy: 'default'
}

resource 'InternetGateway', Type: 'AWS::EC2::InternetGateway'

resource 'InternetGatewayAttach', Type: 'AWS::EC2::VPCGatewayAttachment', Properties: {
  InternetGatewayId: ref('InternetGateway'),
  VpcId: ref(vpc_resource)
}

%w(main pub).each do |route_table|
  resource route_table.to_s, Type: 'AWS::EC2::RouteTable', Properties: {
    VpcId: ref("#{parameters['Environment']}VPC#{parameters['VpcNumber']}"),
    Tags: [
      { Key: 'Environment', Value: parameters['Environment'] },
      { Key: 'CreatedBy', Value: ENV['USER'] },
      { Key: 'Name', Value: "#{parameters['VpcNumber']}-#{route_table}" }
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

short_az = "#{parameters['AvailabilityZone'].delete('-')}"

resource 'NatGateway', Type: 'AWS::EC2::NatGateway', Properties: {
  AllocationId: get_att('NatEIP', 'AllocationId'),
  SubnetId: ref("pub#{short_az}")
}

resource "pub#{short_az}", Type: 'AWS::EC2::Subnet', Properties: {
  CidrBlock: "10.#{parameters['VpcNumber']}.#{find_in_map('TierToSubnetIp', 'pub', 'ip')}.0/26",
  AvailabilityZone: parameters['AvailabilityZone'],
  MapPublicIpOnLaunch: true,
  VpcId: ref("#{parameters['Environment']}VPC#{parameters['VpcNumber']}"),
  Tags: [
    { Key: 'Environment', Value: parameters['Environment'] },
    { Key: 'CreatedBy', Value: ENV['USER'] },
    { Key: 'Tier', Value: 'pub' },
   { Key: 'Name', Value: "#{parameters['VpcNumber']}-pub-#{parameters['AvailabilityZone'].delete('-')}" }
  ]
}

resource "pub#{short_az}Association", Type: 'AWS::EC2::SubnetRouteTableAssociation', Properties: {
  RouteTableId: ref(find_in_map('TierToRouteTable', 'pub', 'table')),
  SubnetId: ref("pub#{short_az}")
}

resource "app#{short_az}", Type: 'AWS::EC2::Subnet', Properties: {
  CidrBlock: "10.#{parameters['VpcNumber']}.#{find_in_map('TierToSubnetIp', 'app', 'ip')}.0/26",
  AvailabilityZone: parameters['AvailabilityZone'],
  MapPublicIpOnLaunch: false,
  VpcId: ref("#{parameters['Environment']}VPC#{parameters['VpcNumber']}"),
  Tags: [
    { Key: 'Environment', Value: parameters['Environment'] },
    { Key: 'CreatedBy', Value: ENV['USER'] },
    { Key: 'Tier', Value: 'app' },
    { Key: 'Name', Value: "#{parameters['VpcNumber']}-app-#{parameters['AvailabilityZone'].delete('-')}" }
  ]
}

resource "app#{short_az}Association", Type: 'AWS::EC2::SubnetRouteTableAssociation', Properties: {
  RouteTableId: ref(find_in_map('TierToRouteTable', 'app', 'table')),
  SubnetId: ref("app#{short_az}")
}


