#!/usr/bin/perl -w

use strict;

use Cwd;

my $workDir = cwd;
$workDir =~ s/bit\/schmidt/schmidt/;
$workDir =~ s/media\/CSBBackup/home\/schmidt/;
my $remotePath = "marvin:$workDir";
#my $remotePath = "marvin:/home/schmidt/models/membrane/pope_tieleman/05a_md_100ns/runB/";

mkdir("results");
chdir("results");


printHelp() unless $ARGV[0];
printHelp() unless ($ARGV[0] eq 'go' || $ARGV[0] eq 'all');

system("scp $remotePath/* .") if $ARGV[0] eq 'all';
system("scp $remotePath/*.xtc .") if $ARGV[0] eq 'go';
system("rm unwrapped.xtc") if (-e 'unwrapped.xtc');
system("echo 0 | trjconv -f *.xtc -o unwrapped.xtc -s *.tpr -pbc whole");
# system("vmd -e unwrapped.state.vmd");

exit;


sub printHelp {
    print $remotePath . "\n";
    exit;
}

