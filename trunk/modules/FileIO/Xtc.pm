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
#
#
# NOTE: This Perl module includes routines adapted from the C source code of the
# VMD molfile plugin (GROMACS.h) which is licensed under the University of
# Illinois/NCSA Open Source License. This license is compatible with the
# GNU GPL v2.
#
# The routines "xtcSizeOfInt", "xtcSizeOfInts", "xtcReceiveBits",
# "xtcReceiveInts", "xtc3dfCoord", as well as the $FIRSTIDX parameter, and the
# list of @xtcMagicInts are an implementation of the 3dfcoord algorithm written
# by Frans van Hoesel as part of the Europort project in 1995.


package FileIO::XTC;

use strict;
use warnings;

use base 'Exporter';

our $VERSION = '1.0';

our @EXPORT    = qw(openXtcFile
                    xtcTimestep
                    readXtc
                    closeXtcFile);

my @xtcMagicInts = qw(0 0 0 0 0 0 0 0 0 8 10 12 16 20 25 32 40 50 64 80 101 128 161
                      203 256 322 406 512 645 812 1024 1290 1625 2048 2580 3250
                      4096 5060 6501 8192 10321 13003 16384 20642 26007 32768 41285
                      52015 65536 82570 104031 131072 165140 208063 262144 330280
                      416127 524287 660561 832255 1048576 1321122 1664510 2097152
                      2642245 3329021 4194304 5284491 6658042 8388607 10568983
                      13316085 16777216);
my $FIRSTIDX = 9;


sub readXtc { # Read the entire XTC file into the @xtcData array. Woooohhh!!! Check your RAM...
    my ($xtcFile, $timeRangeRef) = @_;
    my @xtcData;

    ### Open XTC trajectory file ###############################################
    print "  ---------------------------------\n  Read XTC file \"$xtcFile\"... \r";
    my $fileHandleRef = openXtcFile($xtcFile);
    print "\n" if $main::verbose;
    ############################################################################


    ### Read trajectory frames #################################################
    my $frame = 0;
    while (my $what = xtcTimestep($fileHandleRef, \%{$xtcData[$frame]}, $timeRangeRef)) { # Functions returns 1 if frame was read & 2 if frame was skipped.
        $frame++ if $what == 1;
    }
    pop(@xtcData) if $frame < scalar(@xtcData);
    ############################################################################


    ### Close XTC trajectory file ##############################################
    closeXtcFile($fileHandleRef);
    print "\n" if $main::verbose;
    print "  Read XTC file \"$xtcFile\": Finished\n  ---------------------------------\n\n";
    ############################################################################

    return \@xtcData;
}




