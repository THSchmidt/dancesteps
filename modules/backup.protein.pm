package Protein;

use strict;
use pte;

require Exporter;
our $VERSION = 1.0;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(analyzeProtein getProtAtomIds);


our @aaList3Letter = qw(ALA CYS ASP GLU PHE GLY HIS ILE LYS LEU MET ASN PRO GLN ARG SER THR VAL TRP TYR);


sub getProtAtomIds {
    my $coordDataRef = shift;
    my @protAtomIds;
    my $aaSearchStr = join('|', @aaList3Letter);

    for (my $i=1; $i<@{$coordDataRef}; $i++) {
        next unless $$coordDataRef[$i]{'resName'};
        print $$coordDataRef[$i]{'atomName'} . "\n";
        push(@protAtomIds, \$$coordDataRef[$i]) if $$coordDataRef[$i]{'resName'} =~ /$aaSearchStr/;
    }

    return @protAtomIds;
}



sub analyzeProtein {
    my $ndxDataRef      = shift;
    my $protGroupId     = shift;
    my $suGroupIdsRef   = shift;
    my $coordsRef       = shift;
    my $boxRef          = shift;
    my $gridDelta       = shift;
    my $zMin            = shift;
    my $zMax            = shift;
    my $extCavDetection = shift;
    my $xyProfile       = shift;

    my $gridRef;
    my $gridsizeX = 0;
    my $gridsizeY = 0;

    my $gridAreaProtein;
    my $gridAreaCavity;


    ### Initialize grid ########################################################
    ($gridRef, $gridsizeX, $gridsizeY) = iniGrid($boxRef, $gridDelta);
    ############################################################################


    ### Create protein grid ####################################################
    $gridAreaProtein = protein2Grid($gridRef, $gridsizeX, $gridsizeY, $gridDelta, $$ndxDataRef[$protGroupId]{'atoms'}, $coordsRef, $zMin, $zMax);
    ############################################################################


    ### Connect subdomains to form a cavity ####################################
    connectSubunits($gridRef, $gridsizeX, $gridsizeY, $gridDelta, $ndxDataRef, $suGroupIdsRef, $coordsRef, $zMin, $zMax) if $suGroupIdsRef;
    ############################################################################


    ### Detect the cavity ######################################################
    $gridAreaCavity = detectCavity($gridRef, $gridsizeX, $gridsizeY, $gridDelta, , $extCavDetection);
    ############################################################################


    ### Write out the XY profile ###############################################
    writeXyProfile ($xyProfile, $gridRef, $gridsizeX, $gridsizeY, $gridDelta) if $xyProfile;
    ############################################################################


    return ($gridAreaProtein, $gridAreaCavity, $gridRef);
}



sub iniGrid {
    my $boxRef    = shift;
    my $gridDelta = shift;

    my @grid;
    my $gridsizeX = int($$boxRef{'cooX'} / $gridDelta) + 1;
    my $gridsizeY = int($$boxRef{'cooY'} / $gridDelta) + 1;

    printf("      Create a %dx%d XY grid: 0%%\r", $gridsizeX, $gridsizeY) if $main::verbose;
    for (my $x=0; $x<=$gridsizeX; $x++) {
        printf("      Create a %dx%d XY grid: %d%%\r", $gridsizeX, $gridsizeY, 100*$x/$gridsizeX) if $main::verbose;
        for (my $y=0; $y<=$gridsizeY; $y++) {
            $grid[$x][$y] = 0;
        }
    }
    printf("      Create a %dx%d XY grid: 100%%\n", $gridsizeX, $gridsizeY) if $main::verbose;

    return (\@grid, $gridsizeX, $gridsizeY);
}



