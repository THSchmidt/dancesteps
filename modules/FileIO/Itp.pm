# Copyright 2014 Thomas H. Schmidt
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
package FileIO::ITP;
use strict;
use warnings;


our $VERSION = 1.0;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(readItp resname2Moltype);


sub readItp {
    my $itpFile = shift;
    my %itpData;

    print "  ---------------------------------\n  Read ITP file \"$itpFile\"...\r";
    open(ITPFILE, "<$itpFile") || die "ERROR: Cannot open ITP file \"$itpFile\": $!\n";
    readData(\*ITPFILE, \%itpData);
    close(ITPFILE);
    print "  Read ITP file \"$itpFile\": Finished\n  ---------------------------------\n\n";

    return %itpData;
}



sub readData {
    my $fileHandle = shift;
    my $itpDataRef = shift;
    my $atomsSwitch = 0;

    while (<$fileHandle>) {
        chomp($_);

        $atomsSwitch = 0 if $atomsSwitch && $_ =~ /^\s*\[.+\]/;
        $$itpDataRef{'atoms'} = getAtomdata($_) if $atomsSwitch;
        $atomsSwitch = 1 if $_ =~ /^\s*\[ atoms \]/;
#        $$pdbDataRef{'atoms'}[++$atomId] = getAtomdata($_) if ($_ =~ /^ATOM\s+$/);
#        print "    Read atom data:  $atomId\r" if $main::verbose;
    }
#    printf("\n    Read files for inclusion: %d\n", scalar @{$$topDataRef{'include'}}) if $main::verbose;
#    printf("    Number of molecule types: %d\n", scalar keys %{$$topDataRef{'molecules'}}) if $main::verbose;
}



sub getAtomdata {
    my $atomStr = shift;
    my %atomData;

    if ($atomStr =~ /^\s*(\d+)\s+(\w+)\s+(\d+)\s+(\w{3,4})/) {
        print $4 . " ";
    }

    return \%atomData;
}



sub resname2Moltype {
    my $itpFile = shift;
    my $resName = shift;
    my $molType;
    my $switch = "";

    open(ITPFILE, "<$itpFile") || warn "ERROR: Cannot open ITP file \"$itpFile\": $!\n";
    while (<ITPFILE>) {
        chomp($_);

        if ($switch eq "atoms" && $_ =~ /^\s*(\d+)\s+(\w+)\s+(\d+)\s+(\w{3,4})/) {
            return $molType if $4 eq $resName;
        }
        elsif ($switch eq "moleculetype" && $_ =~ /^\s*(\w+)\s+(\d)/) {
            $molType = $1;
        }
        $switch = $1 if $_ =~ /^\s*\[\s*(\w+)\s*\]/;
    }
    close(ITPFILE);

    return 0;
}

1;
