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


package FileIO::XVG;

use strict;
use warnings;

use base 'Exporter';

our $VERSION = '1.0';

our @EXPORT    = qw(readXvg);

# This file was created Thu Mar 21 19:59:47 2013
# by the following command:
# g_rms -s average.08.pdb -f atomselect.xtc -o rmsd.xvg -fit rot+trans 
#
# g_rms is part of G R O M A C S:
#
# Getting the Right Output Means no Artefacts in Calculating Stuff
#
#@    title "RMSD"
#@    xaxis  label "Time (ps)"
#@    yaxis  label "RMSD (nm)"
#@TYPE xy
#@ subtitle "System after lsq fit to System"
#20000.0000000    0.5213100
#20500.0000000    0.6626570
#21000.0019531    0.5073701
#21500.0019531    0.5244528
#22000.0019531    0.4525010
#22500.0019531    0.4764614
#23000.0019531    0.4289002
#23500.0019531    0.4599570


#@    title "Coordinate"
#@    xaxis  label "Time (ps)"
#@    yaxis  label "Coordinate (nm)"
#@TYPE xy
#@ view 0.15, 0.15, 0.75, 0.85
#@ legend on
#@ legend box on
#@ legend loctype view
#@ legend 0.78, 0.8
#@ legend length 2
#@ s0 legend "atom 74 Z"
#@ s1 legend "atom 126 Z"
#@ s2 legend "atom 178 Z"
#@ s3 legend "atom 230 Z"
#@ s4 legend "atom 282 Z"
#@ s5 legend "atom 334 Z"


sub readXvg {
    my $xvgFile = shift;
    my %xvgData;

    print "  ---------------------------------\n  Read XVG file \"$xvgFile\"...\r";
    open(XVGFILE, "<$xvgFile") || die "ERROR: Cannot open XVG file \"$xvgFile\": $!\n";

    while (<XVGFILE>) {
        chomp($_);
        if ($_ =~ /^\s*#/) {
            push(@{$xvgData{'comment'}}, $_);
        }
        elsif ($_ =~ /^\s*@/) {
            getXvgFormatData($_, \%{$xvgData{'format'}});
        }
        elsif ($_ =~ /^\s*((([-+]?\d*\.?\d+([eE][-+]?\d+)?)(\s+|$))+)/) {
            my @tmpArray = split(/\s+/, $1);
#            print $tmpArray[0] . " -- " . $tmpArray[-1] . "\n";
            if ($xvgData{'format'}{'legendValues'} && scalar(@tmpArray) == scalar(@{$xvgData{'format'}{'legendValues'}})) {
                print "Found " . scalar(@tmpArray) . " values (" . scalar(@{$xvgData{'format'}{'legendValues'}}) . " columns)\n";
                for (my $i=0; $i<@tmpArray; $i++) {
                    push(@{ $xvgData{'values'}{ $xvgData{'format'}{'legendValues'}[$i] } }, $tmpArray[$i]);
                }
            }
            else {
                push(@{$xvgData{'values'}}, \@tmpArray);
            }
        }
    }

    close(XVGFILE);
    print "  Read XVG file \"$xvgFile\": Finished\n  ---------------------------------\n\n";

    return %xvgData;
}



sub getXvgFormatData {
    my $formatStr        = shift;
    my $xvgDataFormatRef = shift;

    my %searchRegex = ('title\s+\"(.+?)\"'           => 'title',
                       'xaxis\s+label\s+\"(.+?)\"'   => 'xaxisLabel',
                       'yaxis\s+label\s+\"(.+?)\"'   => 'yaxisLabel',
                       'legend\s+(on|off)'           => 'legend',
                       'legend\s+box\s+(on|off)'     => 'legendBox',
                       'legend\s+loctype\s+(.+)'     => 'legendLoctype',
                       'legend\s+(([-+]?\d*\.?\d+([eE][-+]?\d+)?)\s*,\s*([-+]?\d*\.?\d+([eE][-+]?\d+)?))' => 'legendPosition',
                       'legend\s+length\s+(\d+?)'    => 'legendLength',
                       's(\d+)\s+legend\s+\"(.+?)\"' => 'legendValues');

    foreach my $key (keys %searchRegex) {
        if ($formatStr =~ /^\s*@\s*$key/) {
            if ($searchRegex{$key} eq 'legendValues') { # Special handling for legend items: value -> column.
                ${$xvgDataFormatRef}{'legendValues'}[$1] = $2;
            }
            else {
                $$xvgDataFormatRef{$searchRegex{$key}} = $2 ? $2 : $1;
            }
        }
    }
}


1;
