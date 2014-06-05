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
  $server         = '127.0.0.1',
	$server_name	  = 'wr.gutenberg-technology.com',
  $script_name    = 'webreader',
  $node_port      = '3000',
  $status         = 'running',
	$wruser		      = 'vagrant',
	$wrgrp		      = 'vagrant',
){
	$nginx = "nginx-light"
	$base = [ $nginx, "ruby-full", "rubygems", "zip", "build-essential", "checkinstall", "fakeroot", "git", "unzip", "libfontconfig1", "redis-server" ]
  $npm_pkg = [ "phantomjs", "gulp", "bower" ]
  $nodeapp_dir = "/var/www/${script_name}/dist/"
	include apt

	apt::source { 'dotdeb':
		location   => 'http://packages.dotdeb.org',
		release    => 'wheezy-php55',
 		repos      => 'all',
		key        => '89DF5277',
 		key_source => 'http://www.dotdeb.org/dotdeb.gpg',
 	}->package { $base:
    		ensure   => 'latest',
    		require =>  Exec [ 'apt-update']
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

	exec { "apt-update":
		command => "/usr/bin/apt-get update",
	}

  class { 'nodejs':
    version => 'v0.10.28',
  }->package { $npm_pkg:
                provider => npm,
  }

  service { 'nginx':
    name    => "nginx",
    ensure  => running,
    enable  => true,
    require => Package[$nginx],
  }

  file { "/usr/local/sbin/webreader.sh":
    ensure  => file,
    mode    => 755,
    owner   => root,
    group   => root,
    source => "puppet:///modules/webreader/webreader.sh",
  }

	file { "/etc/init.d/${script_name}":
		ensure => file,
		mode => 755,
		owner => 'root',
		group => 'root',
		content => template('webreader/webreader.erb'),
	}

	file { "/etc/nginx/sites-available/${script_name}":
		ensure    => file,
		mode      => 644,
		owner     => 'root',
		group     => 'root',
		content   => template('webreader/node.erb'),
    require   => Package [$nginx],
	}

  file {"/etc/nginx/sites-enabled/${script_name}":
    ensure  => link,
    target  => "/etc/nginx/sites-available/${script_name}",
    require => File ["/etc/nginx/sites-available/${script_name}"],
    notify  => Service["nginx"],
  }
  file { "/etc/nginx/sites-enabled/default":
    ensure  => absent,
    require => Package [$nginx],
  }

	exec { 'ssh know github':
		command => 'ssh -Tv git@github.com -o StrictHostKeyChecking=no; echo Success',
		path    => '/bin:/usr/bin',
		user    => $wruser
	}

  /*
  file { "/var/www":
    ensure => directory,
    mode   => 775,
    owner  => 'root',
    group  => $wruser,
  }->
*/
  
  vcsrepo { "/var/www/${script_name}":
		  ensure   => latest,
		  provider => git,
		  revision => 'master',
		  source   => 'git@github.com:Gutenberg-Technology/Web-Reader.git',
  	  user     => $wruser,
  	  owner    => $wruser,
		  group    => $wrgrp,
  	  require  => Exec['ssh know github']
		}->service { "${script_name}":
                name    => $script_name,
                ensure  => running,
                enable  => true,
                require => File ["/etc/init.d/${script_name}"],
  }

}
