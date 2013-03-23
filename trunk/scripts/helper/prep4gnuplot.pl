#!/usr/bin/perl -w

use strict;

my $inFile = shift;
my $outFile = shift;

$outFile = $inFile unless ($outFile);

my @output;

open(INFILE, "<$inFile") or die "ERROR: Cannot open file \"$inFile\": $!\n";
while(<INFILE>) {
    $_ = "#$1" if ($_ =~ /^(\s*\@\s*.*\s*$)/);
    push(@output, $_);
}
close(INFILE);


open(OUTFILE, ">$outFile") or die "ERROR: Cannot open file \"$outFile\": $!\n";
print OUTFILE @output;
close(OUTFILE);