sub xtcTimestep {
    my $fileHandleRef = shift;
    my $stepDataRef   = shift;
    my $timeRangeRef  = shift;

    my $jump = 0; # Jump over this frame.
    my $size = 0;

    ### Check the magic number #################################################
    my $magicNumber = xtcInt($fileHandleRef);
    return unless $magicNumber == 1995;
    ############################################################################


    ### Get the number of atoms, integration step & time #######################
    $$stepDataRef{'nAtoms'} = xtcInt($fileHandleRef);
    $$stepDataRef{'step'}   = xtcInt($fileHandleRef);
    $$stepDataRef{'time'}   = xtcFloat($fileHandleRef);

    printf("  Step %d (%f ps)\r", $$stepDataRef{'step'}, $$stepDataRef{'time'}) if $main::verbose;
#    printf("\nStep %d (%f ps), %d atoms\n", $$stepDataRef{'step'}, $$stepDataRef{'time'}, $$stepDataRef{'nAtoms'}) if $main::verbose;
    ############################################################################


    ### Get the 3D box vectors #################################################
    $$stepDataRef{'box'}{'cooXX'} = xtcFloat($fileHandleRef);
    $$stepDataRef{'box'}{'cooXY'} = xtcFloat($fileHandleRef);
    $$stepDataRef{'box'}{'cooXZ'} = xtcFloat($fileHandleRef);
    $$stepDataRef{'box'}{'cooYX'} = xtcFloat($fileHandleRef);
    $$stepDataRef{'box'}{'cooYY'} = xtcFloat($fileHandleRef);
    $$stepDataRef{'box'}{'cooYZ'} = xtcFloat($fileHandleRef);
    $$stepDataRef{'box'}{'cooZX'} = xtcFloat($fileHandleRef);
    $$stepDataRef{'box'}{'cooZY'} = xtcFloat($fileHandleRef);
    $$stepDataRef{'box'}{'cooZZ'} = xtcFloat($fileHandleRef);

#    printf("Box  X        Y        Z\n  X %8.5f %8.5f %8.5f\n", $$stepDataRef{'box'}{'cooXX'}, $$stepDataRef{'box'}{'cooXY'}, $$stepDataRef{'box'}{'cooXZ'}) if $main::verbose;
#    printf("  Y %8.5f %8.5f %8.5f\n", $$stepDataRef{'box'}{'cooYX'}, $$stepDataRef{'box'}{'cooYY'}, $$stepDataRef{'box'}{'cooYZ'}) if $main::verbose;
#    printf("  Z %8.5f %8.5f %8.5f\n", $$stepDataRef{'box'}{'cooZX'}, $$stepDataRef{'box'}{'cooZY'}, $$stepDataRef{'box'}{'cooZZ'}) if $main::verbose;
    ############################################################################


    ### Check if coords should be read or skipped ##############################
    $$timeRangeRef{'range'}{'min'} = $$stepDataRef{'time'} if ($$timeRangeRef{'range'} && !defined $$timeRangeRef{'range'}{'min'});

    $jump = checkTimeRange($timeRangeRef, $$stepDataRef{'time'});
    return 0 if $jump == 2; # End of reading because the highest frame for reading is lower than the current.
    ############################################################################


    ### Read the coordinates ###################################################
    my $n = xtc3dfCoord($fileHandleRef, \@{$$stepDataRef{'atoms'}}, \$size, $jump); # $stepData{'atoms'} is an array reference; each element is a hash of three values: cooX, cooY, cooZ.
    return if ($n && $n < 0);
    return 2 if $jump == 1;
    ############################################################################

    return 1;
}



sub checkTimeRange {
    my $timeRangeRef = shift;
    my $currTimeStep  = shift;
    my $tolerance     = 0.05; # ps.

    if ($$timeRangeRef{'dump'}) {
        my @dumpSort = sort {$a <=> $b} @{$$timeRangeRef{'dump'}};
        return 2 if ($currTimeStep > $dumpSort[-1]+$tolerance);
        foreach my $time (@dumpSort) {
            return 0 if (($time-$tolerance) <= $currTimeStep && $currTimeStep <= ($time+$tolerance));
        }
    }
    elsif ($$timeRangeRef{'range'}) {
        if ($$timeRangeRef{'range'}{'min'} && $$timeRangeRef{'range'}{'max'}) {
            return 2 if ($currTimeStep > ($$timeRangeRef{'range'}{'max'}+$tolerance));
            if ($$timeRangeRef{'range'}{'step'}) { # Go stepwise.
                for (my $time=$$timeRangeRef{'range'}{'min'}; $time<=$$timeRangeRef{'range'}{'max'}; $time+=$$timeRangeRef{'range'}{'step'}) {
                    return 0 if (($time-$tolerance) <= $currTimeStep && $currTimeStep <= ($time+$tolerance));
                }
            }
            else {
                return 0 if (($$timeRangeRef{'range'}{'min'}-$tolerance) <= $currTimeStep && $currTimeStep <= ($$timeRangeRef{'range'}{'max'}+$tolerance));
            }
        }
        elsif ($$timeRangeRef{'range'}{'min'}) {
            if ($$timeRangeRef{'range'}{'step'}) { # Go stepwise.
                my $time = $$timeRangeRef{'range'}{'min'};
                while ($time <= ($currTimeStep + $tolerance)) {
                    return 0 if (($time-$tolerance) <= $currTimeStep && $currTimeStep <= ($time+$tolerance));
                    $time += $$timeRangeRef{'range'}{'step'};
                }
            }
            else {
                return 0 if (($$timeRangeRef{'range'}{'min'}-$tolerance) <= $currTimeStep);
            }
        }
    }
    return 1;
}



