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
package FileIO::NDX;
use strict;
use warnings;


our $VERSION = 1.0;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(readNdx printNdxGroups selectGroupIds updateNdxData writeNdx);


sub readNdx {
    my $ndxFile = shift;
    my @ndxData;
    my $groupId = -1;
    
    my $tmpAtomList = '';

    print "  ---------------------------------\n  Read NDX file \"$ndxFile\"...\r";
    print "\n" if $main::verbose;
    open(NDXFILE, "<$ndxFile") || die "ERROR: Cannot open NDX file \"$ndxFile\": $!\n";
    while (<NDXFILE>) {
        if ($_ =~ /^\s*((\d+\s+)+)/) {
            my @tmpArray = split(/\s+/, $1);
            push(@{$ndxData[$groupId]{'atoms'}}, @tmpArray) if $groupId >= 0;
        }
        elsif ($_ =~ /^\s*\[\s*(.+?)\s*\]\s*$/) {
            $ndxData[++$groupId]{'groupName'} = $1;
            @{$ndxData[$groupId]{'atoms'}} = ();
            print "    Found " . ($groupId+1) . " groups\r" if $main::verbose;
        }
    }
    print "\n" if $main::verbose;
    close NDXFILE;
    print "  Read NDX file \"$ndxFile\": Finished\n  ---------------------------------\n\n";

    return if $groupId < 0;
    return @ndxData;
}



sub printNdxGroups {
    for (my $i=0; $i<@_; $i++) {
        next unless $_[$i]{'groupName'};
        printf("%3d %-20s: %5d atoms\n", $i, $_[$i]{'groupName'}, scalar(@{$_[$i]{'atoms'}}));
    }
}



sub selectGroupIds {
    my $ndxDataRef      = shift;
    my $groupNameText   = shift;
    my $nGroups         = shift;
    my @selectGroupIds;

    $nGroups = 10000 unless $nGroups; # Set the limit of selectable groups to 10000.

    print "\n  Select a group for $groupNameText: > ";

    chomp(my $groupId = <STDIN>);
    while (!scalar(@selectGroupIds) || $groupId ne 'q') {
        if ($groupId =~ /^\s*(\d+)\s*$/ && $$ndxDataRef[$1]{'groupName'}) {
            push(@selectGroupIds, $1);
            print "    Added group $1.\n";
            return @selectGroupIds if scalar(@selectGroupIds) == $nGroups;
            print "  Do you want to select another group? (\'q\' for quit) > ";
        }
        else {
            print "    Invalid group...\n  Please try to select a group for $groupNameText again (\'q\' for quit): > ";
        }
        chomp($groupId = <STDIN>);
    }
    return @selectGroupIds;
}



sub updateNdxData {
    my $ndxDataRef     = shift;
    my $renumMatrixRef = shift;
    my @newNdxData;

    for (my $groupId=0; $groupId<@{$ndxDataRef}; $groupId++) {
        $newNdxData[$groupId]{'groupName'} = $$ndxDataRef[$groupId]{'groupName'};
    }

    my @atomNdxGroups = getAtomNdxGroups($ndxDataRef);
    for (my $i=0; $i<@atomNdxGroups; $i++) {
        if ($$renumMatrixRef[$i]) {
            foreach (@{$atomNdxGroups[$i]}) {
                push(@{$newNdxData[$_]{'atoms'}}, $$renumMatrixRef[$i]);
            }
        }
    }
    return @newNdxData;
}



sub getAtomNdxGroups {
    my $ndxDataRef = shift;
    my @atomNdxGroups;

    for (my $groupId=0; $groupId<@{$ndxDataRef}; $groupId++) {
        foreach (@{$$ndxDataRef[$groupId]{'atoms'}}) {
            push(@{$atomNdxGroups[$_]}, $groupId);
        }
    }
    return @atomNdxGroups;
}



sub writeNdx {
    my $ndxFile    = shift;
    my $ndxDataRef = shift;

    open(NDXFILE, ">$ndxFile") or die "ERROR: Cannot open output NDX file ($ndxFile): $!\n";
    for (my $groupId=0; $groupId<@{$ndxDataRef}; $groupId++) {
        printf(NDXFILE "[ %s ]", $$ndxDataRef[$groupId]{'groupName'});
        next unless $$ndxDataRef[$groupId]{'atoms'};

        for (my $i=0; $i<@{$$ndxDataRef[$groupId]{'atoms'}}; $i++) {
            $i % 15 ? print NDXFILE " " : print NDXFILE "\n";
            printf(NDXFILE "%4d", $$ndxDataRef[$groupId]{'atoms'}[$i]);
        }
        print NDXFILE "\n";
        print NDXFILE "\n" unless @{$$ndxDataRef[$groupId]{'atoms'}};
    }
    close NDXFILE;
}

1;
