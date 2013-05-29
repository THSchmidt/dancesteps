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

package PTE;

use strict;
use warnings;

use base 'Exporter';

our $VERSION = '1.0';

our @EXPORT_OK = qw(addElement
                    atomName2Element
                    getElementData
                    isElement
                    printPte);
my %elements;
my @keys  = qw(symbol number name      stdWeight     relMass           vdwRadius);
my @table = qw(Dum    0      Dummy       0.000000      0.000000        0.000
               H      1      Hydrogen    1.007947      1.0078250320710 0.110
               D      1      Deuterium   1.007947      2.01410177784   0.110
               T      1      Tritium     1.007947      3.016049277725  0.110
               He     2      Helium      4.0026022     4.002603254156  0.140
               Li     3      Lithium     6.9412        7.016004558     0.182
               Be     4      Beryllium   9.0121823     9.01218224      0.153
               B      5      Boron      10.8117       11.00930544      0.192
               C      6      Carbon     12.01078      12.00000000      0.170
               N      7      Nitrogen   14.00672      14.00307400486   0.155
               O      8      Oxygen     15.99943      15.9949146195616 0.152
               F      9      Fluorine   18.99840325   18.998403227     0.147
               Ne    10      Neon       20.17976      19.992440175419  0.154
               Na    11      Sodium     22.989769282  22.989769280929  0.227
               Mg    12      Magnesium  24.30506      23.98504170014   0.173
               Al    13      Aluminium  26.98153868   26.9815386312    0.184
               Si    14      Silicon    28.08553      27.976926532519  0.210
               P     15      Phosphorus 30.9737622    30.9737616320    0.180
               S     16      Sulfur     32.0655       31.9720710015    0.180
               Cl    17      Chlorine   35.4532       34.968852684     0.175
               Ar    18      Argon      39.9481       39.962383122529  0.188
               K     19      Potassium  39.09831      38.9637066820    0.275
               Ca    20      Calcium    40.0784       39.9625909822    0.231
               Sc    21      Scandium   44.9559126    44.95591199      0.211
               Ti    22      Titanium   47.8671       47.94794639      0.0
               V     23      Vanadium   50.94151      50.943959511     0.0
               Cr    24      Chromium   51.99616      51.94050758      0.0
               Mn    25      Manganese  54.9380455    54.93804517      0.0
               Fe    26      Iron       55.8452       55.93493757      0.0
               Co    27      Cobalt     58.9331955    58.93319507      0.0
               Ni    28      Nickel     58.69344      57.93534297      0.163
               Cu    29      Copper     63.5463       62.92959756      0.140
               Zn    30      Zinc       65.382        63.92914227      0.139
               Ga    31      Gallium    69.7231       68.925573613     0.187
               Ge    32      Germanium  72.641        73.921177818     0.211
               As    33      Arsenic    74.921602     74.921596520     0.185
               Se    34      Selenium   78.963        79.916521321     0.190
               Br    35      Bromine    79.9041       78.918337122     0.185
               Kr    36      Krypton    83.7982       83.9115073       0.202
               Rb    37      Rubidium   85.46783      84.91178973812   0.303
               Sr    38      Strontium  87.621        87.905612112     0.249
               Y     39      Yttrium    88.905852     88.905848327     0.0
               Zr    40      Zirconium  91.2242       89.904704425     0.0
               Nb    41      Niobium    92.906382     92.906378126     0.0
               Mo    42      Molybdenum 95.962        97.905408221     0.0
               Tc    43      Technetium 98            97.9072164       0.0
               Ru    44      Ruthenium 101.072       101.904349322     0.0
               Rh    45      Rhodium   102.905502    102.9055043       0.0
               Pd    46      Palladium 106.421       105.9034864       0.163
               Ag    47      Silver    107.86822     106.9050975       0.172
               Cd    48      Cadmium   112.4118      111.902757829     0.158
               In    49      Indium    114.8183      114.9038785       0.193
               Sn    50      Tin       118.7107      119.902194727     0.217
               Sb    51      Antimony  121.7601      120.903815724     0.206
               Te    52      Tellurium 127.603       129.906224421     0.206
               I     53      Iodine    126.904473    126.9044734       0.198
               Xe    54      Xenon     131.2936      131.904153510     0.216
               Cs    55      Caesium   132.90545192  132.90545193324   0.343
               Ba    56      Barium    137.3277      137.90524725      0.268
               Hf    72      Hafnium   178.492       179.946550023     0.0
               Ta    73      Tantalum  180.947882    180.947995819     0.0
               W     74      Tungsten  183.841       183.95093129      0.0
               Re    75      Rhenium   186.2071      186.955753115     0.0
               Os    76      Osmium    190.233       191.961480727     0.0
               Ir    77      Iridium   192.2173      192.962926418     0.0
               Pt    78      Platinum  195.0849      194.96479119      0.175
               Au    79      Gold      196.9665694   196.96656876      0.166
               Hg    80      Mercury   200.592       201.97064306      0.155
               Tl    81      Thallium  204.38332     204.974427514     0.196
               Pb    82      Lead      207.21        207.976652113     0.202
               Bi    83      Bismuth   208.980401    208.980398716     0.207
               Po    84      Polonium  209           208.982430420     0.197
               At    85      Astatine  210           209.9871488       0.202
               Rn    86      Radon     222           222.017577725     0.220
               Fr    87      Francium  223           223.019735926     0.348
               Ra    88      Radium    226           226.025409825     0.283
               U     92      Uranium   238.028913    238.050788220     0.186
               Rf   104      Rutherfordium 265       265.1167046       0.0
               Db   105      Dubnium   268           268.1254557       0.0
               Sg   106      Seaborgium 271          271.1334770       0.0
               Bh   107      Bohrium   272           272.1380365       0.0
               Hs   108      Hassium   270           270.1346531       0.0
               Mt   109      Meitnerium 276          276.1511673       0.0
               Ds   110      Darmstadtium 281        281.1620678       0.0
               Rg   111      Roentgenium 280         280.1644780       0.0
               Cn   112      Copernicium 285         285.1741178       0.0
               Uut  113      Ununtrium 284           284.1780886       0.0
               Fl   114      Flerovium 289           289.1872879       0.0
               Uup  115      Ununpentium 288         288.1924992       0.0
               Lv   116      Livermorium 293         0                 0.0
               Uus  117      Ununseptium 292         292.20755101      0.0
               Uuo  118      Ununoctium 294          0                 0.0
               Z    247      Zuunium   300           300.000000        0.600
               CGA  999      Bead      000.000000    000.000000        0.400);

