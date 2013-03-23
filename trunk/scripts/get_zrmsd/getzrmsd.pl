#!/usr/bin/perl -w

use strict;


### Load Packages & Modules ####################################################
use strict;
#use Cwd;
#use Fcntl;
use IO::Handle;
use Math::Trig;
use FindBin qw($RealBin); # Absolute path to THIS script.
use lib $RealBin . "/modules";
autoflush STDOUT 1; # For direct output (IO:Handle).

use FileIO::gro;
#use protein;
################################################################################



### Default Parameters #########################################################
our $verbose      = 0;                  # Be loud and noisy (and global).

my $inFile1  = 'in1.gro';
my $inFile2  = 'in2.gro';
my $outFile1 = 'out1.gro';
my $outFile2 = 'out2.gro';
my $outRmsd  = 'rmsd.xvg';
################################################################################



### Internal parameters ########################################################
my %inFile1Data;         # Filled by "GROFiles::readGro(<GROFILE>)".
my %inFile2Data;         # Filled by "GROFiles::readGro(<GROFILE>)".
################################################################################



### Commandline-Parameters #####################################################
my %cmdLParam = ('f1'         => \$inFile1,
                 'f2'         => \$inFile2,
                 'o1'         => \$outFile1,
                 'o2'         => \$outFile2,
                 'ormsd'      => \$outRmsd,
                 'v=f'        => \$verbose,
                 'NOPARAM'    => \&printHelp,
                 'UNKNOWN'    => \&printHelp,
                 'help=f'     => \&printHelp,
                 '?=f'        => \&printHelp,
                 'h=f'        => \&printHelp);
cmdlineParser(\%cmdLParam);
################################################################################



### Read the GRO files #########################################################
%inFile1Data = GRO::readGro($inFile1); # Read membrane input GRO file.
%inFile2Data = GRO::readGro($inFile2); # Read membrane input GRO file.

for (my $i=1; $i<@{$inFile1Data{'atoms'}}; $i++) {
    $inFile1Data{'atoms'}[$i]{'cooX'} = 0;
    $inFile1Data{'atoms'}[$i]{'cooY'} = 0;
}

for (my $i=1; $i<@{$inFile2Data{'atoms'}}; $i++) {
    $inFile2Data{'atoms'}[$i]{'cooX'} = 0;
    $inFile2Data{'atoms'}[$i]{'cooY'} = 0;
}

GRO::writeGro($outFile1, \%inFile1Data);
GRO::writeGro($outFile2, \%inFile2Data);

`echo 3 | g_rms -s $outFile1 -f $outFile2 -fit none -o $outRmsd`;
################################################################################






