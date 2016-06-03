#!/usr/bin/env ruby

require 'cloudformation-ruby-dsl/cfntemplate'
require 'cloudformation-ruby-dsl/spotprice'
require 'cloudformation-ruby-dsl/table'

# Variables
Application = 'drupal-rean'
time = Time.now
timestamp = "#{time.day}-#{time.month}-#{time.year}"



template do
  load_from_file './parameters.rb'

  value AWSTemplateFormatVersion: '2010-09-09'
  value Description: 'AWS Cloudformation template for the creation a drupal demo in a VPC'

  tag 'CreatedBy', { Value: 'drupal-demo' }
  tag 'Name', { Value: 'drupal-automation-demo' }

  load_from_file './vpc.rb'
  load_from_file './instances.rb'

end.exec!