sub protein2Grid {
    my $gridRef     = shift;
    my $gridsizeX   = shift;
    my $gridsizeY   = shift;
    my $gridDelta   = shift;
    my $atomsIdsRef = shift;
    my $coordsRef   = shift;
    my $zMin        = shift;
    my $zMax        = shift;

    my $nAreas      = 0;
    my $gridDelta2  = $gridDelta*$gridDelta;

    print "      Mapping atoms to the grid: 0.000%\r" if $main::verbose;
    foreach (@{$atomsIdsRef}) {
        next unless $$coordsRef[$_]{'cooZ'};
        next if $$coordsRef[$_]{'cooZ'} > $zMax;
        next if $$coordsRef[$_]{'cooZ'} < $zMin;
        printf("      Mapping atoms to the grid: %d%% (protein area %.4f nm^2)\r", (++$$coordsRef[$_]{'atomNum'})/scalar(@{$atomsIdsRef})*100, $nAreas*$gridDelta*$gridDelta) if $main::verbose;

        my $element = substr($$coordsRef[$_]{'atomName'}, 0, 1);
        my $radius  = PTE::getRadius($element);
        my $radius2 = $radius * $radius;

        my $tmpGridX = int($$coordsRef[$_]{'cooX'} / $gridDelta);
        my $tmpGridY = int($$coordsRef[$_]{'cooY'} / $gridDelta);
        my $subrange = int($radius / $gridDelta);

        for (my $x=getMax($tmpGridX-$subrange, 0); $x<=getMin($tmpGridX+$subrange, $gridsizeX-1); $x++) {
            for (my $y=getMax($tmpGridY-$subrange, 0); $y<=getMin($tmpGridY+$subrange, $gridsizeY-1); $y++) {
                my $dx = $$coordsRef[$_]{'cooX'} - $x * $gridDelta;
                my $dy = $$coordsRef[$_]{'cooY'} - $y * $gridDelta;
                my $dist2 = $dx*$dx + $dy*$dy;
                next if $dist2 > $radius2;
                ++$nAreas unless $$gridRef[$x][$y];
                $$gridRef[$x][$y] = 1;
            }
        }
    }
    printf("      Mapping atoms to the grid: 100%% (protein area %.4f nm^2)\n", $nAreas*$gridDelta2) if $main::verbose;

    return ($nAreas*$gridDelta2);
}



sub connectSubunits {
    my $gridRef       = shift;
    my $gridsizeX     = shift;
    my $gridsizeY     = shift;
    my $gridDelta     = shift;
    my $ndxDataRef    = shift;
    my $suGroupIdsRef = shift;
    my $coordsRef     = shift;
    my $zMin          = shift;
    my $zMax          = shift;

    my @gridSuGeoCenter;


    print "      Detecting subunit connections: 0.0000 nm^2 possible\r" if $main::verbose;

    ### Calculate center of mass of each protein subunit in that slice #########
    foreach my $suGroupId (@{$suGroupIdsRef}) {
        my %tmpSum = ('cooX' => 0, 'cooY' => 0);
        my $nAtoms = 0;
        foreach (@{$$ndxDataRef[$suGroupId]{'atoms'}}) {
            next unless $$coordsRef[$_]{'cooZ'};
            next if $$coordsRef[$_]{'cooZ'} > $zMax;
            next if $$coordsRef[$_]{'cooZ'} < $zMin;
            $tmpSum{'cooX'} += $$coordsRef[$_]{'cooX'};
            $tmpSum{'cooY'} += $$coordsRef[$_]{'cooY'};
            $nAtoms++;
        }
        next unless $nAtoms;
        $tmpSum{'cooX'} = int(($tmpSum{'cooX'}/$nAtoms)/$gridDelta);
        $tmpSum{'cooY'} = int(($tmpSum{'cooY'}/$nAtoms)/$gridDelta);
        push(@gridSuGeoCenter, \%tmpSum);
    }
    ############################################################################


    ### Print the geometrical center of each subunit ###########################
    for (my $i=0; $i<@gridSuGeoCenter; $i++) {
        getGridSlope($gridRef, $gridSuGeoCenter[$i-1], $gridSuGeoCenter[$i]);
    }
    ############################################################################
}



sub getGridSlope {
    my $gridRef   = shift;
    my $vecARef   = shift;
    my $vecBRef   = shift;

    my $slope = ($$vecBRef{'cooY'} - $$vecARef{'cooY'}) / ($$vecBRef{'cooX'} - $$vecARef{'cooX'});
    my $xMin = $$vecARef{'cooX'} < $$vecBRef{'cooX'} ? $$vecARef{'cooX'} : $$vecBRef{'cooX'};
    my $xMax = $$vecARef{'cooX'} > $$vecBRef{'cooX'} ? $$vecARef{'cooX'} : $$vecBRef{'cooX'};

    my $y = $$vecARef{'cooY'};
    for (my $x=$xMin; $x<=$xMax; $x++) {
        $y += $slope;
        my $intY = int($y);
        next if $$gridRef[$x][$intY];
        $$gridRef[$x][$intY] = 3;

        $$gridRef[$x+1][$intY] = 3;
        $$gridRef[$x-1][$intY] = 3;
        $$gridRef[$x][$intY+1] = 3;
        $$gridRef[$x][$intY-1] = 3;
        $$gridRef[$x+1][$intY+1] = 3;
        $$gridRef[$x+1][$intY-1] = 3;
        $$gridRef[$x-1][$intY+1] = 3;
        $$gridRef[$x-1][$intY-1] = 3;
    }
}



