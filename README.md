puppet-standalone
=================

## Install Steps

1. Dependencies:

    pkg_add -r bash

2. Installing and Configuring RVM

    curl -L https://get.rvm.io | bash -s stable

    rvm install 1.8.7

    rvm gemset create base18

    rvm gemset use base18

3. Installing Puppet

    gem install puppet

4. Configuring FreeBSD recipe

Edit `freebsd.pp` and change settings to match your needs:

Don't forget to generate a new password to use in password field:

    openssl passwd -1 changepass

5. Finally, run it:

    puppet freebsd.pp -v -d
