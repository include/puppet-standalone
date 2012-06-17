puppet-standalone
=================

Install Steps
-------------

1. `pkg_add -r bash`

2. `curl -L https://get.rvm.io | sudo bash -s stable`

3. `rvm install 1.8.7`

4. `rvm gemset create base18`

5. `rvm gemset use base18`

6. `gem install puppet`

7. `puppet freebsd.pp -v -d`