sub detectCavity {
    my $gridRef         = shift;
    my $gridsizeX       = shift;
    my $gridsizeY       = shift;
    my $gridDelta       = shift;
    my $extCavDetection = shift;

    my $nCavityAreas  = 0;
    my $gridDelta2    = $gridDelta*$gridDelta;


    print "      Detecting protein internal cavities: 0.0000 nm^2 possible\r" if $main::verbose;
    ### Invert protein grid (set all empty grid points to 2 (poss. cav.)) ######
    for (my $x=0; $x<=$gridsizeX; $x++) {
        for (my $y=0; $y<=$gridsizeY; $y++) {
            next if $$gridRef[$x][$y]; # Next loop if this grid point is defined as protein.
            $$gridRef[$x][$y] = 2;
            $nCavityAreas++;
        }
        printf("      Detecting protein internal cavities: %.4f nm^2 possible      \r", $nCavityAreas*$gridDelta2) if $main::verbose;
    }
    ############################################################################


    ### Washing out the cavities ###############################################
    for (my $i=0; $i<2; $i++) {
        my $foundExcl1 = 1;
        my $foundExcl2 = 1;
        for (my $x=0; $x<=$gridsizeX; $x++) {
            my $neighbCellX = $x - 1;
            $nCavityAreas -= $foundExcl1 = washingOutY($x, $neighbCellX, $gridsizeY, $gridRef, $extCavDetection);
            printf("      Detecting protein internal cavities: %.4f nm^2 possible      \r", $nCavityAreas*$gridDelta2) if $main::verbose;
        }

        for (my $x=$gridsizeX; $x>=0; $x--) {
            my $neighbCellX = $x + 1;
            $nCavityAreas -= $foundExcl2 = washingOutY($x, $neighbCellX, $gridsizeY, $gridRef, $extCavDetection);
            printf("      Detecting protein internal cavities: %.4f nm^2 possible      \r", $nCavityAreas*$gridDelta2) if $main::verbose;
        }
        $i = 0 if $foundExcl1 || $foundExcl2;
    }
    ############################################################################
    printf("      Detecting protein internal cavities: %.4f nm^2 detected      \n", $nCavityAreas*$gridDelta2) if $main::verbose;

    return ($nCavityAreas*$gridDelta2);
}



sub washingOutY {
    my $x               = shift;
    my $neighbCellX     = shift;
    my $gridsizeY       = shift;
    my $gridRef         = shift;
    my $extCavDetection = shift;

    my $delAreas        = 0;

    for (my $y=0; $y<=$gridsizeY; $y++) { # SW -> NE.
        my $neighbCellY = $y - 1;
        next unless $$gridRef[$x][$y] == 2; # Next if this grid point is not a possible cavity.
        unless ($$gridRef[$x][$neighbCellY]) { # If the neighbored cell is not protein or not a possible cavity...
            $$gridRef[$x][$y] = 0; # ...exclude this from a possible cavity.
            $delAreas++;
            next;
        }
        unless ($$gridRef[$neighbCellX][$y]) {
            $$gridRef[$x][$y] = 0;
            $delAreas++;
            next;
        }

        next unless $extCavDetection;
        unless ($$gridRef[$neighbCellX][$neighbCellY]) {
            $$gridRef[$x][$y] = 0;
            $delAreas++;
        }
    }

    for (my $y=$gridsizeY; $y>=0; $y--) { # NW -> SE.
        my $neighbCellY = $y + 1;
        next unless $$gridRef[$x][$y] == 2;
        unless ($$gridRef[$x][$neighbCellY]) {
            $$gridRef[$x][$y] = 0;
            $delAreas++;
            next;
        }
        unless ($$gridRef[$neighbCellX][$y]) {
            $$gridRef[$x][$y] = 0;
            $delAreas++;
            next;
        }

        next unless $extCavDetection;
        unless ($$gridRef[$neighbCellX][$neighbCellY]) {
            $$gridRef[$x][$y] = 0;
            $delAreas++;
        }
    }

    return $delAreas;
}



sub writeXyProfile {
    my $xyProfile = shift;
    my $gridRef   = shift;
    my $gridsizeX = shift;
    my $gridsizeY = shift;
    my $gridDelta = shift;

    printf("      Writing out protein xy grid profile: 0%%\r") if $main::verbose;
    open(XYPROFILE, ">$xyProfile") || die "ERROR: Cannot open profile output file \"$xyProfile\": $!\n";
    for (my $x=0; $x<=$gridsizeX; $x++) {
        my $tmpX = $x*$gridDelta; # Performance.
        for (my $y=0; $y<=$gridsizeY; $y++) {
            printf(XYPROFILE "%f %f %d\n", $tmpX, $y*$gridDelta, $$gridRef[$x][$y]) if $$gridRef[$x][$y];
        }
        printf("      Writing out protein xy grid profile: %d%%\r", 100*$x/$gridsizeX) if $main::verbose;
    }
    close XYPROFILE;
    printf("      Writing out protein xy grid profile: 100%%\n") if $main::verbose;
}



sub getMax {
    return $_[0] if $_[0] > $_[1];
    return $_[1];
}



sub getMin {
    return $_[0] if $_[0] < $_[1];
    return $_[1];
}


1;
