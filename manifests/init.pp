# == Class: webreader
#
# Full description of class webreader here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#  TODO
#  class { webreader:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <guillaume@pancak.com>
#
# === Copyright
#
# Copyright 2014 Guillaume Pancak, Gutenberg-technology
#
class webreader (
  $version        = 'latest',
  $environment    = 'production',
  $status         = 'running',
  $bypass_node    = true,
  $nodejs_version = $::nodejs_stable_version,
){
  $nginx = "nginx-light"
  $base = [ $nginx, "ruby-full", "rubygems", "zip", "build-essential", "checkinstall", "fakeroot", "git", "unzip", "libfontconfig1", "redis-server", "python-setuptools", "python-dateutil", "python-magic" ]
  $npm_pkg = [ "phantomjs", "gulp", "bower" ]

  validate_bool($bypass_node)


  include apt

	apt::source { 'dotdebbase':
    location   => 'http://packages.dotdeb.org',
    release    => 'wheezy',
    repos      => 'all',
    key        => '89DF5277',
    key_source => 'http://www.dotdeb.org/dotdeb.gpg',
  }

	apt::source { 'dotdeb':
		location   => 'http://packages.dotdeb.org',
		release    => 'wheezy-php55',
 		repos      => 'all',
		key        => '89DF5277',
 		key_source => 'http://www.dotdeb.org/dotdeb.gpg',
 	}

  package { $base:
    ensure   => 'latest',
 	  require  =>  [Apt::Source['dotdebbase'], Apt::Source ['dotdeb']],
  }

  package { 'compass':
    name => 'compass',
    provider => gem,
    ensure => latest,
    require => Package['rubygems'],
  }

  package { 'sass':
    name => 'sass',
    provider => gem,
    ensure => latest,
    require => Package['rubygems'],
}


  if ! $bypass_node {

    if $::version_nodejs_installed != $nodejs_version {
      class { 'nodejs':
        version => $nodejs_version,
      }

      file { "/usr/local/bin/node":
        ensure  => link,
        target  => '/usr/local/node/node-default/bin/node',
        require => Class['nodejs'],
      }

      file { "/usr/local/bin/npm":
        ensure  => link,
        target  => '/usr/local/node/node-default/bin/npm',
        require => Class['nodejs'],
      }

      file { "/usr/local/bin/phantomjs":
        ensure => link,
        target => '/usr/local/node/node-default/bin/phantomjs',
        require => [Class['nodejs'], Package[$npm_pkg]],
      }

      package { $npm_pkg:
        provider => npm,
        require  => [ Class['nodejs'], File['/usr/local/bin/npm']],
      }
    }

  }

  service { 'nginx':
    name    => "nginx",
    ensure  => running,
    enable  => true,
    require => Package[$nginx],
  }

  file { "/etc/nginx/sites-enabled/default":
    ensure  => absent,
    require => Package [$nginx],
  }

}
