#!/bin/bash
#
# setup-lamp-stack-on-cent-os-7.sh
#
# Sets up a LAMP stack environment using CentOS 7, PHP 5.6, MySQL 5.6, and Apache.
# Also installs PHPUnit and XDebug.
#
# Copyright (c) 2014-2015 Michael Dichirico (https://github.com/mdichirico)
# This software/script is released under the terms of the MIT license (http://en.wikipedia.org/wiki/MIT_License).
# 
# INSTRUCTIONS FOR USE:
# 1. Copy this shell script to your home directory or the /tmp directory.
# 2. Make it executable with the following command: 
#      chmod a+x setup-lamp-stack-on-cent-os-7.sh
# 3. Execute the script as a sudo user:
#      sudo ./setup-lamp-stack-on-cent-os-7.sh
#
#
# IMPORTANT: as of this writing on 2015-01-11, this shell script will support
# CentOS 6.4, 6.5, and 7. It has not been tested on a release greater than
# v7. That is 7 flat, not 7.1, 7.x.
#
# If you wish to use this script with a version of CentOS greater than v7 such as
# 7.1 or higher when they come out, you have to edit this script to be sure that the IUS and EPEL
# repositories correctly use the repos needed for newer versions of CentOS. The
# same applies to all other areas in this file where there is a check for an exact
# version of CentOS before doing a download and/or installation.
#
# It's important to point out that this script assumes that none of the binaries 
# that are to be installed are already present on the target server. If you already
# have the EPEL repository installed on your target server, you should first remove it
# by following the instructions in this link:
#
# http://www.cyberciti.biz/faq/centos-redhat-fedora-linux-remote-yum-repo-configuration/
#



# Since this script needs to be runnable on either CentOS7 or CentOS6, we need to first 
# check which version of CentOS that we are running and place that into a variable.
# Knowing the version of CentOS is important because some shell commands that had
# worked in CentOS 6 or earlier no longer work under CentOS 7
RELEASE=`cat /etc/redhat-release`
isCentOs7=false
isCentOs65=false
isCentOs64=false
isCentOs6=false
SUBSTR=`echo $RELEASE|cut -c1-22`
SUBSTR2=`echo $RELEASE|cut -c1-26`

if [ "$SUBSTR" == "CentOS Linux release 7" ]
then
    isCentOs7=true
elif [ "$SUBSTR2" == "CentOS release 6.5 (Final)" ]
then 
    isCentOs65=true

elif [ "$SUBSTR2" == "CentOS release 6.4 (Final)" ]
then 
    isCentOs64=true
else
    isCentOs6=true
fi

# TODO: add a check for versions earlier than 6.5

if [ "$isCentOs7" == true ]
then
    echo "I am CentOS 7"
elif [ "$isCentOs65" == true ]
then
    echo "I am CentOS 6.5"
elif [ "$isCentOs64" == true ]
then 
    echo "I am CentOS 6.4"
else
    echo "I am CentOS 6"
fi

CWD=`pwd`

# Let's make sure that yum-presto is installed:
sudo yum install -y yum-presto

# Let's make sure that mlocate (locate command) is installed as it makes much easier when searching in Linux:
sudo yum install -y mlocate

# Although not needed specifically for running a LAMP stack, I like to use vim, so let's make sure it is installed:
sudo yum install -y vim

# This shell script makes use of wget, so let's make sure it is installed:
sudo yum install -y wget

# it is important to sometimes work with content in a certain format, so let's be sure to install the following:
sudo yum install -y html2text

# This script makes use of 'sed' so let's make sure it is installed. While
# we're at it, let's also install 'awk'. It's most likely that these packages
# are already installed, but let's be sure. By the way, yes it is 'gawk' as the 
# pacakge name:
sudo yum install -y sed
sudo yum install -y gawk

# Let's make sure that we have the EPEL and IUS repositories installed.
# This will allow us to use newer binaries than are found in the standard CentOS repositories.
# http://www.rackspace.com/knowledge_center/article/install-epel-and-additional-repositories-on-centos-and-red-hat
sudo yum install -y epel-release
if [ "$isCentOs7" != true ]
then
    # The following is needed to get the epel repository to work correctly. Here is
    # a link with more information: http://stackoverflow.com/questions/26734777/yum-error-cannot-retrieve-metalink-for-repository-epel-please-verify-its-path
    sudo sed -i "s/mirrorlist=https/mirrorlist=http/" /etc/yum.repos.d/epel.repo
