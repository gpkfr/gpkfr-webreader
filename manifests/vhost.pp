class webreader::vhost (
	$server_name 	= "wr.gutenberg-technology.com",
	$server 		= '127.0.0.1',
	$script_name    = 'webreader',
	$node_port      = '3000',
	$wruser		    = 'vagrant',
	$wrgrp		    = 'vagrant',
){

	$nodeapp_dir = "/var/www/${script_name}/dist/"

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
  
	vcsrepo { "/var/www/${script_name}":
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