# Copyright 2013 Thomas H. Schmidt
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
package FileIO::PDB;
use strict;
use warnings;


our $VERSION = 1.0;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(readPdb writePdb renumAtoms);


sub readPdb {
    my $pdbFile = shift;
    my %pdbData;

    print "  ---------------------------------\n  Read PDB file \"$pdbFile\"...\r";
    open(PDBFILE, "<$pdbFile") || die "ERROR: Cannot open PDB file \"$pdbFile\": $!\n";
    readCoords(\*PDBFILE, \%pdbData);
    close(PDBFILE);
    print "  Read PDB file \"$pdbFile\": Finished\n  ---------------------------------\n\n";

    return %pdbData;
}



sub renumAtoms {
    my @renumAtoms;
    my $atomId = 0;
    foreach (@{$_[0]}) {
        next unless $$_{'uResId'};
        $renumAtoms[++$atomId] = $_;
    }
    return \@renumAtoms;
}



sub readCoords {
    my $fileHandle = shift;
    my $pdbDataRef = shift;
    my $atomId     = 0;
    my $uResId     = 0; # The unique residue ID.
    my $lastResId  = 0;

    print "\n" if $main::verbose;
    while (<$fileHandle>) {
        chomp($_);
        if ($_ =~ /^ATOM\s*/) {
            $$pdbDataRef{'atoms'}[++$atomId] = getAtomdata($_);
            $uResId++ unless $lastResId == $$pdbDataRef{'atoms'}[$atomId]{'resId'};
            $$pdbDataRef{'atoms'}[$atomId]{'uResId'} = $uResId;
            $lastResId = $$pdbDataRef{'atoms'}[$atomId]{'resId'};
        }
        print "    Read atom data:  $atomId\r" if $main::verbose;
    }
    print "\n" if $main::verbose;
    return 1; # If file ends before all atoms were counted.
}



sub getAtomdata {
    my $atomStr = shift;
    my $strLen  = length($atomStr);
    my %atomData;

    $atomData{'atomNum'}    = checkSubstr($atomStr, $strLen, 6, 5);
    $atomData{'atomName'}   = checkSubstr($atomStr, $strLen, 12, 4);
    $atomData{'altLoc'}     = checkSubstr($atomStr, $strLen, 16, 1);
    $atomData{'resName'}    = checkSubstr($atomStr, $strLen, 17, 3);
    $atomData{'chainID'}    = checkSubstr($atomStr, $strLen, 21, 1);
    $atomData{'resId'}      = checkSubstr($atomStr, $strLen, 22, 4);
    $atomData{'iCode'}      = checkSubstr($atomStr, $strLen, 26, 1);
    $atomData{'cooX'}       = checkSubstr($atomStr, $strLen, 30, 8);
    $atomData{'cooY'}       = checkSubstr($atomStr, $strLen, 38, 8);
    $atomData{'cooZ'}       = checkSubstr($atomStr, $strLen, 46, 8);
    $atomData{'occupancy'}  = checkSubstr($atomStr, $strLen, 54, 6);
    $atomData{'tempFactor'} = checkSubstr($atomStr, $strLen, 60, 6);
    $atomData{'element'}    = checkSubstr($atomStr, $strLen, 76, 2);
    $atomData{'charge'}     = checkSubstr($atomStr, $strLen, 78, 2);

    $atomData{'cooX'} /= 10;
    $atomData{'cooY'} /= 10;
    $atomData{'cooZ'} /= 10;

    return \%atomData;
}



sub checkSubstr {
    my $str       = shift;
    my $strLen    = shift;
    my $start     = shift;
    my $substrLen = shift;
    my $substr    = '';

    if ($strLen >= ($start+$substrLen)) {
        $substr = substr($str, $start, $substrLen);
        $substr =~ s/\s//g;
    }
    return $substr;
}



sub writePdb {
    my $pdbFile    = shift;
    my $pdbDataRef = shift;

    $pdbFile .= ".pdb" unless $pdbFile =~ /\.pdb$/;

    open(PDBFILE, ">$pdbFile") || die "ERROR: Cannot open output PDB file ($pdbFile): $!\n";
    writeCoords(\*PDBFILE, $pdbDataRef);
    close(PDBFILE);
}



sub writeCoords {
    my $fileHandle = shift;
    my $pdbDataRef = shift;

    my $atomId     = 1;

    my %defaultAtom = ("atomNum"    => 0,
                       "atomName"   => "X",
                       "altLoc"     => "",
                       "resName"    => "RES",
                       "chainId"    => 0,
                       "resId"      => 0,
                       "iCode"      => "",
                       "cooX"       => 0.0,
                       "cooY"       => 0.0,
                       "cooZ"       => 0.0,
                       "occupancy"  => 0.0,
                       "tempFactor" => 0.0,
                       "element"    => "X",
                       "charge"     => "0");

    foreach (@{$$pdbDataRef{'atoms'}}) {
        next unless $$_{'uResId'};

        ### Fill empty fields with standard parameters #########################
        foreach my $key (keys %defaultAtom) {
            $$_{$key} = $defaultAtom{$key} unless defined($$_{$key});
        }
        ########################################################################
        $$_{'element'} = substr($$_{'atomName'}, 0, 1) if $$_{'element'} eq 'X';

        printf($fileHandle "ATOM  %5d %4s%1s%4s%1s%4d%1s   %8.3f%8.3f%8.3f%6.2f%6s          %2s%2s\n",
            (($atomId++)%100000), $$_{'atomName'}, $$_{'altLoc'}, $$_{'resName'}, $$_{'chainId'}, ($$_{'resId'}%100000),  $$_{'iCode'}, ($$_{'cooX'}*10), ($$_{'cooY'}*10), ($$_{'cooZ'}*10), $$_{'occupancy'}, substr(sprintf("%6f", $$_{'tempFactor'}), 0, 6), $$_{'element'}, $$_{'charge'});
    }
}



1;
