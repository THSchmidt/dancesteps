# Copyright 2012 Thomas H. Schmidt
#
# This file is part of DanceSteps.
#
# DanceSteps is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# any later version.
#
# DanceSteps is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with DanceSteps; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

require Exporter;
package FileIO::Basic;
use File::Copy;
use strict;

our $VERSION = 1.0;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(backupFile);



sub backupFile {
    my $file    = shift;

    my $tmpDir  = './';
    my $tmpFile = $file;

    ($tmpDir, $tmpFile) = ($1, $2) if ($file =~ /^(.*\/)([^\/]+)$/);

    my $backupFile = "#$tmpFile#";

    if (-e $tmpDir . $backupFile) {
        my $counter = 1;
        while (-e $tmpDir . $backupFile) {
            $backupFile =~ s/(\.\d+)?\#$/\.$counter#/;
            $counter++;
        }
    }
    File::Copy::copy($file, $tmpDir . $backupFile) || die "ERROR: Cannot backup file  \"$file\" to \"$tmpDir$backupFile\": $!\n";
    print "\nBack Off! I just backed up $file to $tmpDir$backupFile\n";
    return $tmpDir . $backupFile;
}

1;
