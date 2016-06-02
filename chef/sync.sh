#!/bin/bash

git pull

knife environment from file ~/drupal-automation-demo/chef/environments/*.json

cookbook_dir=$(readlink -f ~/drupal-automation-demo/chef/cookbooks)
cookbooks=$(echo $(find $cookbook_dir -maxdepth 1 ! -wholename $cookbook_dir -type d -exec echo {} \;) | tr " " "\n" |awk 'BEGIN { FS = "/"  } { print $(NF) }')
knife cookbook upload $cookbooks