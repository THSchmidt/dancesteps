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
package FileIO::IFP;
use strict;
use warnings;


our $VERSION = 1.0;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(readIfp writeIfp renumAtoms);



sub readIfp {
    my $ifpFile = shift;
    my %ifpData;

    my $sectionId = 0;
    my @sectionData;

    print "  ---------------------------------\n  Read IFP file \"$ifpFile\"...\r";
    print "\n" if $main::verbose;


    open(IFPFILE, "<$ifpFile") || die "ERROR: Cannot open IFP file \"$ifpFile\": $!\n";
    while (<IFPFILE>) {
        chomp($_);
        push(@{$sectionData[$sectionId]}, $_);
        $sectionId++ if $_ =~ /^\s*END\s*$/;
        print "    Found IFP sections:  $sectionId\r" if $main::verbose;    
    }
    close(IFPFILE);

    print "\n" if $main::verbose;

    ### Run through the sections ###############################################
    foreach (@sectionData) {
        my $sectionName = shift(@{$_}); # Extract and remove the element (first line) of each section (section name).
        pop(@{$_}); # Remove also the last element (last line) of each section ('END' line).
#        print $sectionName . "\n";

        if ($sectionName eq 'TITLE') {
            
        }
        elsif ($sectionName eq 'FORCEFIELD') {
            
        }
        elsif ($sectionName eq 'MAKETOPVERSION') {
            
        }
        elsif ($sectionName eq 'MASSATOMTYPECODE') {
            
        }
        elsif ($sectionName eq 'BONDSTRETCHTYPECODE') {
            
        }
        elsif ($sectionName eq 'BONDANGLEBENDTYPECODE') {
            
        }
        elsif ($sectionName eq 'IMPDIHEDRALTYPECODE') {
            
        }
        elsif ($sectionName eq 'TORSDIHEDRALTYPECODE') {
            
        }
        elsif ($sectionName eq 'SINGLEATOMLJPAIR') {
            $ifpData{'SINGLEATOMLJPAIR'} = readSec_SINGLEATOMLJPAIR($_);
        }
        elsif ($sectionName eq 'MIXEDATOMLJPAIR') {
            
        }
        elsif ($sectionName eq 'SPECATOMLJPAIR') {
            
        }
        ########################################################################

        
    }
    ############################################################################


    print "\n" if $main::verbose;
    print "  Read IFP file \"$ifpFile\": Finished\n  ---------------------------------\n\n";

    return %ifpData;
}



sub readSec_SINGLEATOMLJPAIR {
    my $sectionDataRef = shift;

    my @data;
    my $currAtomId;

    foreach (@{$sectionDataRef}) {
#        print $_ . "\n";
        if ($_ =~ /^\s*(\d+)\s+([,\+\-a-zA-Z0-9]+)\s+([-+]?\d*\.?\d+([eE][-+]?\d+)?)\s+([-+]?\d*\.?\d+([eE][-+]?\d+)?)\s+([-+]?\d*\.?\d+([eE][-+]?\d+)?)\s+([-+]?\d*\.?\d+([eE][-+]?\d+)?)\s*$/) {
            $currAtomId = $1 - 1;
            $data[$currAtomId]{'atomType'}  = $2;
            $data[$currAtomId]{'sqrtC6'}    = $3;
            $data[$currAtomId]{'sqrtC12_1'} = $5;
            $data[$currAtomId]{'sqrtC12_2'} = $7;
            $data[$currAtomId]{'sqrtC12_3'} = $9;
#            print $data[$currAtomId]{'atomType'} . "  " . $data[$currAtomId]{'sqrtC6'} . " $currAtomId\n";
        }
        elsif (defined $currAtomId && $_ =~ /^\s*([-+]?\d*\.?\d+([eE][-+]?\d+)?)\s+([-+]?\d*\.?\d+([eE][-+]?\d+)?)\s*$/) {
            $data[$currAtomId]{'lj14pairCS6'}  = $1;
            $data[$currAtomId]{'lj14pairCS12'} = $3;
        }
        elsif (defined $currAtomId && $_ =~ /^((\s+[123]){1,20})\s*$/) {
            $data[$currAtomId]{'matrixLine'} .= $1;
        }
#        elsif (defined $currAtomId) {
#            print $data[$currAtomId]{'matrixLine'} . "\n" if $data[$currAtomId]{'matrixLine'};
#        }
    }
    
    return \@data;
}



