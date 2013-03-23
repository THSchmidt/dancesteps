#!/usr/bin/perl -w

use strict;
use Math::Trig;

=pod

=head1 vector.pm

This Module contains some functions for vector operations.

 

=begin html

<hr />

=end html


=head2 vec_addi()

=over 4

=item * Description

Add vector B to vector A.

=item * Needs

Needs 2 Matrices (one for vector A, one for vector B) with the x-, y- and z-values.

=item * Returns

Returns the sum of the input vectors (e.g. a moving vector).

=back 4

 

=begin html

<hr />

=end html

=cut

sub vec_addi {
    my $vectorA = shift;
    my $vectorB = shift;

    my @moveVec;

    my $dimensVecA = @$vectorA;
    my $dimensVecB = @$vectorB;

    if ($dimensVecA != $dimensVecB) {
        die "ERROR: Dimension of Vector A differs from Dimension of Vector B.";
    }

    $moveVec[0] = @$vectorA[0] + @$vectorB[0];
    $moveVec[1] = @$vectorA[1] + @$vectorB[1];
    $moveVec[2] = @$vectorA[2] + @$vectorB[2];

    return @moveVec;

}


=head2 vec_subt()

=over 4

=item * Description

Subtract vector B from vector A.

=item * Needs

Needs 2 Matrices (one for vector A, one for vector B) with the x-, y- and z-values.

=item * Returns

Returns the difference of the input vectors (e.g. a moving vector).

=back 4

=cut

sub vec_subt {
    my $vectorA = shift;
    my $vectorB = shift;

    my @moveVec;

    my $dimensVecA = @$vectorA;
    my $dimensVecB = @$vectorB;

    if ($dimensVecA != $dimensVecB) {
        die "ERROR: Dimension of Vector A differs from Dimension of Vector B.";
    }

    $moveVec[0] = @$vectorA[0] - @$vectorB[0];
    $moveVec[1] = @$vectorA[1] - @$vectorB[1];
    $moveVec[2] = @$vectorA[2] - @$vectorB[2];

    return @moveVec;
}


=head2 dot_prod()

=over 4

=item * Description

Calculated the scalar Dotproduct of two vectors.

=item * Needs

Needs two vectors (Vector A, Vector B) with the x-, y- and z-values of each vector.

=item * Returns

Returns the scalar product of the two input vectors.

=back 4

 

=begin html

<hr />

=end html

=cut

sub dot_prod {
    my $vectorA = shift;
    my $vectorB = shift;

    my $dotProd = 0;

    my $dimensVecA = @$vectorA;
    my $dimensVecB = @$vectorB;

    if ($dimensVecA != $dimensVecB) {
        die "ERROR: Dimension of Vector A differs from Dimension of Vector B.";
    }

    for (my $i=0; $i<$dimensVecA; $i++) {
        $dotProd += (@$vectorA[$i] * @$vectorB[$i]);
    }

    return $dotProd;
}


sub vec_angle { # Calculates the angle between vector A and B.
    my $vectorA = shift;
    my $vectorB = shift;
    my $vecALen = shift;
    my $vecBLen = shift;

    my $phi = 0;

    if (!$vecALen) { $vecALen = vec_len($vectorA); }
    if (!$vecBLen) { $vecBLen = vec_len($vectorB); }

    my $dimensVecA = @$vectorA;
    my $dimensVecB = @$vectorB;

    if ($dimensVecA != $dimensVecB) {
        die "ERROR: Dimension of Vector A differs from Dimension of Vector B.";
    }

    $phi = acos(dot_prod($vectorA, $vectorB)/($vecALen * $vecBLen));
    return rad2deg($phi);
}

sub vec_len {
    my $vector = shift;
    my $vecLen = 0;

    foreach (@$vector) {
        $vecLen += $_**2;
    }

    return sqrt($vecLen);
}

sub norm_vec {
    my $vector = shift;
    my $vecLen = vec_len($vector);
    my @normVec;

    foreach (@$vector) {
        push(@normVec, $_/$vecLen);
    }
    return @normVec;
}

sub cross_prod {
    my $vectorA = shift;
    my $vectorB = shift;
    my @crossProd;

    my $dimensVecA = @$vectorA;
    my $dimensVecB = @$vectorB;

    if ($dimensVecA != $dimensVecB) {
        die "ERROR: Dimension of Vector A ($dimensVecA) differs from Dimension of Vector B ($dimensVecB).";
    }

    $crossProd[0] = (@$vectorA[1] * @$vectorB[2]) - (@$vectorA[2] * @$vectorB[1]);
    $crossProd[1] = (@$vectorA[2] * @$vectorB[0]) - (@$vectorA[0] * @$vectorB[2]);
    $crossProd[2] = (@$vectorA[0] * @$vectorB[1]) - (@$vectorA[1] * @$vectorB[0]);

    return @crossProd;
}

