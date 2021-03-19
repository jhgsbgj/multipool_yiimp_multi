#!/usr/bin/env bash

#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by cryptopool.builders for crypto use...
#####################################################
source /etc/functions.sh
source /etc/multipool.conf
echo "Starting Remote Web Server Build..."
if [[ ! -e '$STORAGE_ROOT/yiimp/' ]]; then
sudo mkdir -p $STORAGE_ROOT/yiimp/
sudo cp -r /tmp/.yiimp.conf $STORAGE_ROOT/yiimp/
source $STORAGE_ROOT/yiimp/.yiimp.conf
else
sudo cp -r /tmp/.yiimp.conf $STORAGE_ROOT/yiimp/
source $STORAGE_ROOT/yiimp/.yiimp.conf
fi

# Set timezone
echo Setting TimeZone to UTC...
if [ ! -f /etc/timezone ]; then
echo "Setting timezone to UTC."
echo "Etc/UTC" > sudo /etc/timezone
restart_service rsyslog
fi

# Add repository
echo Adding the required repsoitories...
if [ ! -f /usr/bin/add-apt-repository ]; then
echo "Installing add-apt-repository..."
hide_output sudo apt-get -y update;
apt_install software-properties-common;
fi
# PHP 7
echo Installing Ondrej PHP PPA...
if [ ! -f /etc/apt/sources.list.d/ondrej-php-bionic.list ]; then
hide_output sudo add-apt-repository -y ppa:ondrej/php;
fi
# MariaDB
echo Installing MariaDB Repository...
hide_output sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8;
sudo add-apt-repository 'deb [arch=amd64,arm64,i386,ppc64el] http://mirrors.accretive-networks.net/mariadb/repo/10.3/ubuntu xenial main'
wait $!

# Upgrade System Files
echo Updating system packages...
hide_output sudo apt-get update;
wait $!

echo Upgrading system packages...
if [ ! -f /boot/grub/menu.lst ]; then
apt_get_quiet upgrade;
wait $!

else
sudo rm /boot/grub/menu.lst
hide_output sudo update-grub-legacy-ec2 -y;
wait $!

apt_get_quiet upgrade;
wait $!
fi

echo Running Dist-Upgrade...
apt_get_quiet dist-upgrade;
wait $!

echo Running Autoremove...
apt_get_quiet autoremove;
wait $!

echo Installing Base system packages...
apt_install python3 python3-dev python3-pip \
wget curl git sudo coreutils bc \
haveged pollinate unzip \
unattended-upgrades cron ntp fail2ban screen;
wait $!

# ### Seed /dev/urandom
echo Initializing system random number generator...
hide_output dd if=/dev/random of=/dev/urandom bs=1 count=32 2> /dev/null
hide_output sudo pollinate -q -r
wait $!

echo Installing YiiMP Required system packages...
if [ -f /usr/sbin/apache2 ]; then
echo Removing apache...
hide_output apt-get -y purge apache2 apache2-*;
wait $!

hide_output apt-get -y --purge autoremove;
wait $!
fi

hide_output sudo apt-get update;
wait $!

apt_install php7.2-fpm php7.2-opcache php7.2-fpm php7.2 php7.2-common php7.2-gd \
php7.2-mysql php7.2-imap php7.2-cli php7.2-cgi \
php-pear php-auth-sasl mcrypt imagemagick libruby \
php7.2-curl php7.2-intl php7.2-pspell php7.2-recode php7.2-sqlite3 \
php7.2-tidy php7.2-xmlrpc php7.2-xsl memcached php-memcache \
php7.2-memcache php7.2-memcached memcached \
php-imagick php-gettext php7.2-zip php7.2-mbstring \
fail2ban ntpdate python3 python3-dev python3-pip \
curl git sudo coreutils pollinate unzip unattended-upgrades cron mariadb-client \
nginx pwgen;
wait $!

echo Downloading selected YiiMP Repo...
hide_output sudo git clone $YiiMPRepo $STORAGE_ROOT/yiimp/yiimp_setup/yiimp;
if [[ ("$CoinPort" == "y" || "$CoinPort" == "Y" || "$CoinPort" == "yes" || "$CoinPort" == "Yes" || "$CoinPort" == "YES") ]]; then
	cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp
	sudo git fetch
	sudo git checkout multi-port
fi

exit 0