sub xtcInt {
    my $fileHandleRef = shift;
    my @tmpChar;

    fread(\@tmpChar, 1, 4, $fileHandleRef); # Size of an integer must be 4.

    return int($tmpChar[3] + ($tmpChar[2] << 8) + ($tmpChar[1] << 16) + ($tmpChar[0] << 24));
}



sub xtcFloat {
    my $fileHandleRef = shift;

    return unpack("f*", pack("i", xtcInt($fileHandleRef)));
}



sub xtcData {
    my $fileHandleRef = shift;
    my $bufRef        = shift;
    my $len           = shift;

    if ($bufRef) {
        return if (fread($bufRef, 1, $len, $fileHandleRef) != $len);
        if ($len % 4) {
            return unless sysseek(*{$fileHandleRef}, 4 - ($len % 4), 1); # Shift the reading position.
        }
    }
    else {
        my $newLen = $len;
        $newLen += (4 - ($len % 4)) if $len % 4;
        return unless sysseek(*{$fileHandleRef}, $newLen, 1); # Shift the reading position.
    }
    return $len;
}



### Returns the number of bits in the binary expansion of the given integer.
sub xtcSizeOfInt { # Takes only one scalar ($_[0]) which is the size.
    my $num   = 1;
    my $nBits = 0;

    while ($_[0] >= $num && $nBits < 32) {
        $nBits++;
        $num <<= 1;
    }
    return $nBits;
}



### Calculates the number of bits a set of compressed integers will take up.
sub xtcSizeOfInts { # $_[0] = $nInts, $_[1] = $sizesRef.
    my $num;
    my $nBytes = 1;
    my @bytes  = (1);
    my $byteCount;
    my $nBits  = 0;

    for (my $i=0; $i<$_[0]; $i++) {
        my $tmp = 0;
        for ($byteCount=0; $byteCount<$nBytes; $byteCount++) {
            $tmp = $bytes[$byteCount] * ${$_[1]}[$i] + $tmp;
            $bytes[$byteCount] = $tmp & 0xff;
            $tmp >>= 8;
        }
        while ($tmp != 0) {
            $bytes[$byteCount++] = $tmp & 0xff;
            $tmp >>=8;
        }
        $nBytes = $byteCount;
    }
    $num = 1;
    $nBytes--;
    while ($bytes[$nBytes] >= $num) {
        $nBits++;
        $num *= 2;
    }
    return $nBits + $nBytes * 8;
}



### Reads bits from a buffer.
sub xtcReceiveBits { # Time critical routine. Implementation for efficient runtimes looks weird (since there is no compiler), but works.
    my $nBits = $_[1]; # Copying the second param because of modification.
    my $mask  = int((1 << $nBits) - 1);
    my $num   = 0;

    while ($nBits >= 8) {
        ${$_[0]}[2] = int((${$_[0]}[2] << 8) | ${${$_[0]}[3]}[${$_[0]}[0]++]);
        $num     |= int((${$_[0]}[2] >> ${$_[0]}[1]) << ($nBits - 8));
        $nBits   -= 8;
    }
    if ($nBits > 0) {
        if (int(${$_[0]}[1]) < $nBits) {
            ${$_[0]}[1] += 8;
            ${$_[0]}[2] = int((${$_[0]}[2] << 8) | ${${$_[0]}[3]}[${$_[0]}[0]++]);
        }
        ${$_[0]}[1] -= $nBits;
        $num |= int((${$_[0]}[2] >> ${$_[0]}[1]) & ((1 << $nBits) - 1));
    }
    $num &= $mask;
    return int($num);
}


