define webreader::vhost (
	$nodeapp_dir,
  	$server_js,
	$root_dir       = '/var/www',
	$server_name 	= $name,
	$server 		= '127.0.0.1',
	$node_port      = '3000',
	$script_name    = 'webreader',
	$wruser		    = 'vagrant',
	$wrgrp		    = 'vagrant',
  	$nginx = $::webreader::nginx,
  	$vagrant = false
){

 if ! defined(Class['webreader']) {
    fail('You must include the webreader base class before using any webreader defined resources')
  }


  validate_bool($vagrant)

	# $nodeapp_dir = "/var/www/${script_name}/dist/"

	file { "/usr/local/sbin/webreader.sh":
	    ensure  => file,
	    mode    => 755,
	    owner   => 'root',
	    group   => 'root',
	    source => "puppet:///modules/webreader/webreader.sh",
	 }

	file { "/etc/init.d/${script_name}":
		ensure => file,
		mode => 755,
		owner => 'root',
		group => 'root',
		content => template('webreader/webreader.erb'),
	}

	service { "${script_name}":
		ensure => running,
		enable => true,
		require => [File["/etc/init.d/${script_name}"], Class['nodejs']],
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

	exec { 'ssh know github':
		command => 'ssh -Tv git@github.com -o StrictHostKeyChecking=no; echo Success',
		path    => '/bin:/usr/bin',
		user    => $wruser
	}

  if ! $vagrant {
    file { "${root_dir}":
    	ensure  => directory,
    	owner   => $wruser,
    	group   => $wrgrp,
    	mode    => 775,
    	require => Package [$nginx],
	}->vcsrepo 
		{ "${root_dir}/${script_name}":
			ensure   => latest,
			provider => git,
			revision => 'master',
			source   => 'git@github.com:Gutenberg-Technology/Web-Reader.git',
  			user     => $wruser,
  			owner    => $wruser,
			group    => $wrgrp,
  			require  => Exec['ssh know github']
		}
  }
}
