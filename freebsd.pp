# FreeBSD Puppet standalone recipe
# Francisco Cabrita : francisco.cabrita@gmail.com
# 18/Jun/2012

# TODO: Configure environment variables
# TODO: Configure SSHD KEYS
# TODO: Configure sysctls

# CHANGE THIS VARIABLES TO MATCH YOU NEEDS

$fbsd::username = 'include'
$fbsd::password = '$1$KnukxEEq$k/btq06o9z.mBTF1MNd8M0'
$fbsd::fullname = 'Francisco Cabrita'
$fbsd::email    = 'francisco.cabrita@gmail.com'
$fbsd::mydomain = 'jailaxy.com'
$fbsd::ip       = $::ipaddress_em0
$fbsd::dns      = '8.8.8.8'

$fbsd::dotfiles_repo = 'https://github.com/include/dotfiles.git'

##
# YOU!
class users {

  @group { 'puppet': ensure => present }

  realize Group['puppet']

  @user { $fbsd::username:
    ensure     => present,
    comment    => $fbsd::fullname,
    shell      => '/usr/local/bin/bash',
    home       => "/home/${fbsd::username}",
    password   => $fbsd::password,
    managehome => true,
    groups     => [ 'wheel' ]
  }

  realize User[$fbsd::username]
}


##
# BSD packages
class packages {
  package { [ 'curl',
              'bash',
              'vim-lite',
              'git',
              'portaudit',
              'portmaster',
              'tmux',
              'augeas' ]:
              ensure   => installed,
              provider => freebsd
  }
}


##
# BSD Services
class services {

  exec { 'bindssh':
    command => "sed -i -e 's/#ListenAddress 0.0.0.0/ListenAddress ${fbsd::ip}/' /etc/ssh/sshd_config",
    path    => [ '/usr/bin' ]
  }

  if $::is_virtual == true {
    $services = [ 'sshd' ]
  }
  else {
    $services = [ 'ntpdate', 'sshd' ]
  }

  service { $::services:
        ensure => running,
        enable => true
  }
}


##
# Core puppet environment
class puppetenv {

  $puppet_dirs = [  '/var/lib/puppet',
                    '/var/lib/puppet/facts',
                    '/var/lib/puppet/client_data',
                    '/var/lib/puppet/run',
                    '/var/lib/puppet/state',
                    '/var/lib/puppet/state/graphs',
                    '/var/lib/puppet/client_yaml',
                    '/var/lib/puppet/lib',
                    '/var/lib/puppet/clientbucket',
                    '/var/lib/puppet/log',
                    '/var/lib/puppet/rrd' ]

  file { $::puppet_dirs:
    ensure => directory,
    owner  => 'root',
    group  => 'puppet',
    mode   => '0750'
  }
}


##
# Base node settings
class base {
  include puppetenv

  file { '/etc/resolv.conf':
    content => "nameserver ${fbsd::dns}" }

  host { 'localhost':
    ensure       => present,
    ip           => '127.0.0.1',
    host_aliases => ['localhost'],
    target       => '/etc/hosts'
  }
  host { $::hostname:
    ensure       => present,
    ip           => $fbsd::ip,
    host_aliases => [$::hostname],
    target       => '/etc/hosts'
  }
  host { 'services':
    ensure       => present,
    ip           => '192.168.10.20',
    host_aliases => ["services.${fbsd::mydomain}"],
    target       => '/etc/hosts'
  }
  host { 'proxy':
    ensure       => present,
    ip           => '192.168.10.31',
    host_aliases => ["proxy.${fbsd::mydomain}"],
    target       => '/etc/hosts'
  }

  exec { 'gitclonedotfiles':
    command => "git clone ${fbsd::dotfiles_repo} /${::id}/dotfiles",
    cwd     => "/${::id}/",
    creates => "/${::id}/dotfiles",
    path    => [ '/usr/local/bin' ],
    require => Package['git']
  }

  exec { 'linkdotfiles':
    command => "/${::id}/dotfiles/makelinks.sh",
    #cwd     => "/${id}/dotfiles",
    require => Exec['gitclonedotfiles']
  }
}


##
# TBD - Jail settings
class jail {
  notify {'Info: HI CAN HAZ JAIL!': }
}


##
# Set MOTD
class bsd::conf::motd {

  file { 'motd':
    ensure  => file,
    path    => '/etc/motd',
    mode    => '0644',
    content => "Welcome to ${::operatingsystem} ${::operatingsystemrelease} \n\n" }
}


##
# Set localtime
class bsd::conf::localtime {

  file { '/etc/localtime':
    ensure => link,
    source => 'file:///usr/share/zoneinfo/Europe/Lisbon' }
}


##
# BSD specific class
class bsd {
  include base
  include users
  include packages
  include services
  include bsd::conf::motd
  include bsd::conf::localtime

  case $::virtual {
    /jail/: { include jail }
    default: { fail('HAZ NO JAILS') }
  }
}


# default node rule
node default {
  case $::operatingsystem {
    /FreeBSD/: { include bsd }
    default: { fail("Unrecognized operating system: ${::operatingsystem}") }
  }
}
