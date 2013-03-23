#!/usr/bin/perl -w

use strict;


my @areaA;
my @timeA;
my @areaB;
my @timeB;
my @areaAB;
my @timeAB;

my @tmpArray;



### Check input #########################################
printHelp() unless @ARGV == 4;
#########################################################



### Read files ##########################################
@tmpArray = readNaccess($ARGV[0]);
@timeA = @{$tmpArray[0]};
@areaA = @{$tmpArray[1]};

@tmpArray = readNaccess($ARGV[1]);
@timeB = @{$tmpArray[0]};
@areaB = @{$tmpArray[1]};

@tmpArray = readNaccess($ARGV[2]);
@timeAB = @{$tmpArray[0]};
@areaAB = @{$tmpArray[1]};
#########################################################



### Write output ########################################
print "Writing output to $ARGV[3]...\n";
open(OUTPUT, ">$ARGV[3]") or die "ERROR: Cannot open file \"$ARGV[3]\": $!\n";
for (my $i=0; $i<@areaAB; $i++) {
    my $interface = ($areaA[$i] + $areaB[$i]) - $areaAB[$i];
    print OUTPUT "$timeAB[$i]        $interface\n";
}
close OUTPUT;
#########################################################



#########################################################
### Subroutines #########################################
#########################################################
sub readNaccess {
    my $fileName = shift;
    my @area;
    my @time;

    print "Reading area: $fileName...\n";
    open(AREA, "<$fileName") or die "ERROR: Cannot open file \"$fileName\": $!\n";
    while (<AREA>) {
        if (/^TOTAL\s+([\*0-9\.-]+)\s+[\*0-9\.-]+\s+[\*0-9\.-]+\s+[\*0-9\.-]+\s+[\*0-9\.-]+\s+([0-9\.-]+)/) {
            push(@time, $2);
            push(@area, $1);

            print "$1      $2\n";
        }
    }
    close(AREA);

    return(\@time, \@area);
}



sub printHelp {
    print "\nEXTRACTAREA reads solvent accessible surface area data
produced by g_sas or naccess and calculates the buried surface area of a complex AB.

Usage:
EXTRACTAREA areaA areaB areaAB interfaceA-B.dat

;) ChK\n\n";
    exit;
}
#########################################################

