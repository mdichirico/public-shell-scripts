# !/bin/bash
#
# (c) 2015 Michael Dichirico <https://github.com/mdichirico>
#
# Installs Java 8 and ElaticSearch on a CentOS 7 environment.`
#
# References:
# http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/setup-repositories.html
# https://www.unixmen.com/install-oracle-java-jdk-8-centos-76-56-4/
#
#############################################################################################################
#
#                                     IMPORTANT! IMPORTANT! IMPORTANT! 
#
# - Before running this script, you need to download the official Oracle Java JDK:
#   http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
#   
#   At the time of this writing, from that above link to oracle.com, I downloaded 
#   the "Linux x64" RPM file "jdk-8u40-linux-x64.rpm" since I was installing to a CentOS 7 64-bit image.
#
#   Download to your HOME directory.
#   
# - If you had previously installed OpenJDK v6 or OpenJDK v7, this shell script will attempt to remove it.
#   If you see the following output during the execution of this script, it is fine:
#     "No Match for argument: java-1.7.0-openjdk"
#     "No Match for argument: java-1.6.0-openjdk"
#
# - This script assumes that the file "jdk-8u40-linux-x64.rpm" (or equivalent) has been downloaded to your home directory. 
#   If your file is located elsewhere or you have a filename newer than jdk-8u40-linux-x64.rpm, update
#   the variable JAVA_RPM to the correct location/filename. Use an absolute path.
#
# - This script has a dependency on two other files: "java.sh" and "elasticsearch.repo". If you have not already
#   downloaded them, you can find them here:
#   https://github.com/mdichirico/public-shell-scripts
#
#   By default, this script assumes that those two files are located in the same directory as this shell script. 
#   If they are located elsewhere in your filesystem, update the variables JAVA_SH and ELASTICSEARCH_REPO_FILE. 
#   Use absolute paths.
# 
#############################################################################################################
#
# Instructions:
#
# 1. Save this shell to your home directory or /tmp directory.
#
# 2. Make the script executable:
#    chmod a+x setup-elasticsearch-on-cent-os-7.sh
#
# 3. Execute the script with sudo privileges:
#    sudo ./setup-elasticsearch-on-cent-os-7.sh
#
#############################################################################################################

JAVA_RPM=~/jdk-8u40-linux-x64.rpm
JAVA_SH=./java.sh
ELASTICSEARCH_REPO_FILE=./elasticsearch.repo

if [ ! -f $JAVA_RPM ];
then
    echo ""
    echo "Could not locate the file $JAVA_RPM. Did you download it?"
    echo "See the section IMPORTANT! IMPORTANT! IMPORTANT! in this script"
    echo "Aborting..."
    echo ""
    exit 1
fi;

if [ ! -f $JAVA_SH ];
then
    echo ""
    echo "Could not locate the file $JAVA_SH. Did you download it?"
    echo "See the section IMPORTANT! IMPORTANT! IMPORTANT! in this script"
    echo "Aborting..."
    echo ""
    exit 1
fi;

if [ ! -f $ELASTICSEARCH_REPO_FILE ];
then
    echo ""
    echo "Could not locate the file $ELASTICSEARCH_REPO_FILE. Did you download it?"
    echo "See the section IMPORTANT! IMPORTANT! IMPORTANT! in this script"
    echo "Aborting..."
    echo ""
    exit 1
fi;

# ElasticSearch requires Java, but they recommend using the official Oracle Java 1.8 JDK
sudo yum remove -y java
sudo yum remove java-1.7.0-openjdk
sudo yum remove java-1.6.0-openjdk

sudo rpm -ivh "$JAVA_RPM"

# copy our Java start up script to /etc/init.d
sudo cp "$JAVA_SH" /etc/profile.d/
sudo chmod +x /etc/profile.d/java.sh
source /etc/profile.d/java.sh

# Although we've copied java.sh to the /etc/profile.d directory, it turns out
# that that won't help us when we want to use 'sudo' commands as it is
# only of use to our non-privileged account. Let's fix this by simply creating symlinks
# First, let's make sure no Java related symlinks already exist:
sudo rm -f /usr/bin/java
sudo rm -f /usr/bin/javac
sudo rm -f /usr/bin/javaws
sudo rm -f /usr/bin/jar

# Now, let's create our Java 1.8 symlinks:
sudo ln -s /usr/java/jdk1.8.0_40/bin/java /usr/bin/java
sudo ln -s /usr/java/jdk1.8.0_40/bin/javac /usr/bin/javac
sudo ln -s /usr/java/jdk1.8.0_40/bin/jar /usr/bin/jar
sudo ln -s /usr/java/jdk1.8.0_40/bin/javaws /usr/bin/javaws

# Set up the elasticsearch yum-based repository:
sudo rpm --import https://packages.elasticsearch.org/GPG-KEY-elasticsearch

sudo cp "$ELASTICSEARCH_REPO_FILE" /etc/yum.repos.d/

#Ok, let's now use yum to do the installation of elasticsearch
sudo yum install -y elasticsearch


echo ""
echo "Please wait while we start elasticsearch..."
echo ""

# Let's start elasticsearch:
sudo /sbin/chkconfig --add elasticsearch
sudo service elasticsearch start

# Let's make sure that elasticsearch starts automatically upon system boot:
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service

echo ""
echo "Success! Elasticsearch is installed and currently running."
echo ""
