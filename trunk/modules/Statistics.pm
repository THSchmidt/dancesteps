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

require Exporter;
package Statistics;
use strict;

our $VERSION = 1.0;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(min max mean variance stddev all);


sub min {
    my $vectorRef = shift;
    my $min;

    return unless $vectorRef;
    return unless scalar(@{$vectorRef});

    for (my $i=0; $i<@{$vectorRef}; $i++) {
        next unless defined $$vectorRef[$i];
        if (defined $min) {
            $min = $$vectorRef[$i] if $$vectorRef[$i] < $min;
        }
        else {
            $min = $$vectorRef[$i];
        }
    }

    return unless $min;
    return $min;
}


sub max {
    my $vectorRef = shift;
    my $max;

    return unless $vectorRef;
    return unless scalar(@{$vectorRef});

    for (my $i=0; $i<@{$vectorRef}; $i++) {
        next unless defined $$vectorRef[$i];
        if (defined $max) {
            $max = $$vectorRef[$i] if $$vectorRef[$i] > $max;
        }
        else {
            $max = $$vectorRef[$i];
        }
    }

    return unless $max;
    return $max;
}
    


sub mean {
    my $vectorRef   = shift;
    my $sum         = 0;
    my $cardinality = 0;

    return unless $vectorRef;
    return unless scalar(@{$vectorRef});

    for (my $i=0; $i<@{$vectorRef}; $i++) {
        next unless defined $$vectorRef[$i];
        $sum += $$vectorRef[$i];
        $cardinality++;
    }

    return unless $cardinality;
    return ($sum/$cardinality);
}



sub variance {
    my $vectorRef   = shift;
    my $mean        = shift; # Optional.
    my $tmp         = 0;
    my $cardinality = 0;

    return unless $vectorRef;
    return unless scalar(@{$vectorRef});
    $mean = mean($vectorRef) unless defined $mean;
    return unless $mean;

    for (my $i=0; $i<@{$vectorRef}; $i++) {
        next unless defined $$vectorRef[$i];
        $tmp += ($$vectorRef[$i] - $mean)**2;
        $cardinality++;
    }

    return unless $cardinality;
    return ($tmp/($cardinality-1));
}



sub stddev {
    my $vectorRef   = shift;
    my $variance    = shift; # Optional.
    my $mean        = shift; # Optional.

    return unless $vectorRef;
    return unless scalar(@{$vectorRef});
    unless (defined $variance) {
        $variance = defined $mean ? variance($vectorRef, $mean) : variance($vectorRef);
    }
    return unless $variance;

    return sqrt($variance);
}



sub all {
    my $vectorRef = shift;
    my $mean      = 0;
    my $variance  = 0;
    my $stddev    = 0;

    return unless $vectorRef;
    return unless scalar(@{$vectorRef});

    $mean     = mean($vectorRef);
    return unless $mean;

    $variance = variance($vectorRef, $mean);
    return unless $variance;

    $stddev = stddev($vectorRef, $variance, $mean);
    return unless $stddev;

    return ($mean, $variance, $stddev);
}


1;
