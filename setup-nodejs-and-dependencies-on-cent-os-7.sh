# !/bin/bash
#
# PLEASE READ:
#
# This script is meant for use on a CentOS 7 environment that does not already
# have Node.js installed. It will install a fresh copy of Node.js, but it does
# not make any attempt to upgrade an existing Node.js installation.
#
# For best results, use this script AFTER you have run the setup-lamp-stack-on-cent-os-7.sh script.
#
# Author: Michael Dichirico <mike.dichirico@gmail.com> / Github: mdichirico

clear
CWD=`pwd`
cd /tmp

# Let's make sure we don't have any residual from a previous attempt at installing this script:
sudo rm -R -f /tmp/node-v0.12.0-linux-x64
sudo rm -f /tmp/node-v0.12.0-linux-x64.tar.gz

sudo rm -f /usr/bin/node
sudo rm -f /usr/bin/npm

sudo rm -R -f /usr/local/bin/node-v0.12.0-linux-x64

# We should try to remove Node.js if it has been installed via the yum package manager.
# This shouldn't be necessary, however, if users are running this script on an environment
# that doesn't already have Node.js installed as had already been warned.
sudo yum erase -y nodejs

# Let's setup the 'client' portion. It requires Node.js and related tools, so let's make sure they are installed.
# We will be using the Node.js build described here: https://github.com/joyent/node/wiki/installing-node.js-via-package-manager#enterprise-linux-and-fedora
wget http://nodejs.org/dist/v0.12.0/node-v0.12.0-linux-x64.tar.gz

# The following instructions come from https://www.digitalocean.com/community/tutorials/how-to-install-node-js-on-a-centos-7-server:
# The following will extract the binary package into our system's local package hierarchy
# with the tar command. The archive is packaged with a versioned directory, which we can get rid
# of by passing the --strip-components l option. We will specify the target directory of our
# command with the -C command:
sudo tar --strip-components 1 -xzvf node-v* -C /usr/local

# Confirm that Node.js is installed by checking for its version number to be output:
cd ~
node --version

# clean-up downloaded files:
sudo rm -R -f /tmp/node-v0.12.0-linux-x64

# install NPM for the current user (yourself!):
rm -f ~/install.sh
curl https://raw.githubusercontent.com/creationix/nvm/v0.23.3/install.sh | bash
source ~/.bashrc
rm -f ~/install.sh

# Create symlinks to node and npm so when you run them as sudo, you don't get errors. First, let's make sure symlinks
# don't already exist:
sudo rm -f /usr/bin/node
sudo rm -f /usr/lib/node
sudo rm -f /usr/bin/npm
sudo rm -f /usr/bin/node-waf

# Now we can create our symlinks:
sudo ln -s /usr/local/bin/node /usr/bin/node
sudo ln -s /usr/local/lib/node /usr/lib/node
sudo ln -s /usr/local/bin/npm /usr/bin/npm
sudo ln -s /usr/local/bin/node-waf /usr/bin/node-waf

# Install ruby and ruby-devel for compass, sass and grunt to work
sudo yum -y install ruby ruby-devel rubygems
gem install json_pure compass


# Let's now install bower:
sudo npm install -g bower grunt-cli grunt-contrib-compass
sudo npm install -g grunt
# Install yeoman:
sudo npm install -g yo

# Got into the /client directory and install components listed in bower.json
cd "$CWD/../client"
bower install
grunt



echo ""
echo "Finished installing Node.js, npm, and bower"
echo ""