fi

if [ "$isCentOs7" == true ]
then
    sudo wget -N http://dl.iuscommunity.org/pub/ius/stable/CentOS/7/x86_64/ius-release-1.0-13.ius.centos7.noarch.rpm
    sudo rpm -Uvh ius-release*.rpm
else
    # Please note that v6.5, 6.4, etc. are all covered by the following repository:
    sudo wget -N http://dl.iuscommunity.org/pub/ius/stable/CentOS/6/x86_64/ius-release-1.0-13.ius.centos6.noarch.rpm
    sudo rpm -Uvh ius-release*.rpm
fi

# Let's make sure that openssl is installed:
sudo yum install -y openssl

# Let's make sure that curl is installed:
sudo yum install -y curl

# Let's make sure we have a C/C++ compiler installed:
sudo yum install -y gcc

# Let's make sure we have the latest version of bash installed, which
# are patched to protect againt the shellshock bug. Here is an article explaning
# how to check if your bash is vulnerable: http://security.stackexchange.com/questions/68168/is-there-a-short-command-to-test-if-my-server-is-secure-against-the-shellshock-b
sudo yum update -y bash

# Let's install our LAMP stack by starting with Apache:
sudo yum install -y httpd
if [ "$isCentOs7" == true ]
then
    sudo systemctl start httpd
else
    sudo service httpd start
fi

# Install MySQL:
if [ "$isCentOs7" == true ]
then
    sudo wget -N http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
    sudo yum localinstall -y mysql-community-release-el7-5.noarch.rpm
    sudo yum install -y mysql-community-server

    sudo systemctl start mysqld
elif [ "$isCentOs65" == true ]
then
    sudo wget -N https://repo.mysql.com/mysql-community-release-el6-5.noarch.rpm
    sudo yum localinstall -y mysql-community-release-el6-5.noarch.rpm
    sudo yum install -y mysql-community-server

    sudo service mysqld start
elif [ "$isCentOs64" == true ]
then
    sudo wget -N https://repo.mysql.com/mysql-community-release-el6-4.noarch.rpm
    sudo yum localinstall -y mysql-community-release-el6-4.noarch.rpm
    sudo yum install -y mysql-community-server

    sudo service mysqld start
else
    sudo wget -N https://repo.mysql.com/mysql-community-release-el6.rpm
    sudo yum localinstall -y mysql-community-release-el6.rpm
    sudo yum install -y mysql-community-server
    sudo service mysqld start
fi

# We need to edit the my.cnf and make sure that it is using utf8 as the default charset:
MYCNF=`sudo find /etc -name my.cnf -print`
INSERT1='skip-character-set-client-handshake'
INSERT2='collation-server=utf8_unicode_ci'
INSERT3='character-set-server=utf8'
INSERT5="default_time_zone='+00:00'"
# We also want to allow remote connections:
INSERT4='bind-address=127.0.0.1'
sudo sed -i "/\[mysqld\]/a$INSERT1\n$INSERT2\n$INSERT3\n$INSERT4\n$INSERT5" "$MYCNF"
# comment out the statement 'skip-networking' is commented out:
sudo sed -i 's/skip-networking/# skip-networking/' "$MYCNF"

# Make sure that we restart MySQL so the changes take effect 
if [ "$isCentOs7" == true ]
then
    sudo systemctl restart mysqld
else
    sudo service mysqld restart
fi

# Open port 3306 for remote connections to MySQL:
if [ "$isCentOs7" == true ]
then
    sudo firewall-cmd --zone=public --add-port=3306/tcp --permanent
    sudo firewall-cmd --reload
else
    sudo iptables -A INPUT -p tcp -m tcp --dport 3306 -j ACCEPT
    sudo service iptables save
    sudo service iptables restart
fi

# We need to also make sure that ports 80 and 443 are open for the web:
# Port 80:
if [ "$isCentOs7" == true ]
then
    sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
    sudo firewall-cmd --reload
else
    sudo iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
    sudo service iptables save
    sudo service iptables restart
