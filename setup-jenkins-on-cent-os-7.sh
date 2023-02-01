#!/bin/bash
#
# Copyright (c) 2014-2015 Michael Dichirico (https://github.com/mdichirico)
# This software/script is released under the terms of the MIT license (http://en.wikipedia.org/wiki/MIT_License).
#
# I wrote this shell script to use Jenkins with a LAMP stack environment. 
# If you need or would like to set up a LAMP environment for use with Jenkins, use this script first:
#   https://github.com/mdichirico/public-shell-scripts/blob/master/setup-lamp-stack-on-cent-os-7.sh
# Then run this script by following the INSTRUCTIONS FOR USE that follows.
#
# INSTRUCTIONS FOR USE:
# 1. Copy this shell script to your home directory or the /tmp directory.
# 2. Make it executable with the following command: 
  #   chmod a+x setup-jenkins-on-cent-os-7.sh
# 3. Execute the script as a sudo user:
   # sudo ./setup-jenkins-on-cent-os-7.sh
#
# It's important to point out that this script assumes that none of the binaries 
# that are to be installed are already present on the target server. If you already
# have the EPEL repository installed on your target server, you should first remove it
# by following the instructions in this link:
#
# http://www.cyberciti.biz/faq/centos-redhat-fedora-linux-remote-yum-repo-configuration/
#
# If you already have Jenkins installed on your target server, please be aware that
# the user 'Anonymous' needs to have ALL privileges in order to successfully plugins
# as part of this shell script. After running this shell script, you can return
# the anonynous user to have less privileges.

# Since this script needs to be runnable on either CentOS7 or CentOS6, we need to first 
# check which version of CentOS that we are running and place that into a variable.
# Knowing the version of CentOS is important because some shell commands that had
# worked in CentOS 6 or earlier no longer work under CentOS 7
RELEASE=`cat /etc/redhat-release`
isCentOs7=false
SUBSTR=`echo $RELEASE|cut -c1-22`

if [ "$SUBSTR" == "CentOS Linux release 7" ]
then
    isCentOs7=true
fi

if [ "$isCentOs7" == true ]
then
    echo "I am CentOS 7"
fi

CWD=`pwd`

# Let's make sure that yum-presto is installed:
sudo yum install -y yum-presto

# Let's make sure that mlocate (locate command) is installed as it makes much easier when searching in Linux:
sudo yum install -y mlocate

# Although not needed for Jenkins, I like to use vim, so let's make sure it is installed:
sudo yum install -y vim

# The Jenkins setup makes use of wget, so let's make sure it is installed:
sudo yum install -y wget

# Let's make sure that we have the EPEL and IUS repositories installed.
# This will allow us to use newer binaries than are found in the standard CentOS repositories.
# http://www.rackspace.com/knowledge_center/article/install-epel-and-additional-repositories-on-centos-and-red-hat
sudo yum install -y epel-release
if [ "$isCentOs7" == true ]
then
    sudo wget -N http://dl.iuscommunity.org/pub/ius/stable/CentOS/7/x86_64/ius-release-1.0-13.ius.centos7.noarch.rpm
    sudo rpm -Uvh ius-release*.rpm
else
    sudo wget -N http://dl.iuscommunity.org/pub/ius/stable/CentOS/6/x86_64/ius-release-1.0-13.ius.centos6.noarch.rpm
    sudo rpm -Uvh ius-release*.rpm
fi

# Let's make sure that openssl is installed:
sudo yum install -y openssl

# Let's make sure that curl is installed:
sudo yum install -y curl

# Jenkins on CentOS requires Java, but it won't work with the default (GCJ) version of Java. So, let's remove it:
sudo yum remove -y java

# install the OpenJDK version of Java 7:
sudo yum install -y java-1.7.0-openjdk

# Jenkins uses 'ant' so let's make sure it is installed:
sudo yum install -y ant

# Let's now install Jenkins:
sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
sudo rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key
sudo yum install -y jenkins

# Let's start Jenkins
if [ "$isCentOs7" == true ]
then
    sudo systemctl start jenkins