#sub xtcReceiveBits { # Long version (inefficient) for understanding what happens.
#    my ($bufRef, $nBits) = @_;
#
#    my $mask     = int((1 << $nBits) - 1);
#    my $cnt      = $$bufRef[0];
#    my $lastBits = int($$bufRef[1]);
#    my $lastByte = int($$bufRef[2]);
#    my @cBuf     = @{$$bufRef[3]}; # Replace this to someting like ${${$_[0]}[3]} enables efficient reading (no copying (copying is bad (bad, bad, bad))).
#    my $num      = 0;
#
#    while ($nBits >= 8) {
#        $lastByte = int(($lastByte << 8) | $cBuf[$cnt++]);
#        $num     |= int(($lastByte >> $lastBits) << ($nBits - 8));
#        $nBits   -= 8;
#    }
#    if ($nBits > 0) {
#        if ($lastBits < $nBits) {
#            $lastBits += 8;
#            $lastByte = int(($lastByte << 8) | $cBuf[$cnt++]);
#        }
#        $lastBits -= $nBits;
#        $num |= int(($lastByte >> $lastBits) & ((1 << $nBits) - 1));
#    }
#    $num &= $mask;
#    $$bufRef[0] = $cnt;
#    $$bufRef[1] = $lastBits;
#    $$bufRef[2] = $lastByte;
#    return int($num);
#}




### Decompress small integers from the buffer.
sub xtcReceiveInts {
    my ($bufRef, $nInts, $nBits, $sizesRef, $numsRef) = @_;

    my $num;
    my $p;
    my @bytes;
    $bytes[1] = $bytes[2] = $bytes[3] = 0;
    my $nBytes = 0;

    while ($nBits > 8) {
        $bytes[$nBytes++] = xtcReceiveBits($bufRef, 8);
        $nBits -= 8;
    }
    if ($nBits > 0) {
        $bytes[$nBytes++] = xtcReceiveBits($bufRef, $nBits);
    }
    for (my $i=$nInts-1; $i>0; $i--) {
        $num = 0;
        for (my $j=$nBytes-1; $j>=0; $j--) {
            $num = (int($num) << 8) | $bytes[$j];
            $p = int($num) / int($$sizesRef[$i]);
            $bytes[$j] = int($p);
            $num = int($num) - int($p) * int($$sizesRef[$i]);
        }
        $$numsRef[$i] = $num;
    }
    $$numsRef[0] = int($bytes[0]) | (int($bytes[1]) << 8) | (int($bytes[2]) << 16) | (int($bytes[3]) << 24);
}



