set ${CI:+-x} -euo pipefail

# /*
# Unique SpamTagger Plus packages
# */
dnf -y install --setopt=install_weak_deps=False \
  composer \
  httpd \
  mod_ssl \
  mariadb \
  mariadb-server \
  mod_ssl \
  net-snmp \
  net-snmp-devel \
  perl-DBD-MariaDB \
  perl-Net-SNMP \
  php
# /*
# Try getting all PHP dependencies through composer
# php-bcmath \
# php-common \
# php-dba \
# php-gd \
# php-gmp \
# php-intl \
# php-mbstring \
# php-pecl-memcache \
# php-mysqlnd \
# php-pear \
# php-snmp \
# php-soap \
# php-xml \
# php-pecl-zip
# */

# /* Missing, perhaps resolved my net-snmp
# snmp-mibs-downloader
# snmpd
# */
