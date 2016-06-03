#!/usr/bin/env ruby

require 'aws-sdk-core'
require 'thor'
require 'time'
require 'open3'

def create_ssh_key(ec2, ssh_key)
  begin
    resp = ec2.create_key_pair({
      key_name: ssh_key, # required
    })
  rescue Aws::EC2::Errors::InvalidKeyPairDuplicate
    puts "The ssh key #{ssh_key} already exists. Hopefully you already have the pem."
    return true
  rescue => e
    puts "An error occurred attempting to create ssh key #{ssh_key} : #{e}"
    exit 1
  end
  puts "The ssh key #{ssh_key} was successfully created."
  return resp.key_material
end

def get_creds(region, profile)
  if profile.nil? || profile.empty?
    aws_creds = Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
  else
    aws_creds = Aws::SharedCredentials.new(profile_name: profile)
  end
  if aws_creds.credentials.access_key_id.nil?
    puts 'Unable to build aws credentials. Try using a profile.'
    exit 1
  end
  Aws::EC2::Client.new(region: region, credentials: aws_creds)
end

class MyCLI < Thor
  class_option :ssh_key,       type: :string, required: false, default: 'dmarkley-ssh'
  class_option :ssh_key_store, type: :string, required: false, default: "#{ENV["HOME"]}/.ssh/"
  class_option :region,        type: :string, required: false, default: 'us-west-2'
  class_option :profile,   type: :string, required: false

  desc 'default', 'Create or update the managed security group cloudformation template for an environment'
  def default
    ec2 = get_creds(options['region'], options['profile'])
    ssh_key_pem = create_ssh_key(ec2, options['ssh_key'])
    unless ssh_key_pem == true
      ssh_key_file_path = "#{options['ssh_key_store']}#{options['ssh_key']}.pem"
      if File.exists?(ssh_key_file_path)
        ssh_key_file_path = "#{ssh_key_file_path}_new_#{Time.now.to_i}"
        puts "The desired ssh key #{options['ssh_key']} was already in your ssh directory."
      end
      puts "Writing #{ssh_key_file_path}"
      File.write(ssh_key_file_path, ssh_key_pem)
    end
  end
end

# Using unshift we can make thor run the default function every time
array = ARGV.unshift('default')
MyCLI.start(array)

