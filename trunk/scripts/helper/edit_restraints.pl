#!/usr/bin/perl -w

use strict;

my $inFile  = shift;
my $valFrom = shift;
my $valTo   = shift;
my $outFile = shift;

$outFile = $inFile unless ($outFile);

my @output;

open(INFILE, "<$inFile") or die "ERROR: Cannot open file \"$inFile\": $!\n";
while(<INFILE>) {
    if ($_ =~ /^(\s*\d+\s+\d+\s+)$valFrom\s+$valFrom\s+$valFrom(\s*)$/) {
        $_ = $1 . $valTo . "      " . $valTo . "      " . $valTo . $2;
    }
    push(@output, $_)
}
close(INFILE);


open(OUTFILE, ">$outFile") or die "ERROR: Cannot open file \"$outFile\": $!\n";
print OUTFILE @output;
close(OUTFILE);