### Create %elements hash ######################################################
my $nKeys = scalar(@keys);
for (my $i=0; $i<@table; $i+=$nKeys) {
    for (my $j=0; $j<$nKeys; $j++) {
        $elements{ $table[$i] }{ $keys[$j] } = $table[$i+$j];
    }
}
################################################################################



sub isElement { # $_[0] = element name, if $_[1] = true -> turn warnings off (default: warnings on).
    unless ($elements{$_[0]}) {
        warn "WARNING: Element \"$_[0]\" does not exist.\n" unless $_[1];
        return;
    }
    return 1;
}



sub getElementData { # $_[0] = $symbol, $_[1] = any element of @keys.
    return unless isElement($_[0]);
    unless ($elements{$_[0]}{$_[1]}) {
        warn "WARNING: Element \"$_[0]\" has no number.\n";
        return;
    }
    return $elements{$_[0]}{$_[1]};
}



sub atomName2Element {
    my $atomName = shift;

    return $atomName if isElement($atomName, 1);
    $atomName =~ /([A-Za-z]{1,3})/;
    return $1 if isElement($1, 1);

    my $oneLetter = substr($1, 0, 1);
    return $oneLetter if isElement($oneLetter, 1);

    warn("WARNING: No element was found for atom name \"$atomName\".\n");
    return;
}



#sub getNumberByElement {
#    unless ($elements{$_[0]}) {
#        warn "WARNING: Element \"$_[0]\" does not exist.\n";
#        return;
#    }
#    unless ($elements{$_[0]}{'number'}) {
#        warn "WARNING: Element \"$_[0]\" has no number.\n";
#        return;
#    }
#    return $elements{$_[0]}{'number'};
#}
#
#
#
#sub getStdWeightByElement {
#    unless ($elements{$_[0]}) {
#        warn "WARNING: Element \"$_[0]\" does not exist.\n";
#        return;
#    }
#    unless ($elements{$_[0]}{'stdWeight'}) {
#        warn "WARNING: Element \"$_[0]\" has no standard weight.\n";
#        return;
#    }
#    return $elements{$_[0]}{'stdWeight'};
#}
#
#
#
#sub getRelMassByElement {
#    unless ($elements{$_[0]}) {
#        warn "WARNING: Element \"$_[0]\" does not exist.\n";
#        return;
#    }
#    unless ($elements{$_[0]}{'relMass'}) {
#        warn "WARNING: Element \"$_[0]\" has no relative mass.\n";
#        return;
#    }
#    return $elements{$_[0]}{'relMass'};
#}
#
#
#
#sub getVdwRadiusByElement {
#    unless ($elements{$_[0]}) {
#        warn "WARNING: Element \"$_[0]\" does not exist.\n";
#        return;
#    }
#    unless ($elements{$_[0]}{'vdwRadius'}) {
#        warn "WARNING: Element \"$_[0]\" has no VDW radius.\n";
#        return;
#    }
#    return $elements{$_[0]}{'vdwRadius'};
#}



sub printPte {
    print join(" ", @keys) . "\n";

    foreach my $symbol ( sort { $elements{$a}{'number'} <=> $elements{$b}{'number'} } keys %elements ) {
        foreach (@keys) {
            if ($_ eq "number") {
                printf("%3d ", $elements{$symbol}{$_});
            }
            elsif ($elements{$symbol}{$_} =~ /^\d+(\.\d+)?$/) {
                printf("%10.6f ", $elements{$symbol}{$_});
            }
            elsif ($_ eq "symbol") {
                printf("%-3s ", $elements{$symbol}{$_});
            }
            else {
                printf("%-14s ", $elements{$symbol}{$_});
            }
        }
        print "\n";
    }
}



sub addElement {
    return if $nKeys != scalar(@_);
    return if $elements{ $_[0] };

    for (my $j=0; $j<$nKeys; $j++) {
        $elements{ $_[0] }{ $keys[$j] } = $_[$j];
    }
    return 1;
#    $elements{$_[0]}{'symbol'}    = $_[0];
#    $elements{$_[0]}{'number'}    = $_[1];
#    $elements{$_[0]}{'stdWeight'} = $_[2];
#    $elements{$_[0]}{'relMass'}   = $_[3];
#    $elements{$_[0]}{'vdwRadius'} = $_[4];
}


# Zuunium (247) is a rare element from a planet called Zuun, which can be used for creating superheros or to form the word 'BaZINGa' with element symbols.
# Wikipedia contributors, "Timber Wolf (comics)," Wikipedia, The Free Encyclopedia, http://en.wikipedia.org/w/index.php?title=Timber_Wolf_(comics)&oldid=512914132 (accessed January 4, 2013).
# http://www.funnyjunk.com/funny_pictures/2918986/Bazinga/

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

1;