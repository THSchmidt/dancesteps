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

package MolOps;

use strict;
use warnings;

use base 'Exporter';

our $VERSION = '1.0';

our @EXPORT    = qw();
our @EXPORT_OK = qw(getGeoCenter getGeoCenterPbc getCom getComPbc);

use constant PI    => 3.14159265358979;
use constant TWOPI => 6.28318530717958;


sub getGeoCenter {
    my $atomIdsRef   = shift;
    my $coordDataRef = shift;

    my %geoCen  = ('cooX' => 0,
                   'cooY' => 0,
                   'cooZ' => 0);

    foreach (@{$atomIdsRef}) {
        $geoCen{'cooX'} += $$coordDataRef[$_]{'cooX'};
        $geoCen{'cooY'} += $$coordDataRef[$_]{'cooY'};
        $geoCen{'cooZ'} += $$coordDataRef[$_]{'cooZ'};
    }

    $geoCen{'cooX'} /= scalar(@{$atomIdsRef});
    $geoCen{'cooY'} /= scalar(@{$atomIdsRef});
    $geoCen{'cooZ'} /= scalar(@{$atomIdsRef});

    return %geoCen;
}



sub getGeoCenterPbc {
    my $atomIdsRef   = shift;
    my $coordDataRef = shift;
    my $boxRef       = shift;

    my (%avgXi, %avgZeta, %avgTheta);
    my %geoCen  = ('cooX' => 0,
                   'cooY' => 0,
                   'cooZ' => 0);

    foreach (@{$atomIdsRef}) {
        my $theta = $$coordDataRef[$_]{'cooX'} * TWOPI / $$boxRef{'cooX'};
        $avgXi{'cooX'}   += $$boxRef{'cooX'} * cos($theta);
        $avgZeta{'cooX'} += $$boxRef{'cooX'} * sin($theta);

        $theta = $$coordDataRef[$_]{'cooY'} * TWOPI / $$boxRef{'cooY'};
        $avgXi{'cooY'}   += $$boxRef{'cooY'} * cos($theta);
        $avgZeta{'cooY'} += $$boxRef{'cooY'} * sin($theta);

        $theta = $$coordDataRef[$_]{'cooZ'} * TWOPI / $$boxRef{'cooZ'};
        $avgXi{'cooZ'}   += $$boxRef{'cooZ'} * cos($theta);
        $avgZeta{'cooZ'} += $$boxRef{'cooZ'} * sin($theta);
    }

    $avgXi{'cooX'}   /= scalar(@{$atomIdsRef});
    $avgXi{'cooY'}   /= scalar(@{$atomIdsRef});
    $avgXi{'cooZ'}   /= scalar(@{$atomIdsRef});

    $avgZeta{'cooX'} /= scalar(@{$atomIdsRef});
    $avgZeta{'cooY'} /= scalar(@{$atomIdsRef});
    $avgZeta{'cooZ'} /= scalar(@{$atomIdsRef});

    $avgTheta{'cooX'} = atan2(-1*$avgZeta{'cooX'}, -1*$avgXi{'cooX'}) + PI;
    $avgTheta{'cooY'} = atan2(-1*$avgZeta{'cooY'}, -1*$avgXi{'cooY'}) + PI;
    $avgTheta{'cooZ'} = atan2(-1*$avgZeta{'cooZ'}, -1*$avgXi{'cooZ'}) + PI;

    $geoCen{'cooX'} = $$boxRef{'cooX'} * $avgTheta{'cooX'} / TWOPI;
    $geoCen{'cooY'} = $$boxRef{'cooY'} * $avgTheta{'cooY'} / TWOPI;
    $geoCen{'cooZ'} = $$boxRef{'cooZ'} * $avgTheta{'cooZ'} / TWOPI;

    return %geoCen;
}



sub getCom {
    my $atomIdsRef   = shift;
    my $coordDataRef = shift;

    my %com  = ('cooX' => 0,
                'cooY' => 0,
                'cooZ' => 0);
    my $mass = 0;

    foreach (@{$atomIdsRef}) {
        $com{'cooX'} += $$coordDataRef[$_]{'cooX'} * $$coordDataRef[$_]{'mass'};
        $com{'cooY'} += $$coordDataRef[$_]{'cooY'} * $$coordDataRef[$_]{'mass'};
        $com{'cooZ'} += $$coordDataRef[$_]{'cooZ'} * $$coordDataRef[$_]{'mass'};
        $mass        += $$coordDataRef[$_]{'mass'};
    }

    $com{'cooX'} /= $mass;
    $com{'cooY'} /= $mass;
    $com{'cooZ'} /= $mass;

    return %com;
}



sub getComPbc {
    my $atomIdsRef   = shift;
    my $coordDataRef = shift;
    my $boxRef       = shift;

    my (%avgXi, %avgZeta, %avgTheta);
    my %com  = ('cooX' => 0,
                'cooY' => 0,
                'cooZ' => 0);
    my $mass = 0;

    foreach (@{$atomIdsRef}) {
        ### Component x ########################################################
        my $theta  = $$coordDataRef[$_]{'cooX'} * TWOPI / $$boxRef{'cooX'};
        my $factor = $$boxRef{'cooX'} * $$coordDataRef[$_]{'mass'};
        $avgXi{'cooX'}   += cos($theta) * $factor;
        $avgZeta{'cooX'} += sin($theta) * $factor;

        ### Component y ########################################################
        $theta  = $$coordDataRef[$_]{'cooY'} * TWOPI / $$boxRef{'cooY'};
        $factor = $$boxRef{'cooY'} * $$coordDataRef[$_]{'mass'};
        $avgXi{'cooY'}   += cos($theta) * $factor;
        $avgZeta{'cooY'} += sin($theta) * $factor;

        ### Component z ########################################################
        $theta  = $$coordDataRef[$_]{'cooZ'} * TWOPI / $$boxRef{'cooZ'};
        $factor = $$boxRef{'cooZ'} * $$coordDataRef[$_]{'mass'};
        $avgXi{'cooZ'}   += cos($theta) * $factor;
        $avgZeta{'cooZ'} += sin($theta) * $factor;

        $mass        += $$coordDataRef[$_]{'mass'};
    }

    ### Get the mean value of each angle #######################################
    $avgXi{'cooX'} /= scalar(@{$atomIdsRef});
    $avgXi{'cooY'} /= scalar(@{$atomIdsRef});
    $avgXi{'cooZ'} /= scalar(@{$atomIdsRef});

    $avgZeta{'cooX'} /= scalar(@{$atomIdsRef});
    $avgZeta{'cooY'} /= scalar(@{$atomIdsRef});
    $avgZeta{'cooZ'} /= scalar(@{$atomIdsRef});


    ### Back projection ########################################################
    $avgTheta{'cooX'} = atan2(-1*$avgZeta{'cooX'} / $mass, -1*$avgXi{'cooX'} / $mass) + PI;
    $avgTheta{'cooY'} = atan2(-1*$avgZeta{'cooY'} / $mass, -1*$avgXi{'cooY'} / $mass) + PI;
    $avgTheta{'cooZ'} = atan2(-1*$avgZeta{'cooZ'} / $mass, -1*$avgXi{'cooZ'} / $mass) + PI;

    $com{'cooX'} = $$boxRef{'cooX'} * ($avgTheta{'cooX'}) / TWOPI;
    $com{'cooY'} = $$boxRef{'cooY'} * ($avgTheta{'cooY'}) / TWOPI;
    $com{'cooZ'} = $$boxRef{'cooZ'} * ($avgTheta{'cooZ'}) / TWOPI;

    return %com;
}

1;