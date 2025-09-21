set ${CI:+-x} -euo pipefail

# /*
# Enable UBlue OS repo for image signing
# */

dnf -y copr enable ublue-os/packages

# /*
# Common SpamTagger / SpamTagger Plus packages
# */

dnf -y install --setopt=install_weak_deps=False --allowerasing \
  bind \
  bogofilter \
  bzip2 \
  clamav \
  clamav-unofficial-sigs \
  composer \
  cronie \
  crontabs \
  distrobox \
  dnsutils \
  exim \
  exim-greylist \
  fail2ban \
  git \
  gzip \
  httpd \
  ipset \
  iputils \
  kbd \
  libspf2 \
  links \
  lsb-release \
  lzma \
  mariadb \
  mariadb-server \
  mod_ssl \
  net-snmp \
  net-snmp-perl-module \
  openssl \
  openssh \
  openssh-server \
  open-vm-tools \
  perl-App-cpanminus \
  perl-DBD-MariaDB \
  perl-Digest-SHA \
  perl-Digest-HMAC \
  perl-LDAP \
  perl-Net-SNMP \
  perl-LWP-Protocol-https \
  perl-PerlIO-gzip \
  perl-SNMP_Session \
  php \
  podman \
  poppler-utils \
  procps \
  python-is-python3 \
  pyzor \
  qemu-guest-agent \
  re2c \
  rrdtool \
  rrdtool-perl \
  rsyslog \
  rsync \
  spamassassin \
  systemd-container \
  telnet \
  tesseract \
  ublue-os-signing \
  usbutils \
  vim \
  wget \
  wireguard-tools

# /*
# apply custom signing policy then disable ublue repo
# */

mv /etc/containers/policy.json /etc/containers/policy.json-upstream
mv /usr/etc/containers/policy.json /etc/containers/
rm -fr /usr/etc
sed -i 's/ublue-os/spamtagger/' /etc/containers/policy.json
dnf -y copr disable ublue-os/packages

# /*
# DCC doesn't have an official package, but is packaged by the OpenSuSE Build Service
# */

OBS_PATH="https://download.opensuse.org/repositories/home:/voegelas/AlmaLinux_10/x86_64/"
VERSION=$(curl $OBS_PATH 2>/dev/null | grep -P 'dcc-[0-9]' | grep -v mirrorlist | sed 's/.*href="\.\/\([^"]*\)".*/\1/')
wget $OBS_PATH$VERSION
rpm -i $VERSION
rm $VERSION

# /* The following Perl libraries were distributed in MailCleaner's 'install/src/perl' directory or
# were included in the list of debian packages but don't appear to be used within the current source
# code. We need to verify which of these dependencies still exist and (eg. via MailScanner) and
# download them via CPAN if we still need them.
#
# AI::Categorizer
# AI::DecisionTree
# Algorithm::NaiveBayes
# Algorithm::SVM
# Archive::Any::Lite
# Archive::Zip
# Archive::Zip::SimpleZip
# Business::ISBN
# Compress::Raw::Zlib
# Compress::Zlib
# config::YAML
# Convert::TNEF
# Crypt::DES
# Crypt::OpenSSL::AES
# Crypt::OpenSSL::Bignum
# Crypt::OpenSSL::Random
# Crypt::OpenSSL::RSA
# Cwd
# Data::Dump
# Data::Validate::Domain
# Date::Pcalc
# DB_File
# Digest
# Digest::MD5
# Digest::Nilsimsa
# Digest::SHA
# Encode::Detect
# Error
# ExtUtils::CBuilder
# ExtUtils::Constant
# ExtUtils::MakeMaker
# ExtUtils::ParseXS
# File::Spec
# File::Temp
# File::Which
# Filesys::Df
# Getopt::Long
# Geography::Countries
# HTML::Parser
# HTML::Tagset
# IMAP::Client
# Inline
# Inline::C
# IO::Socket::IP
# IO::Socket::SSL
# IO::Compress
# IO::Compress::Base
# IO::Compress::Zlib
# IO::String
# IO::stringy
# IO::Socket::INET6
# IO::Socket::SSL
# IP::Country
# Log::Agent
# Log::Log4perl
# Mail::ClamAV
# Mail::DomainKeys
# Mail::SPF::Query
# MLDBM
# MLDBM::Sync
# MIME::Base64
# MIME::Lite
# MIME::tools
# Module::Signature
# NetAddr::IP
# Net::DNS::Resolver::Programmable
# Net::Ident
# Net::IMAP::Simple
# Net::IMAP::Simple::SSL
# NetSNMP::default_store
# Net_SSLeay.pm
# NTLM
# OLE::Storage_Lite
# OO.pm.patch
# Parse::RecDescent
# Pod::Escapes
# Pod::Parser
# Pod::Simple
# Pod::Readme
# podlators
# PathTools
# re2c
# Scalar::List::Utils
# Socket
# Socket6
# Statistics::Contingency
# Storable
# String::Approx
# Sys::SigAction
# Sys::Hostname::Long
# Tie::Cache
# Time::HiRes
# Time::Progress
# TimeDate
# Test::Simple
# Test::Harness
# URI::imap
# URI::Find::Rule
# version
# XML::Parser
# */

# /* Possibly replaced by perl-Razor-Agent, but would likely need an updated module.
# razor
# */

# /*
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
#
# Missing php modules
# php-imap
# php-mcrypt
# php-xmlrpc (provided by Zend)
# */

# /*
# Install missing Perl dependencies from CPAN
# GreylistD doesn't have an official package. Investigate built-in greylisting configuration provided by exim-greaylist:
# https://github.com/Exim/exim/wiki/SimpleGreylisting
# Otherwise, greylistd is just a python program, so we can fetch from GitHub and write a simple installer.
# git clone https://github.com/SpamTagger/greylistd
# */

# /*
# missing Apache modules
# libapache2-mpm-itk (or something like (mod_mpm-itx) doesn't exist. Other MPM modules probably exist, but I don't think we actually need to run multilple vhosts, so this is not needed.
# */

# /*
# Dependencies for custom Exim package. Test what features are missing from CentOS package before compiling our own.
# libssl3 (now openssl-devel?) \
# libpcre3
# */

# /* Pending acceptance for EPEL 10 https://bodhi.fedoraproject.org/updates/?packages=pwgen
# Maybe just generate our own random password (used in install/installer.pl).
#
# pwgen
# */

# /* Missing, perhaps resolved my net-snmp
# snmp-mibs-downloader
# */
cpanm Mail::IMAPClient
cpanm Mail::POP3Client
cpanm RRDTool::OO
cpanm IPC::Shareable
cpanm IO::Interactive

rm -rf ~/.cpan/build
