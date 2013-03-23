sub cmdlineparser {
    my $paramsRef = shift;

    for (my $argID=0; $argID<@ARGV; $argID++) {

        foreach my $paramKey (keys %{$paramsRef}) {
            my $paramName = $paramKey;
            my $paramType = 0;
            my $paramIni = "--";
            my $isArray = 0;

            if($paramKey =~ /^(.+?)=([\@f])$/) {
                $paramName = $1;
                $paramType = $2;
            }

            if(length($paramName) == 1) {
                $paramIni = "-";
            }

            if($paramType eq "@") {
                $isArray = 1;
            }
            elsif($paramType eq "f") {
                if($ARGV[$argID] eq $paramIni.$paramName) {
                    if (ref(${$paramsRef}{$paramKey}) eq "SCALAR") {
                        ${${$paramsRef}{$paramKey}} = 1;
                    }
                    elsif (ref(${$paramsRef}{$paramKey}) eq "CODE") {
                        &{${$paramsRef}{$paramKey}}();
                    }
                }
                next;
            }

            if($ARGV[$argID] eq $paramIni.$paramName and not $isArray) {
                ${${$paramsRef}{$paramKey}} = $ARGV[$argID+1];
            }
            elsif($ARGV[$argID] eq $paramIni.$paramName and $isArray) {
#                 print "Multiple Files into an Array\n";
                $argID++;
                my @tmpArray;
                while ($argID <= $#ARGV and not $ARGV[$argID] =~ /^--/ and not $ARGV[$argID] =~ /^-.$/) {
#                    print $ARGV[$argID]."\n";
                    push (@tmpArray, $ARGV[$argID]);
                    $argID++;
                }
                @{${$paramsRef}{$paramKey}} = @tmpArray;
                $argID--;
            }
        }
    }
}

1;
