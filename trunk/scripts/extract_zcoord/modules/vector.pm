package Vector;

use strict;

require Exporter;

my @ISA = qw(Exporter);
my @EXPORT = qw(vSub vLen vNorm vXprod vDotprod);


sub vSub {
    my %vecDiff = ('cooX' => $_[0]{'cooX'} - $_[1]{'cooX'},
                   'cooY' => $_[0]{'cooY'} - $_[1]{'cooY'},
                   'cooZ' => $_[0]{'cooZ'} - $_[1]{'cooZ'});
    return %vecDiff;
}



sub vLen {
    return sqrt($_[0]{'cooX'}*$_[0]{'cooX'} + $_[0]{'cooY'}*$_[0]{'cooY'} + $_[0]{'cooZ'}*$_[0]{'cooZ'});
}



sub vNorm {
    my $vecLen  = vLen($_[0]);
    my %vecNorm = ('cooX' => $_[0]{'cooX'}/$vecLen,
                   'cooY' => $_[0]{'cooY'}/$vecLen,
                   'cooZ' => $_[0]{'cooZ'}/$vecLen);
    return %vecNorm;
}



sub vXprod {
    my %vecXprod = ('cooX' => $_[0]{'cooY'} * $_[1]{'cooZ'} - $_[0]{'cooZ'} * $_[1]{'cooY'},
                    'cooY' => $_[0]{'cooZ'} * $_[1]{'cooX'} - $_[0]{'cooX'} * $_[1]{'cooZ'},
                    'cooZ' => $_[0]{'cooX'} * $_[1]{'cooY'} - $_[0]{'cooY'} * $_[1]{'cooX'});
    return %vecXprod;
}



sub vDotprod {
    return ($_[0]{'cooX'} * $_[1]{'cooX'} + $_[0]{'cooY'} * $_[1]{'cooY'} + $_[0]{'cooZ'} * $_[1]{'cooZ'});
}

1;