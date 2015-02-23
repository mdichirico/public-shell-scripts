# !/bin/bash
# 
# Copyright 2015 Michael Dichirico 
#
# This will enable error logging AND display errors to browser, which is meant for development environments.
#
# INSTRUCTIONS:
# 1. Copy this shell script to your home directory.
# 2. Make it executable with the following command:
#    chmod a+x php-ini-error-reporting-turn-on.sh
# 3. Execute the script with the following command:
#    sudo ./php-ini-error-reporting-turn-on.sh
# 
# This shell script will restart Apache upon completion, so you do not need to do that manually.
#
# It is safe to run this script more than one, but one time should be all that you need.
#
#

echo "Starting..."
MYPHPINI=`sudo find /etc -name php.ini -print`
echo "Path to php.ini: $MYPHPINI"
sudo sed -i "s/;error_log = php_errors.log/error_log = php_errors.log/" "$MYPHPINI"
sudo sed -i "s/;display_errors = On/display_errors = On/" "$MYPHPINI"
sudo sed -i "s/;log_errors = On/log_errors = On/" "$MYPHPINI"
sudo systemctl restart httpd
echo "Apache is restarting..."
echo "Finished!"