fi

# Port 443:
if [ "$isCentOs7" == true ]
then
    sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
    sudo firewall-cmd --reload
else
    sudo iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
    sudo service iptables save
    sudo service iptables restart
fi


# Install PHP 5.6
sudo yum install -y php56u php56u-mysql php56u-bcmath php56u-cli php56u-common php56u-ctype php56u-devel php56u-embedded php56u-enchant php56u-fpm php56u-gd php56u-hash php56u-intl php56u-json php56u-ldap php56u-mbstring php56u-mysql php56u-odbc php56u-pdo php56u-pear.noarch ph56u-pecl-jsonc php56u-pecl-memcache php56u-pgsql php56u-phar php56u-process php56u-pspell php56u-openssl php56u-recode php56u-snmp php56u-soap php56u-xml php56u-xmlrpc php56u-zlib php56u-zip

# Edit the php.ini configuration file and set the default timezone to UTC:
MYPHPINI=`sudo find /etc -name php.ini -print`
PATTERN=';date.timezone =';
REPLACEMENT='date.timezone = UTC'
sudo sed -i "s/$PATTERN/$REPLACEMENT/" "$MYPHPINI"
# Also, turn on error logging and outputting errors to browser, which is meant for development environments:
sudo sed -i "s/;error_log = php_errors.log/error_log = php_errors.log/" "$MYPHPINI"
sudo sed -i "s/;display_errors = On/display_errors = On/" "$MYPHPINI"
sudo sed -i "s/;log_errors = On/log_errors = On/" "$MYPHPINI"

# Restart Apache
if [ "$isCentOs7" == true ]
then
    sudo systemctl start httpd
else
    sudo service httpd start
fi

# Add XDebug:
sudo pecl install xdebug
# and be sure to again edit the php.ini file to set the Xdebug extension:
MYPHPINI=`sudo find /etc -name php.ini -print`
XDEBUG=`sudo find /usr -name xdebug.so -print`
INSERT="zend_extension=$XDEBUG"
sudo sed -i "\$a$INSERT" "$MYPHPINI"

# Restart Apache for these php.ini edits to take effect:
if [ "$isCentOs7" == true ]
then
    sudo systemctl start httpd
else
    sudo service httpd start
fi


# Make sure that when the server boots up that both Apache and MySQL start automatically:
if [ "$isCentOs7" == true ]
then
    sudo systemctl enable httpd
    sudo systemctl enable mysqld
else
    sudo chkconfig httpd on
    sudo chkconfig mysqld on
fi

# Let's make sure that git is intalled:
sudo yum install -y git

# Install phpDox, which is needed by Jenkins. If you don't need it, it is ok to comment out the following three sudo commands.
# https://github.com/theseer/phpdox
sudo wget -N http://phpdox.de/releases/phpdox.phar
sudo chmod +x phpdox.phar
sudo mv phpdox.phar /usr/bin/phpdox


# Install 'composer':
sudo curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/bin --filename=composer

# Now that composer is installed, let's install PHPUnit and its associated packages:
sudo composer global require "phpunit/phpunit=4.3.*"
sudo composer global require "phpunit/php-invoker"
sudo composer global require "phpunit/dbunit": ">=1.2"
sudo composer global require "phpunit/phpunit-selenium": ">=1.2"

# PHP CodeSniffer:
sudo composer global require "squizlabs/php_codesniffer"

sudo composer update

echo ""
echo "Finished with setup!"
echo ""
echo "You can verify that PHP is successfully installed with the following command: php -v"
echo "You should see output like the following:"
echo ""
echo "PHP 5.6.4 (cli) (built: Dec 19 2014 10:17:51)"
echo "Copyright (c) 1997-2014 The PHP Group"
echo "Zend Engine v2.6.0, Copyright (c) 1998-2014 Zend Technologies"
echo ""
echo "If you are using CentOS 7, you can restart Apache with this command:"
echo "sudo systemctl restart httpd"
echo ""
echo "The MySQL account currently has no password, so be sure to set one."
echo "You can find info on securing your MySQL installation here: http://dev.mysql.com/doc/refman/5.6/en/postinstallation.html"
echo ""
echo "Happy development!"
echo ""