sub readSections {
    my $fileHandle = shift;
    my $ifpDataRef = shift;

    $$ifpDataRef{'title'}  = <$fileHandle>;
    $$ifpDataRef{'title'}  =~ s/(^\s*)|(\s*$)//g;
    $$ifpDataRef{'nAtoms'} = <$fileHandle>;
    $$ifpDataRef{'nAtoms'} =~ s/\s//g;

    print "\n    Number of atoms: " . $$ifpDataRef{'nAtoms'} . "\n" if $main::verbose;
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



sub readHeader {
    my $fileHandle = shift;
    my $ifpDataRef = shift;

    $$ifpDataRef{'title'}  = <$fileHandle>;
    $$ifpDataRef{'title'}  =~ s/(^\s*)|(\s*$)//g;
    $$ifpDataRef{'nAtoms'} = <$fileHandle>;
    $$ifpDataRef{'nAtoms'} =~ s/\s//g;

    print "\n    Number of atoms: " . $$ifpDataRef{'nAtoms'} . "\n" if $main::verbose;
}



sub readFooter {
    my $fileHandle = shift;
    my $ifpDataRef = shift;

    $$ifpDataRef{'footline'} = <$fileHandle>;
    $$ifpDataRef{'footline'} =~ s/(^\s*)|(\s*$)//g;
    if ($$ifpDataRef{'footline'} =~ /([-+]?\d*\.?\d+([eE][-+]?\d+)?)\s+([-+]?\d*\.?\d+([eE][-+]?\d+)?)\s+([-+]?\d*\.?\d+([eE][-+]?\d+)?)/) {
        $$ifpDataRef{'box'}{'cooX'} = $1;
        $$ifpDataRef{'box'}{'cooY'} = $3;
        $$ifpDataRef{'box'}{'cooZ'} = $5;

        print "\n    Boxsize: x=$1, y=$3, z=$5\n" if $main::verbose;
    }
}



sub readCoords {
    my $fileHandle = shift;
    my $ifpDataRef = shift;
    my $atomId     = 0;
    my $uResId     = 0; # The unique residue ID.
    my $lastResId  = 0;

    while (<$fileHandle>) {
        chomp($_);
        unless ($_ =~ /^\s*$/) {
            $$ifpDataRef{'atoms'}[++$atomId] = getAtomdata($_);
            $uResId++ unless $lastResId == $$ifpDataRef{'atoms'}[$atomId]{'resId'};
            $$ifpDataRef{'atoms'}[$atomId]{'uResId'} = $uResId;
            $lastResId = $$ifpDataRef{'atoms'}[$atomId]{'resId'};
        }
        print "    Read atom data:  $atomId\r" if $main::verbose;
        return 1 if ($atomId == $$ifpDataRef{'nAtoms'});
    }
    return 0; # If file ends before all atoms were count.
}



sub getAtomdata {
    my $atomStr = shift;
    my $strLen  = length($atomStr);
    my %atomData;

    $atomData{'resId'}    = checkSubstr($atomStr, $strLen,  0, 5);
    $atomData{'resName'}  = checkSubstr($atomStr, $strLen,  5, 5);
    $atomData{'atomName'} = checkSubstr($atomStr, $strLen, 10, 5);
    $atomData{'serial'}   = checkSubstr($atomStr, $strLen, 15, 5);
    $atomData{'cooX'}     = checkSubstr($atomStr, $strLen, 20, 8);
    $atomData{'cooY'}     = checkSubstr($atomStr, $strLen, 28, 8);
    $atomData{'cooZ'}     = checkSubstr($atomStr, $strLen, 36, 8);
    $atomData{'velX'}     = checkSubstr($atomStr, $strLen, 44, 8);
    $atomData{'velY'}     = checkSubstr($atomStr, $strLen, 52, 8);
    $atomData{'velZ'}     = checkSubstr($atomStr, $strLen, 60, 8);

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



sub writeIfp {
    my $ifpFile    = shift;
    my $ifpDataRef = shift;

    $ifpFile .= ".ifp" unless $ifpFile =~ /\.ifp$/;

    open(IFPFILE, ">$ifpFile") || die "ERROR: Cannot open output IFP file ($ifpFile): $!\n";
    writeHeader(\*IFPFILE, $ifpDataRef);
    writeCoords(\*IFPFILE, $ifpDataRef);
    writeFooter(\*IFPFILE, $ifpDataRef);
    close(IFPFILE);
}



sub writeHeader {
    my $fileHandle = shift;
    my $ifpDataRef = shift;

    print $fileHandle $$ifpDataRef{'title'} . "\n";
    print $fileHandle $$ifpDataRef{'nAtoms'} . "\n";
}



sub writeCoords {
    my $fileHandle = shift;
    my $ifpDataRef = shift;

    foreach (@{$$ifpDataRef{'atoms'}}) {
        next unless $$_{'uResId'};
        printf($fileHandle "%5d%-5s%5s%5d%8.3f%8.3f%8.3f\n",
            ($$_{'uResId'}%100000), $$_{'resName'}, $$_{'atomName'}, ($$_{'serial'}%100000), $$_{'cooX'}, $$_{'cooY'}, $$_{'cooZ'});
    }
}



sub writeFooter {
    my $fileHandle = shift;
    my $ifpDataRef = shift;

    printf($fileHandle "  %8.3f  %8.3f  %8.3f\n", $$ifpDataRef{'box'}{'cooX'}, $$ifpDataRef{'box'}{'cooY'}, $$ifpDataRef{'box'}{'cooZ'});
}

1;