else 
    sudo service jenkins start
fi

# Jenkins runs on port 8080 by default. Let's make sure port 8080 is open:
if [ "$isCentOs7" == true ]
then
    sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent
    sudo firewall-cmd --reload
else
    sudo iptables -A INPUT -p tcp -m tcp --dport 8080 -j ACCEPT
    sudo service iptables save
    sudo service iptables restart
fi

# Let's make sure that git is installed since Jenkins will need this
sudo yum install -y git

# Install phpDox, which is needed by Jenkins.
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

# We need to increase the memory limit used by PHP:
sudo sed -i 's/memory_limit = 128M/memory_limit = 2048M/g' /etc/php.ini

# Let's update Jenkins to use the PHP tools that we had installed with Composer:
sudo curl -L http://updates.jenkins-ci.org/update-center.json | sed '1d;$d' | curl -X POST -H 'Accept: application/json' -d @- http://localhost:8080/updateCenter/byId/default/postBack

sudo wget -N http://localhost:8080/jnlpJars/jenkins-cli.jar

sudo java -jar jenkins-cli.jar -s http://localhost:8080 install-plugin checkstyle cloverphp crap4j dry htmlpublisher jdepend plot pmd violations xunit

# Install the PHP-Jenkins job template:
sudo wget -N http://localhost:8080/jnlpJars/jenkins-cli.jar
sudo curl -L https://raw.githubusercontent.com/sebastianbergmann/php-jenkins-template/master/config.xml | sudo java -jar jenkins-cli.jar -s http://localhost:8080 create-job php-template

# Lastly, let's install the plugins needed in Jenkins to connect to Github and get a fairly well-running Jenkins installation:
cd /var/lib/jenkins/plugins
sudo rm -R -f ant
sudo rm -R -f credentials
sudo rm -R -f deploy
sudo rm -R -f git-client
sudo rm -R -f git
sudo rm -R -f github-api
sudo rm -R -f github-oauth
sudo rm -R -f github
sudo rm -R -f gcal
sudo rm -R -f google-oauth-plugin
sudo rm -R -f greenballs
sudo rm -R -f javadoc
sudo rm -R -f ldap
sudo rm -R -f mailer 
sudo rm -R -f mapdb-api
sudo rm -R -f maven-plugin
sudo rm -R -f external-monitor-job
sudo rm -R -f oauth-credentials
sudo rm -R -f pam-auth
sudo rm -R -f scm-api
sudo rm -R -f ssh-agent
sudo rm -R -f ssh-credentials
sudo rm -R -f ssh-slaves
sudo rm -R -f subversion
sudo rm -R -f translation
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin ant
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin credentials
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin deploy
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin git-client
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin git
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin github-api
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin github-oauth
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin github
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin gcal
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin google-oauth-plugin
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin greenballs
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin javadoc
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin ldap
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin mailer
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin mapdb-api
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin maven-plugin
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin external-monitor-job
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin oauth-credentials
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin pam-auth
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin scm-api
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin ssh-agent
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin ssh-credentials
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin ssh-slaves
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin subversion
sudo java -jar $CWD/jenkins-cli.jar -s http://localhost:8080/ install-plugin translation

# Be sure to change ownership of all of these downloaded plugins to jenkins:jenkins
sudo chown jenkins:jenkins *.hpi
sudo chown jenkins:jenkins *.jpi

# Restart Jenkins to implement the new plugins:
cd $CWD

# Let's start Jenkins
sudo java -jar jenkins-cli.jar -s http://localhost:8080 safe-restart

# Update the 'locate' database:
sudo updatedb

echo ""
echo "Finished with setup"
echo ""
echo "You can visit your Jenkins installation at the following address (substitute 'localhost' if necessary):"
echo "  http://localhost:8080"
echo ""
echo "Although Jenkins should be installed at this point, it hasn't been secured. See this link:"
echo "https://wiki.jenkins-ci.org/display/JENKINS/Standard+Security+Setup"
echo ""

