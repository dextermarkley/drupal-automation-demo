name             'drupal-demo'
maintainer       'NA DEMO'
maintainer_email 'dextermarkley@gmail.com'
license          'All rights reserved'
description      'Installs/Configures drupal-demo demo'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.0'

depends 'mysql'
depends 'database'
depends 'yum-mysql-community'