sub printHelp {
    print "
###########################################################################
                                 LAMBADA
                     Written by Christian Kandt, (c) 2012

   Kandt C, Ash WL, Tieleman DP (2007): Setting up and running molecular
       dynamics simulations of membrane proteins. Methods 41:475-488

                     http://www.csb.bit.uni-bonn.de
###########################################################################

INFLATEGRO reads the coordinates of a bilayer and inflates them in XY
directions using a common SCALING FACTOR. To identify the lipids for
inflating a group in an NDX file must be defined.

Everything else will be centered in the XY plane of the new simulation box.

A DISTANCE CUTOFF in nm can be defined: Only lipids with a P - CA distance
exceeding that cutoff will be written. It is currently assumed that you're
actually dealing with phospholipids. However, this can be easily changed in
the code.

AREA PER LIPID is estimated by caculating the area per protein first.
This is done using a grid-based approach. A GRID SIZE of 5 A (0.5 nm) was
found to give good results. Output is written as a 3-collumned ASCII file
holding three area per lipid values: total, upper leaflet & lower leaflet.

DOUGHNUT mode is a recent extension to INFLATEGRO that might be useful when
dealing with several peptides at once or multimeric proteins of somewhat
torrodial (doughnut-like!) shape featuring central lipid-filled cavities.
It is activated via the >doughnut< flag. If that is set, the protein is no
longer centered in the XY plane. Instead, inflating now also applies to the
protein coordinates which are translated laterally in a subunit-dependent
manner. Protein subunits are defined in an given ndx file.

USAGE: lambada --igro INPUTGROFILE --ogro OUTPUTGROFILE
  --igro             Input GRO file (default: \"\").
  --ogro             Output GRO file (default: \"\").
  -g                 Grid size to detect the area of the protein [nm]  (default: \"\").
  -v                 Be loud and noisy and communicative and meaningful and profound. Seriously!
  -h, -? or --help   Put out this help.\n\n";
    exit;
}



sub cmdlineParser {
    my $paramsRef = shift;

    my %knownParam;
    my @unknownParam;

    for (my $argID=0; $argID<@ARGV; $argID++) {
        my $cmdlineName = $ARGV[$argID];
        $knownParam{$ARGV[$argID]} = 0;

        foreach my $paramKey (keys %{$paramsRef}) {
            my $paramName = $paramKey;
            my $paramType = 0;
            my $paramIni  = "--";
            my $isArray   = 0;

            if ($paramKey =~ /^(.+?)=([\@f])$/) {
                $paramName = $1;
                $paramType = $2;
            }

            $paramIni = "-" if (length($paramName) == 1);

            if ($paramType eq "@") {
                $isArray = 1;
            }
            elsif ($paramType eq "f") {
                if ($cmdlineName eq $paramIni.$paramName) {
                    if (ref(${$paramsRef}{$paramKey}) eq "SCALAR") {
                        ${${$paramsRef}{$paramKey}} = 1;
                        $knownParam{$cmdlineName} = 1;
                    }
                    elsif (ref(${$paramsRef}{$paramKey}) eq "CODE") {
                        &{${$paramsRef}{$paramKey}}();
                        $knownParam{$cmdlineName} = 1;
                    }
                }
                next;
            }

            if ($cmdlineName eq $paramIni.$paramName && not $isArray) {
                $argID++;
                next if($ARGV[$argID] =~ /^-/);

                ${${$paramsRef}{$paramKey}} = $ARGV[$argID];
                $knownParam{$cmdlineName} = 1;
            }
            elsif ($ARGV[$argID] eq $paramIni.$paramName && $isArray) {
                $knownParam{$cmdlineName} = 1;
                $argID++;

                my @tmpArray;
                while ($argID <= $#ARGV && not $ARGV[$argID] =~ /^--/ && not $ARGV[$argID] =~ /^-.$/) {
                    push (@tmpArray, $ARGV[$argID]);
                    $argID++;
                }
                @{${$paramsRef}{$paramKey}} = @tmpArray;
                $argID--;
            }
        }

        if (defined $knownParam{$cmdlineName} && $knownParam{$cmdlineName} == 0) {
            push(@unknownParam, $cmdlineName) if($cmdlineName =~ /^-/);
        }
    }


    ### Catch unknown parameters ###########################
    if (@unknownParam && ${$paramsRef}{"UNKNOWN"} && ref(${$paramsRef}{"UNKNOWN"}) eq "CODE") {
        print "WARNING: Unknown or non-set parameters detected:\n";
        for (@unknownParam) { print "        \"$_\"\n"; }
        &{${$paramsRef}{"UNKNOWN"}}();
    }
    elsif (@unknownParam) {
        print "ERROR: Unknown or non-set parameters detected:\n";
        for(@unknownParam) { print "       \"$_\"\n"; }
        exit;
    }
    ########################################################


    ### Catch no given parameters ##########################
    if (!@ARGV && ${$paramsRef}{"NOPARAM"} && ref(${$paramsRef}{"NOPARAM"}) eq "CODE") {
        print "WARNING: Parameters needed...\n";
        &{${$paramsRef}{"NOPARAM"}}();
    }
    ########################################################
}