sub transl_vec {
    my $vector = shift;
    my $direction = shift; # + (positiv, away from the center), - (negativ, to the center)
    my @move;
    $move[0] = shift; # X-move
    $move[1] = shift; # Y-move
    $move[2] = shift; # Z-move
    my @movedCoord;

    if ($direction eq "-") {
        $move[0] *= (-1);
        $move[1] *= (-1);
        $move[2] *= (-1);
    }

    my $dimensVec = @$vector;
    my $dimensMove = @move;

    if ($dimensVec != $dimensMove) {
        die "ERROR: Dimension of Vector ($dimensVec) differs from Number of moving parameters ($dimensMove).";
    }

    for (my $i=0; $i<$dimensVec; $i++) {
        $movedCoord[$i] = @$vector[$i] + $move[$i];
    }
    return @movedCoord;
}

sub perpen_2vec {
    # Find the perpendicular of two vectors.
    my $vectorA = shift;
    my $vectorB = shift;
    my $rotatPoint = shift; # Rotational Point

    my @subtVecA = vec_subt($vectorA, $rotatPoint);
    my @subtVecB = vec_subt($vectorB, $rotatPoint);

    my @perpenAxis = cross_prod(\@subtVecA, \@subtVecB);

    return vec_addi(\@perpenAxis, $rotatPoint);
}



sub rotate_by_vec {
    my $atomRef       = shift;
#    my $vectorARef = shift;
#    my $vectorBRef = shift;
    my $axisVecRef  = shift;
    my $rotPointRef = shift;
    my $rotAngle    = shift;
    my @atoms = @$atomRef;

    my $tolerance2Zero = 1e-6;

    my @rotatAxis = vec_subt($axisVecRef, $rotPointRef); # Set the rotational point to 0.

    my @unitVecZ = norm_vec(\@rotatAxis); # -> Get unit vector z; Rotate later around this axis.

    ### Find the direction (x,y,z) of the vector with the lowest value.
    my $lowDirecInd = 0;
    my $lowDirec = $unitVecZ[$lowDirecInd]; # Initialize with the X-Coordinate as "lowest-direction"-value.
    for (my $i=1; $i<@unitVecZ; $i++) { # $i will be only 1 and 2 (3 Coordinates, initialization with 0 (see before)).
        if ($unitVecZ[$i] < $lowDirec) {
            $lowDirec = $unitVecZ[$i];
            $lowDirecInd = $i; # -> Important operation (needed for next step).
        }
    }

    ### Calculate the second and third basis vector (unit vectors x and y)
    my @tmpVector = (0,0,0);
    $tmpVector[$lowDirecInd] = 1;
    
    my @crossGetY = cross_prod(\@unitVecZ, \@tmpVector); # Calculate the CrossProduct to get the direction of Y.
    my @unitVecY = norm_vec(\@crossGetY); # -> Get unit vector y.
    my @unitVecX = cross_prod(\@unitVecY, \@unitVecZ); # -> Get unit vector x.


    ### Build the new orthonormal system and check it ###
    my @newOrthoSys = ([@unitVecX], [@unitVecY], [@unitVecZ]); # New Base with rotational axis = z.

    my $chkOrthoXY = dot_prod(\@unitVecX, \@unitVecY);
    my $chkOrthoXZ = dot_prod(\@unitVecX, \@unitVecZ);
    my $chkOrthoYZ = dot_prod(\@unitVecY, \@unitVecZ);
    if (abs($chkOrthoXY) > $tolerance2Zero or abs($chkOrthoXZ) > $tolerance2Zero or abs($chkOrthoYZ) > $tolerance2Zero) {
        die "ERROR: Cannot build orthogonal system for the rotation.\n".
            "Unit vector x = (".join(", ", @unitVecX)."),\n".
            "unit vector y = (".join(", ", @unitVecY)."),\n".
            "unit vector z = (".join(", ", @unitVecZ).")\n";
    }


    #####################################################
    ### Rotation ########################################
    #####################################################
    my @rotatedCoords;
    my $angCos = cos(deg2rad($rotAngle));
    my $angSin = sin(deg2rad($rotAngle));

    for (my $atomID=0; $atomID<@atoms; $atomID++) {
        my @coordCenter = vec_subt(\@{$atoms[$atomID]{"coords"}}, $rotPointRef);
        my $radiusX = dot_prod(\@unitVecX, \@coordCenter);
        my $radiusY = dot_prod(\@unitVecY, \@coordCenter);
        my $compouZ = dot_prod(\@unitVecZ, \@coordCenter);

        my $coeffiX = $radiusX*$angCos - $radiusY*$angSin;
        my $coeffiY = $radiusX*$angSin + $radiusY*$angCos;
        my @coeffiMat = ($coeffiX, $coeffiY, $compouZ); # z is rotational axis.

        my @tmpRotated = (0,0,0);

        for (my $j=0; $j<3; $j++) {
            for (my $k=0; $k<3; $k++) {
                $tmpRotated[$j] += $coeffiMat[$k]*$newOrthoSys[$k][$j];
            }
        }
        my @cooRotBack = vec_addi(\@tmpRotated, $rotPointRef);
        $rotatedCoords[$atomID]{"coords"} = [@cooRotBack];
    }
    return @rotatedCoords;
}



