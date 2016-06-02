

cm_user_data = File.read('./userdata-scripts/cm.sh')
web_user_data = File.read('./userdata-scripts/web.sh')

resource 'EC2SecurityGroupWeb', Type: 'AWS::EC2::SecurityGroup', Properties: {
  GroupDescription: 'Basic network access for Web instance',
  SecurityGroupIngress: [
    { IpProtocol: 'tcp', FromPort: '22', ToPort: '22', CidrIp: parameters['AllowedIP'] },
    { IpProtocol: 'tcp', FromPort: '80', ToPort: '80', CidrIp: parameters['AllowedIP'] },
    { IpProtocol: 'tcp', FromPort: '443', ToPort: '443', CidrIp: parameters['AllowedIP'] },
  ],
  SecurityGroupEgress: [
    { IpProtocol: 'tcp', FromPort: '22', ToPort: '22', CidrIp: '10.0.0.0/8' },
    { IpProtocol: 'udp', FromPort: '53', ToPort: '53', CidrIp: '0.0.0.0/0' },
    { IpProtocol: 'tcp', FromPort: '80', ToPort: '80', CidrIp: '0.0.0.0/0' },
    { IpProtocol: 'tcp', FromPort: '443', ToPort: '443', CidrIp: '0.0.0.0/0' }
  ],
  VpcId: ref("#{parameters['Environment']}VPC#{parameters['VpcNumber']}")
}

resource 'EC2SecurityGroupCM', Type: 'AWS::EC2::SecurityGroup', Properties: {
  GroupDescription: 'Basic network access for CM instance',
  SecurityGroupIngress: [  ],
  SecurityGroupEgress: [
    { IpProtocol: 'udp', FromPort: '53', ToPort: '53', CidrIp: '0.0.0.0/0' },
    { IpProtocol: 'tcp', FromPort: '80', ToPort: '80', CidrIp: '0.0.0.0/0' },
    { IpProtocol: 'tcp', FromPort: '443', ToPort: '443', CidrIp: '0.0.0.0/0' }
  ],
  VpcId: ref("#{parameters['Environment']}VPC#{parameters['VpcNumber']}")
}

resource 'EC2SecurityGroupCMIngress22', Type: 'AWS::EC2::SecurityGroupIngress', Properties: {
  GroupId: ref('EC2SecurityGroupCM'),
  IpProtocol: 'tcp', FromPort: '22', ToPort: '22', SourceSecurityGroupId: ref('EC2SecurityGroupWeb')
}

resource 'EC2SecurityGroupCMIngress443', Type: 'AWS::EC2::SecurityGroupIngress', Properties: {
  GroupId: ref('EC2SecurityGroupCM'),
  IpProtocol: 'tcp', FromPort: '443', ToPort: '443', SourceSecurityGroupId: ref('EC2SecurityGroupWeb')
}


resource 'InstanceCM', Type: 'AWS::EC2::Instance', Properties: {
  ImageId: parameters['AmiId'],
  InstanceType: parameters['InstanceType'],
  KeyName: parameters['SSHKey'],
  NetworkInterfaces: [{
    AssociatePublicIpAddress: false,
    DeviceIndex: '0',
    SubnetId: ref("app#{parameters['AvailabilityZone'].delete('-')}"),
    GroupSet: [  ref('EC2SecurityGroupCM')],
  }],
  UserData: base64(interpolate(cm_user_data))
}

resource 'InstanceWeb', Type: 'AWS::EC2::Instance', Properties: {
  ImageId: parameters['AmiId'],
  InstanceType: parameters['InstanceType'],
  KeyName: parameters['SSHKey'],
  NetworkInterfaces: [{
                        AssociatePublicIpAddress: true,
                        DeviceIndex: '0',
                        SubnetId: ref("pub#{parameters['AvailabilityZone'].delete('-')}"),
                        GroupSet: [  ref('EC2SecurityGroupWeb')],
                      }],
  UserData: base64(interpolate(web_user_data))
}

resource 'WaitHandleWeb', Type: 'AWS::CloudFormation::WaitConditionHandle'

resource 'WaitConditionWeb', Type: 'AWS::CloudFormation::WaitCondition', DependsOn: 'InstanceWeb', Properties: {
  Count: 1,
  Handle: ref('WaitHandleWeb'),
  Timeout: '1500'
}

resource 'WaitHandleCM', Type: 'AWS::CloudFormation::WaitConditionHandle'

resource 'WaitConditionCM', Type: 'AWS::CloudFormation::WaitCondition', DependsOn: 'InstanceCM', Properties: {
  Count: 1,
  Handle: ref('WaitHandleCM'),
  Timeout: '1500'
}