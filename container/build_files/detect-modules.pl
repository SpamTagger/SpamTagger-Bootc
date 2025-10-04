#!/usr/bin/env perl
#
#   SpamTagger Plus - Open Source Spam Filtering
#   Copyright (C) 2025 John Mertz <git@john.me.tz>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use v5.40;
use warnings;
use utf8;

use Cwd qw( abs_path );
use Symbol 'gensym';

my $start = shift || '/usr/spamtagger';
our %modules = ();
our %provided = ();

die "Path '$start' does not exist\n" unless (-d $start);
$start = abs_path($start) unless ($start =~ m/^\//);

sub check_dir ($path) {
  my $dir;
  opendir($dir, $path);
  while (my $new_path = readdir($dir)) {
    next if ($new_path =~ /^\./);
    if (-f "$path/$new_path" && "$path/$new_path" =~ /\.p(l|m)$/) {
      open(my $fh, "<", "$path/$new_path");
      while (my $line = <$fh>) {
        next if ($line =~ /^#/);
        next if ($line =~ /^\s*use\s+v5\.\d\d/);
        $modules{$1} = 1 if ($line =~ /^\s*(?:use|require)\s+([\w:]+)/);
        $provided{$1} = 1 if ($line =~ /^\s*package\s+([\w:]+)\s*;/);
      }
    }
    check_dir($path."/".$new_path) if (-d $path.'/'.$new_path);
  }
  close($dir);
  return;
}

check_dir($start);

delete($modules{$_}) foreach keys(%provided);
print "EXTRA_MODULES=".join("  ", (sort(keys(%modules))))."\n";
