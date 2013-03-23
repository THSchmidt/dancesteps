#!/usr/bin/perl -w

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


use strict;

my $pteFile = shift;
$pteFile = 'pte.csv' unless $pteFile;

my %elements;

getRelMasses(\%elements);
getVdwRadii(\%elements);

writeTable($pteFile, \%elements);



sub getRelMasses {
    my $elementsRef = shift;
    my $source      = 'http://physics.nist.gov/cgi-bin/Compositions/stand_alone.pl?ele=&ascii=ascii2&isotype=some';
    my $tempDir     = 'relMassesTemp/';

    my %isotopes;

#    mkdir($tempDir);
    chdir($tempDir);

#    system("wget \"$source\" -O relmasses.txt");
    open(RELMASSES, "<relmasses.txt") || die "ERROR: Cannot open file \"relmasses.txt\": $!\n";
    my @fileContent = <RELMASSES>;
    close(RELMASSES);

    map {$_ =~ s/\n$/;/g} @fileContent;
    my $str = join("", @fileContent);
    $str =~ s/<html>.*?<\/a>//g;
    $str =~ s/<a.*<\/html>//g;
    $str =~ s/;\s*;\s*;/;;/g;
    $str =~ s/\(|\)|\[|\]//g;
    my @array = split(/;;/, $str);


    foreach (@array) {
        if ($_ =~ /Atomic Number = (\d+);Atomic Symbol = (.+?);Mass Number = (\d+);Relative Atomic Mass = (\d+(\.\d+)?)#?;Isotopic Composition = ;Standard Atomic Weight = (\d+(\.\d+)?);Notes/) {
            my %tmpHash = ('number'   => $1,
                           'symbol'   => $2,
                           'massNum'  => $3,
                           'relMass'  => $4,
                           'stdWeight' => $6);
            push(@{$isotopes{$2}}, \%tmpHash);
        }
        elsif ($_ =~ /Atomic Number = (\d+);Atomic Symbol = (.+?);Mass Number = (\d+);Relative Atomic Mass = (\d+(\.\d+)?)#?;Isotopic Composition = (\d+(\.\d+)?)*;Standard Atomic Weight = (\d+(\.\d+)?);Notes/) {
            my %tmpHash = ('number'   => $1,
                           'symbol'   => $2,
                           'massNum'  => $3,
                           'relMass'  => $4,
                           'isoComp'  => $6,
                           'stdWeight' => $8);
            push(@{$isotopes{$2}}, \%tmpHash);
        }
        elsif ($_ =~ /Atomic Number = (\d+);Atomic Symbol = (.+?);Mass Number = (\d+);Relative Atomic Mass = ;Isotopic Composition = ;Standard Atomic Weight = (\d+(\.\d+)?);Notes/) {
            my %tmpHash = ('number'   => $1,
                           'symbol'   => $2,
                           'massNum'  => $3,
                           'relMass'  => $4,
                           'stdWeight' => $4);
            push(@{$isotopes{$2}}, \%tmpHash);
        }
        elsif ($_ =~ /Atomic Number = (\d+);Atomic Symbol = (.+?);Mass Number = (\d+);Relative Atomic Mass = ;Isotopic Composition = (\d+(\.\d+)?)*;Standard Atomic Weight = (\d+(\.\d+)?);Notes/) {
            my %tmpHash = ('number'   => $1,
                           'symbol'   => $2,
                           'massNum'  => $3,
                           'relMass'  => $6,
                           'isoComp'  => $4,
                           'stdWeight' => $6);
            push(@{$isotopes{$2}}, \%tmpHash);
        }
    }


    foreach my $symbol ( sort { $isotopes{$a}[0]{'number'} <=> $isotopes{$b}[0]{'number'} } keys %isotopes ) {
#        printf("%3d :: %3s (%d isotopes)\n", $isotopes{$symbol}[0]{'number'}, $symbol, scalar(@{$isotopes{$symbol}}));
#        next;
        for (my $isotope=0; $isotope<@{$isotopes{$symbol}}; $isotope++) {
            if (sprintf("%1.0f", $isotopes{$symbol}[$isotope]{'relMass'}) == sprintf("%1.0f", $isotopes{$symbol}[$isotope]{'stdWeight'})) {
#                print $isotopes{$symbol}[$isotope]{'relMass'} . " " . $isotopes{$symbol}[$isotope]{'stWeight'} . "\n" if $symbol eq 'Br';
                combineHashes(\%{$$elementsRef{$symbol}}, $isotopes{$symbol}[$isotope]);
            }
            elsif (scalar(@{$isotopes{$symbol}}) == 1) {
                combineHashes(\%{$$elementsRef{$symbol}}, $isotopes{$symbol}[$isotope]);
            }
            elsif ($isotopes{$symbol}[$isotope]{'isoComp'} && $isotopes{$symbol}[$isotope]{'isoComp'} > 0.5) {
                print $isotopes{$symbol}[$isotope]{'isoComp'} . " $symbol\n";
                combineHashes(\%{$$elementsRef{$symbol}}, $isotopes{$symbol}[$isotope]);
            }
            else {
#                print $isotopes{$symbol}[$isotope]{'relMass'} . " " . $isotopes{$symbol}[$isotope]{'stWeight'} . "\n" if $symbol eq 'Br';
                combineHashes(\%{$$elementsRef{ $symbol.$isotopes{$symbol}[$isotope]{'massNum'} }}, $isotopes{$symbol}[$isotope]);
            }
        }
    }

    chdir('..');
#    system("rm -r $tempDir");
}



