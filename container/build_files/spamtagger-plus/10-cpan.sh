# /*
#shellcheck disable=SC2174,SC2114
# */

set ${CI:+-x} -euo pipefail

setterm --foreground green
echo "####################################"
echo "# Generating module list for CPAN..."
echo "####################################"
setterm --foreground default

cat <<EOF | tr "\n" " " >/tmp/staticperlrc
EXTRA_MODULES=Authen::Radius
Authen::Radius
Data::Validate::IP
Date::Calc
DateTime
DBD::MariaDB
DBD::SQLite
DBI
Devel::Size
Digest::HMAC
Digest::SHA
Dumpvalue
Env
ExtUtils::MakeMaker
File::Touch
FindBin
IO::Interactive
IPC::Shareable
IPC::Run
IPC::Run3
LDAP
Log::Log4perl
Mail::DKIM
Mail::IMAPClient
Mail::POP3Client
Mail::SPF
Mail::tools
Math::Int128
Module::Load::Conditional
Net::CIDR
Net::CIDR::Lite
Net::DNS
Net::DNS::Resolver
Net::HTTP
Net::IP
Net::SNMP
Net::SMTP::SSL
LWP::Protocol::https
PerlIO::gzip
Proc::ProcessTable
Regexp::Common
RRDTool::OO
Safe
SNMP_Session
String::ShellQuote
Sys::Hostname
TermReadKey
threads::shared
Test2::Suite
Time::Piece
TOML::Tiny
URI
EOF