### Function that actually reads and writes compressed coordinates.
sub xtc3dfCoord {
    my $fileHandleRef = shift;
    my $atomsRef      = shift;
    my $sizeRef       = shift;
    my $jump          = shift;

    my @buf = (0, 0, 0);
    my @minInt;
    my @maxInt;
    my @sizeInt;
    my @bitSizeInt;
    my $bitSize = 0;
    my $isSmaller;

    ### Get the list size of the following atoms ###############################
    my $lSize = xtcInt($fileHandleRef);

    return -1 if $lSize < 0;
    return if ($$sizeRef != 0 && $lSize != $$sizeRef);

    $$sizeRef = $lSize;
    if ($lSize <= 9) {
        for (my $i=0; $i<$$sizeRef; $i++) {
            return -1 if (($$atomsRef[$i]{'cooX'} = xtcFloat($fileHandleRef)) < 0);
            return -1 if (($$atomsRef[$i]{'cooY'} = xtcFloat($fileHandleRef)) < 0);
            return -1 if (($$atomsRef[$i]{'cooZ'} = xtcFloat($fileHandleRef)) < 0);
        }
        return $lSize;
    }
#    print "List size = $lSize\n";
    ############################################################################


    ### Get the precision ######################################################
    my $precision = xtcFloat($fileHandleRef);
    my $invPrecision = 1/$precision;
#    print "Precision = $precision\n";
    ############################################################################


    ### Get the size of the integers ###########################################
    $minInt[0] = xtcInt($fileHandleRef) - 4294967296;
    $minInt[1] = xtcInt($fileHandleRef) - 4294967296;
    $minInt[2] = xtcInt($fileHandleRef) - 4294967296;
#    printf("Min. int. = %s %s %s\n", $minInt[0], $minInt[1], $minInt[2]);

    $maxInt[0] = xtcInt($fileHandleRef);
    $maxInt[1] = xtcInt($fileHandleRef);
    $maxInt[2] = xtcInt($fileHandleRef);
#    printf("Max. int. = %d %d %d\n", $maxInt[0], $maxInt[1], $maxInt[2]);

    $sizeInt[0] = int($maxInt[0] - $minInt[0] + 1);
    $sizeInt[1] = int($maxInt[1] - $minInt[1] + 1);
    $sizeInt[2] = int($maxInt[2] - $minInt[2] + 1);
#    printf("Size int. = %d %d %d\n", $sizeInt[0], $sizeInt[1], $sizeInt[2]);
    ############################################################################


    ### Check if one of the sizes is too big to be multiplied ##################
    if (($sizeInt[0] | $sizeInt[1] | $sizeInt[2]) > 0xffffff) {
        $bitSizeInt[0] = xtcSizeOfInt($sizeInt[0]);
        $bitSizeInt[1] = xtcSizeOfInt($sizeInt[1]);
        $bitSizeInt[2] = xtcSizeOfInt($sizeInt[2]);
        $bitSize = 0;
#        printf("BitSizeInt = %d %d %d\n", $bitSizeInt[0], $bitSizeInt[1], $bitSizeInt[2]);
    }
    else {
        $bitSize = xtcSizeOfInts(3, \@sizeInt);
#        printf("BitSizeInts = %d\n", $bitSize);
    }
    ############################################################################


    ### Initialize decompression factors #######################################
    my $smallIdx  = xtcInt($fileHandleRef);
    my $smaller   = int($xtcMagicInts[ $FIRSTIDX > $smallIdx - 1 ? $FIRSTIDX : $smallIdx - 1] / 2);
    my $small     = int($xtcMagicInts[ $smallIdx ] / 2);
    my @sizeSmall = ($xtcMagicInts[ $smallIdx ],
                     $xtcMagicInts[ $smallIdx ],
                     $xtcMagicInts[ $smallIdx ]);
    ############################################################################


    ### Fill the buffer ########################################################
    $buf[0] = $buf[1] = $buf[2] = 0;

    $buf[0] = xtcInt($fileHandleRef); # Get the length in bytes (counter).
    xtcData($fileHandleRef, \@{$buf[3]}, int($buf[0]));

    $buf[0] = $buf[1] = $buf[2] = 0; # Reset the counter, last bits & last byte.
    return if $jump;
    ############################################################################


    ### Run through the compressed coordinates #################################
    my $run = 0;
    my $i   = 0;

    while ($i < $lSize)  {
        my (@thisCoord, @prevCoord);

        if ($bitSize == 0) {
            $thisCoord[0] = xtcReceiveBits(\@buf, $bitSizeInt[0]);
            $thisCoord[1] = xtcReceiveBits(\@buf, $bitSizeInt[1]);
            $thisCoord[2] = xtcReceiveBits(\@buf, $bitSizeInt[2]);
        }
        else {
            xtcReceiveInts(\@buf, 3, $bitSize, \@sizeInt, \@thisCoord);
        }
        $i++;

        $thisCoord[0] += $minInt[0];
        $thisCoord[1] += $minInt[1];
        $thisCoord[2] += $minInt[2];

        $prevCoord[0] = $thisCoord[0];
        $prevCoord[1] = $thisCoord[1];
        $prevCoord[2] = $thisCoord[2];


        my $flag = xtcReceiveBits(\@buf, 1);
        $isSmaller = 0;
        if ($flag == 1) {
            $run = xtcReceiveBits(\@buf, 5);
            $isSmaller = $run % 3;
            $run -= $isSmaller;
            $isSmaller--;
        }

        if ($run > 0) {
            for (my $k=0; $k<$run; $k+=3) {
                xtcReceiveInts(\@buf, 3, $smallIdx, \@sizeSmall, \@thisCoord);
                $i++;
                $thisCoord[0] += $prevCoord[0] - $small;
                $thisCoord[1] += $prevCoord[1] - $small;
                $thisCoord[2] += $prevCoord[2] - $small;

                if ($k == 0) {
                    my $tmp = $thisCoord[0];
                    $thisCoord[0] = $prevCoord[0];
                    $prevCoord[0] = $tmp;

                    $tmp = $thisCoord[1];
                    $thisCoord[1] = $prevCoord[1];
                    $prevCoord[1] = $tmp;

                    $tmp = $thisCoord[2];
                    $thisCoord[2] = $prevCoord[2];
                    $prevCoord[2] = $tmp;

                    my %tmpHash = ('cooX' => $prevCoord[0] * $invPrecision,
                                   'cooY' => $prevCoord[1] * $invPrecision,
                                   'cooZ' => $prevCoord[2] * $invPrecision);
                    push(@{$atomsRef}, \%tmpHash);
                }
                else {
                    $prevCoord[0] = $thisCoord[0];
                    $prevCoord[1] = $thisCoord[1];
                    $prevCoord[2] = $thisCoord[2];
                }

                my %tmpHash = ('cooX' => $thisCoord[0] * $invPrecision,
                               'cooY' => $thisCoord[1] * $invPrecision,
                               'cooZ' => $thisCoord[2] * $invPrecision);
                push(@{$atomsRef}, \%tmpHash);
            }
        }
        else {
            my %tmpHash = ('cooX' => $thisCoord[0] * $invPrecision,
                           'cooY' => $thisCoord[1] * $invPrecision,
                           'cooZ' => $thisCoord[2] * $invPrecision);
            push(@{$atomsRef}, \%tmpHash);
        }
        $smallIdx += $isSmaller;
        if ($isSmaller < 0) {
#            printf("%6.2f%%\r", $i/$lSize*100); # Best position for status report (fastest runtime).
            $small = $smaller;
            if ($smallIdx > $FIRSTIDX) {
                $smaller = int($xtcMagicInts[$smallIdx - 1] / 2);
            }
            else {
                $smaller = 0;
            }
        }
        elsif ($isSmaller > 0) {
            $smaller = $small;
            $small = int($xtcMagicInts[$smallIdx] / 2);
        }
        $sizeSmall[0] = $sizeSmall[1] = $sizeSmall[2] = $xtcMagicInts[$smallIdx];
    }
    ############################################################################
#    print "100.00%%\n";

    return 1;
}



sub fread {
    my $arrayRef      = shift;
    my $size          = shift;
    my $count         = shift;
    my $fileHandleRef = shift;

    for (my $i=0; $i<$count; $i++) {
        my $tmpStr;
        sysread(*{$fileHandleRef}, $tmpStr, $size);
        $$arrayRef[$i] = unpack("C*", $tmpStr);
    }
    return scalar(@{$arrayRef});
}




sub openXtcFile {
    my $xtcFile = shift;
    my $modeId  = shift;
    return if $modeId && $modeId > 2;
    return if $modeId && $modeId < 0;
    $modeId = 0 unless $modeId;

    return unless sysopen(XTCHANDLE, $xtcFile, $modeId) || die "ERROR: Cannot open XTC file \"$xtcFile\": $!\n";
    return \*XTCHANDLE;
}



sub closeXtcFile {
    my $fileHandleRef = shift;
    return close(*{$fileHandleRef});
}

1;
