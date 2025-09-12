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
  net-snmp-perl-module \
  perl-DBD-MariaDB \
  perl-Digest-SHA1 \
  perl-Digest-HMAC \
  perl-LDAP \
  perl-MIME-tools \
  perl-Net-SNMP \
  perl-Perl-Critic \
  perl-Regexp-Common \
  perl-SNMP_Session \
  php \
  rrdtool-perl
# /*
# net-snmp-devel \
# net-snmp-perl-module \
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
# */

# /* The following Perl libraries were distributed in MailCleaner's 'install/src/perl' directory
# and were installed for the local Perl version with 'install/install_perl_libs.sh'.
# We need to verify which of these dependencies still exist and source them from elsewhere,
# prioritizing the CentOS repos, then CPAN
#
# Digest::MD5
# Filesys::Df
# Net::IMAP::Simple::SSL
# Mail::DomainKeys
# Pod::Parser
# Net::DNS
# Pod::Simple
# Parse::RecDescent
# PathTools
# Mail::SPF
# Module::Build
# MIME::Base64
# File::Spec
# MailTools
# Mail::POP3Client
# Crypt::OpenSSL::Random
# XML::Parser
# Log::Log4perl
# re2c
# Net::IP
# Time::Progress
# NetAddr::IP
# Compress::Zlib
# Time::HiRes
# MLDBM::Sync
# Pod::Readme
# Storable
# Crypt::OpenSSL::AES
# Statistics::Contingency
# IO::Socket::IP
# Digest
# Mail::ClamAV
# NTLM
# DBD::SQLite
# Algorithm::NaiveBayes
# Pod::Escapes
# Log::Agent
# OLE::Storage_Lite
# MLDBM
# HTML::Parser
# Socket6
# Compress::Raw::Zlib
# Net::CIDR
# URI
# Algorithm::SVM
# version
# MIME::Lite
# Module::Signature
# File::Temp
# Net::DNS::Resolver::Programmable
# Crypt::OpenSSL::Bignum
# MIME::tools
# DBD::mysql
# Net_SSLeay.pm
# IO::Socket::SSL
# ExtUtils::MakeMaker
# ExtUtils::ParseXS
# Inline
# Authen::Radius
# NetSNMP::default_store
# HTML::Tagset
# DBI
# IO::Socket::INET6
# Net::SNMP
# URI::imap
# URI::Find::Rule
# ExtUtils::CBuilder
# Convert::TNEF
# TimeDate
# String::Approx
# Digest::SHA
# AI::DecisionTree
# Sys::Hostname::Long
# Scalar::List::Utils
# RRDTool::OO
# IP::Country
# Encode::Detect
# AI::Categorizer
# Cwd
# Socket
# OO.pm.patch
# IO::stringy
# Date::Pcalc
# File::Which
# DB_File
# podlators
# Mail::DKIM
# Net::Ident
# IMAP::Client
# Sys::SigAction
# Archive::Zip
# Crypt::OpenSSL::RSA
# Convert::BinHex
# IO::Compress::Zlib
# Getopt::Long
# Error
# Tie::Cache
# Crypt::DES
# Test::Simple
# IO::Compress::Base
# Net::CIDR::Lite
# Net::IMAP::Simple
# Test::Harness
# Mail::SPF::Query
# Digest::Nilsimsa
# Digest::HMAC
# ExtUtils::Constant
# Geography::Countries
#
# New dependencies:
# TOML::Tiny
# */

# /*
# Install missing Perl dependencies from CPAN
# */
cpanm Mail::IMAPClient
cpanm Mail::POP3Client
cpanm RRDTool::OO
cpanm IPC::Shareable
cpanm IO::Interactive

rm -rf ~/.cpan/build
