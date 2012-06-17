# FreeBSD Puppet standalone recipe
# Francisco Cabrita : francisco.cabrita@gmail.com
# 17/Jun/2012

# TODO: Fix password issue
# TODO: Fetch dotfiles
# TODO: Configure environment variables
# TODO: Configure SSHD KEYS
# TODO: Configure sysctls

# CHANGE THIS VARIABLES TO MATCH YOU NEEDS

$username = "include"
$password = "mudarpwd"
$fullname = "Francisco Cabrita"
$email = "francisco.cabrita@gmail.com"
$mydomain = "jailaxy.com"
$ip = "${ipaddress_em0}"
$dns = "8.8.8.8"

class users {

  @group { "puppet": ensure => present }

  realize Group["puppet"]

  @user { $username:
    ensure => present,
    comment => $fullname,
    shell   => "/usr/local/bin/bash",
    home => "/home/${username}",
    password => "mudarpwd",
    managehome => true,
    groups => [ "wheel" ] }

  realize User[$username]

#  exec { "fix_passwd":
#    command     => "/bin/echo ${password} | /usr/sbin/pw usermod ${username} -h 0",
#    refreshonly => true }

}


class packages { 
  package { [ "curl",
              "bash",
              "vim-lite",
              "git",
              "portaudit",
              "portmaster",
              "tmux" ]:
              provider => freebsd,
              ensure => installed }
}


class services {

  $services = [ "ntpdate", "sshd" ]

  service { $services:
        ensure => running,
        enable => true }

}


class puppetenv {

  $puppet_dirs = [ "/var/lib/puppet",
                   "/var/lib/puppet/facts",
                   "/var/lib/puppet/client_data",
                   "/var/lib/puppet/run",
                   "/var/lib/puppet/state",
                   "/var/lib/puppet/state/graphs",
                   "/var/lib/puppet/client_yaml",
                   "/var/lib/puppet/lib",
                   "/var/lib/puppet/clientbucket",
                   "/var/lib/puppet/log",
                   "/var/lib/puppet/rrd" ]

  file { $puppet_dirs:
    ensure => "directory",
    owner  => "root",
    group  => "puppet",
    mode   => 750 }

}


class base {
  include puppetenv

  file { "/etc/resolv.conf":
    content => "nameserver ${dns}" }

  host { "localhost":
    ensure => present,
    host_aliases => ["localhost"],
    ip => "127.0.0.1",
    target => "/etc/hosts"
  }
  host { $hostname:
    ensure => present,
    ip => $ip,
    host_aliases => [$hostname],
    target => "/etc/hosts"
  }
  host { "services":
    ensure => present,
    host_aliases => ["services.${mydomain}"],
    ip => "192.168.10.20",
    target => "/etc/hosts"
  }
  host { "proxy":
    ensure => present,
    ip => "192.168.10.31",
    host_aliases => ["proxy.${mydomain}"],
    target => "/etc/hosts"
  }
}


class bsd {
  include base
  include users
  include services
  include packages
}


node default {
  case $operatingsystem {
    /FreeBSD/: { include bsd }
    default: { fail("Unrecognized operating system: ${operatingsystem}") }
  }
}