# sub get_trafo_matrix {
#     my $baseOriginRef = shift;
#     my $baseNewInvRef = shift;
#     my @baseOrigin = @$baseOriginRef;
#     my @baseNewInv = @$baseNewInvRef;
#     
#     my @resultMat;
#     
#     $resultMat[0][0] = $baseNewInv[0][0]*$baseOrigin[0][0] + $baseNewInv[0][1]*$baseOrigin[1][0] + $baseNewInv[0][2]*$baseOrigin[2][0];
#     $resultMat[0][1] = $baseNewInv[0][0]*$baseOrigin[0][1] + $baseNewInv[0][1]*$baseOrigin[1][1] + $baseNewInv[0][2]*$baseOrigin[2][1];
#     $resultMat[0][2] = $baseNewInv[0][0]*$baseOrigin[0][2] + $baseNewInv[0][1]*$baseOrigin[1][2] + $baseNewInv[0][2]*$baseOrigin[2][2];
#     
#     $resultMat[1][0] = $baseNewInv[1][0]*$baseOrigin[0][0] + $baseNewInv[1][1]*$baseOrigin[1][0] + $baseNewInv[1][2]*$baseOrigin[2][0];
#     $resultMat[1][1] = $baseNewInv[1][0]*$baseOrigin[0][1] + $baseNewInv[1][1]*$baseOrigin[1][1] + $baseNewInv[1][2]*$baseOrigin[2][1];
#     $resultMat[1][2] = $baseNewInv[1][0]*$baseOrigin[0][2] + $baseNewInv[1][1]*$baseOrigin[1][2] + $baseNewInv[1][2]*$baseOrigin[2][2];
#     
#     $resultMat[2][0] = $baseNewInv[2][0]*$baseOrigin[0][0] + $baseNewInv[2][1]*$baseOrigin[1][0] + $baseNewInv[2][2]*$baseOrigin[2][0];
#     $resultMat[2][1] = $baseNewInv[2][0]*$baseOrigin[0][1] + $baseNewInv[2][1]*$baseOrigin[1][1] + $baseNewInv[2][2]*$baseOrigin[2][1];
#     $resultMat[2][2] = $baseNewInv[2][0]*$baseOrigin[0][2] + $baseNewInv[2][1]*$baseOrigin[1][2] + $baseNewInv[2][2]*$baseOrigin[2][2];
#     
#     return @resultMat;
# }

sub get_inv_matrix {
    my $matrixRef = shift;
    my $determ = shift;
    my @matrix = @$matrixRef;

    $matrix[0][0] /= $determ;
    $matrix[0][1] /= $determ;
    $matrix[0][2] /= $determ;
    $matrix[1][0] /= $determ;
    $matrix[1][1] /= $determ;
    $matrix[1][2] /= $determ;
    $matrix[2][0] /= $determ;
    $matrix[2][1] /= $determ;
    $matrix[2][2] /= $determ;

    return @matrix;
}

sub get_determ {
    my $matrixRef = shift;
    my @matrix = @$matrixRef;
    
    my $determ = $matrix[0][0]*$matrix[1][1]*$matrix[2][2] + $matrix[0][1]*$matrix[1][2]*$matrix[2][0] + $matrix[0][2]*$matrix[1][0]*$matrix[2][1]
               - $matrix[0][2]*$matrix[1][1]*$matrix[2][0] - $matrix[0][0]*$matrix[1][2]*$matrix[2][1] - $matrix[0][1]*$matrix[1][0]*$matrix[2][2];
    return $determ;
}


1;