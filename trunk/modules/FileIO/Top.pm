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
package FileIO::TOP;
use strict;
use warnings;


our $VERSION = 1.0;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(readTop writeTop);



sub readTop {
    my $topFile = shift;
    my %topData;

    my $molSwitch  = 0;

    print "  ---------------------------------\n  Read TOP file \"$topFile\"...\r";
    open(TOPFILE, "<$topFile") || die "ERROR: Cannot open TOP file \"$topFile\": $!\n";
    while (<TOPFILE>) {
        chomp($_);
        if ($_ =~ /^\s*\[\s*molecules\s*\]/) {
            $molSwitch = 1;
        }
        elsif ($molSwitch && $_ =~ /^\s*\[\s*.+\s*\]/) {
            $molSwitch = 0;
        }
        
        if ($molSwitch && $_ =~ /^\s*(\w+)\s+(\d+)\s*$/) {
#            my %tmpHash = ('molType' => $1);
            $topData{'molecules'}{$1} += $2;
        }
        else {
            push(@{$topData{'lines'}}, $_);
        }
    }
    close(TOPFILE);
    print "  Read TOP file \"$topFile\": Finished\n  ---------------------------------\n\n";

    return %topData;
}



sub writeTop {
    my $topFile    = shift;
    my $topDataRef = shift;

    open(TOPFILE, ">$topFile") || die "ERROR: Cannot open TOP file \"$topFile\": $!\n";
    foreach (@{$$topDataRef{'lines'}}) {
        print TOPFILE $_ . "\n";
    }

    print TOPFILE "\n[ molecules ]\n";
    foreach my $molType (keys %{$$topDataRef{'molecules'}}) {
        printf TOPFILE ("%-14s %6d\n", $molType, $$topDataRef{'molecules'}{$molType});
    }
    close(TOPFILE);
}

1;