sub combineHashes {
    my $hash1Ref = shift;
    my $hash2Ref = shift;

    foreach my $key2 (keys %{$hash2Ref}) {
        warn "WARNING: Element attribute \"$key2\" already exists. Will overwrite value...\n" if exists $$hash1Ref{$key2};
        $$hash1Ref{$key2} = $$hash2Ref{$key2};
    }
}



sub getVdwRadii {
    my $elementsRef = shift;

    my %vdwRadii = ('H'  => 0.110,
                    'He' => 0.140,
                    'Li' => 0.182,
                    'Be' => 0.153,
                    'B'  => 0.192,
                    'C'  => 0.170,
                    'N'  => 0.155,
                    'O'  => 0.152,
                    'F'  => 0.147,
                    'Ne' => 0.154,
                    'Na' => 0.227,
                    'Mg' => 0.173,
                    'Al' => 0.184,
                    'Si' => 0.210,
                    'P'  => 0.180,
                    'S'  => 0.180,
                    'Cl' => 0.175,
                    'Ar' => 0.188,
                    'K'  => 0.275,
                    'Ca' => 0.231,
                    'Ni' => 0.163,
                    'Cu' => 0.140,
                    'Zn' => 0.139,
                    'Ga' => 0.187,
                    'Ge' => 0.211,
                    'As' => 0.185,
                    'Se' => 0.190,
                    'Br' => 0.185,
                    'Kr' => 0.202,
                    'Rb' => 0.303,
                    'Sr' => 0.249,
                    'Pd' => 0.163,
                    'Ag' => 0.172,
                    'Cd' => 0.158,
                    'In' => 0.193,
                    'Sn' => 0.217,
                    'Sb' => 0.206,
                    'Te' => 0.206,
                    'I'  => 0.198,
                    'Xe' => 0.216,
                    'Cs' => 0.343,
                    'Ba' => 0.268,
                    'Pt' => 0.175,
                    'Au' => 0.166,
                    'Hg' => 0.155,
                    'Tl' => 0.196,
                    'Pb' => 0.202,
                    'Bi' => 0.207,
                    'Po' => 0.197,
                    'At' => 0.202,
                    'Rn' => 0.220,
                    'Fr' => 0.348,
                    'Ra' => 0.283,
                    'U'  => 0.186,
                    'CGA'=> 0.400);

    foreach my $symbol (keys %vdwRadii) {
        next unless $$elementsRef{$symbol};
        next unless defined $$elementsRef{$symbol}{'number'};
        warn "WARNING: Element attribute \"vdwRadius\" already exists. Will overwrite value...\n" if exists $$elementsRef{$symbol}{'vdwRadius'};
        $$elementsRef{$symbol}{'vdwRadius'} = $vdwRadii{$symbol};
    }

# Atomic van der Waals radii in nm.
#    1) R. Scott Rowland, Robin Taylor: Intermolecular Nonbonded Contact
#       Distances in Organic Crystal Structures: Comparison with Distances
#       Expected from van der Waals Radii. In: J. Phys. Chem. 1996, 100,
#       S. 7384–7391, doi:10.1021/jp953141+.
#    2) A. Bondi: van der Waals Volumes and Radii. In: J. Phys. Chem. 1964, 68,
#       S. 441-451, doi:10.1021/j100785a001.
#    3) Manjeera Mantina, Adam C. Chamberlin, Rosendo Valero, Christopher J.
#       Cramer, Donald G. Truhlar: Consistent van der Waals Radii for the Whole
#       Main Group. In: J. Phys. Chem. A. 2009, 113, S. 5806–5812,
#       doi:10.1021/jp8111556.
}



sub writeTable {
    my $pteCsvOut   = shift;
    my $elementsRef = shift;
    my %elements = %{$elementsRef};;

    my $firstLine = 1;

    open(PTECSV, ">$pteCsvOut") || die "ERROR: Cannot open file \"$pteCsvOut\": $!\n";
    foreach my $symbol ( sort { $elements{$a}{'number'} <=> $elements{$b}{'number'} } keys %elements ) {
        next unless $symbol;

        if ($firstLine) {
            printf PTECSV ("# symbol;number;relMass;stdWeight;vdwRadius\n");
            $firstLine = 0;
        }

        my $tmpStr = sprintf ("%s;", $symbol);
        $tmpStr .= sprintf ("%d;",   defined $elements{$symbol}{'number'} ? $elements{$symbol}{'number'} : 0);
        $tmpStr .= sprintf ("%f;", defined $elements{$symbol}{'relMass'} ? $elements{$symbol}{'relMass'} : 0);
        $tmpStr .= sprintf ("%f;", defined $elements{$symbol}{'stdWeight'} ? $elements{$symbol}{'stdWeight'} : 0);
        $tmpStr .= sprintf ("%f;", defined $elements{$symbol}{'vdwRadius'} ? $elements{$symbol}{'vdwRadius'} : 0);
        printf PTECSV $tmpStr . "\n";
    }
    close(PTECSV);
}
