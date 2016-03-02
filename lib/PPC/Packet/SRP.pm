package PPC::Packet::SRP;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

use PPC::Packet;
use Time::HiRes qw( usleep tv_interval );
use Net::Frame::Layer::ARP qw( :consts );

use Exporter;

our @EXPORT = qw( srp );

our @ISA = qw( PPC PPC::Packet Exporter );

########################################################

sub new {
    shift @_;
    srp(@_);
}

sub srp {
    my %params = (
        callback => 'srp_match',
        continue => 1,
        count    => 1,
        delay    => 0,
        detail   => undef,
        device   => $PPC::PPC_GLOBALS->{device},
        filter   => '',
        number   => 1,
        packet   => undef,
        snaplen  => 68,
        timeout  => 2,
        verbose  => 0
    );

    if (    defined( $PPC::PPC_GLOBALS->{interface} )
        and defined( $PPC::PPC_GLOBALS->{interface}->mtu ) ) {
        $params{snaplen} = $PPC::PPC_GLOBALS->{interface}->mtu;
    }

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) {
            PPC::_help( __PACKAGE__,
                "COMMANDS/srp - send and receive packets" );
        }
        ( $params{packet} ) = $arg;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $params{packet} = shift;
        }
        my %args = @_;
        for ( keys(%args) ) {
            if (/^-?call(?:back)?$/i) {
                if ( $args{$_} !~ /^PPC::/ ) {
                    $params{callback} = "PPC::" . $args{$_};
                } else {
                    $params{callback} = $args{$_};
                }
            } elsif (/^-?cont(?:inue)?$/i) {
                $params{continue} = $args{$_};
            } elsif (/^-?count$/i) {
                if ( ( $args{$_} !~ /^(?:\-)?\d+$/ ) or ( $args{$_} == 0 ) ) {
                    warn
                      "Invalid count `$args{$_}' - using $params{count}\n";
                } else {
                    $params{count} = $args{$_};
                }
            } elsif (/^-?delay$/i) {
                if (   ( $args{$_} !~ /^[0-9]*\.?[0-9]+$/ )
                    or ( $args{$_} < 0 ) ) {
                    warn
                      "Invalid delay `$args{$_}' - using $params{delay}\n";
                } else {
                    $params{delay} = $args{$_};
                }
            } elsif (/^-?detail$/i) {
                if ( $args{$_} !~ /^\d$/ ) {
                    warn
                      "Invalid detail `$args{$_}' - using default\n";
                } else {
                    $params{detail} = $args{$_};
                }
            } elsif (/^-?device$/i) {
                $params{device} = $args{$_};
                if ( !_testpcap( $params{device} ) ) { return }
            } elsif (/^-?filter$/i) {
                $params{filter} = $args{$_};
            } elsif (/^-?num(?:ber)?$/i) {
                if ( $args{$_} !~ /^\d+$/ ) {
                    warn
                      "Invalid number `$args{$_}' - using $params{number}\n";
                } else {
                    $params{number} = $args{$_};
                }
            } elsif (/^-?packet$/i) {
                $params{packet} = $args{$_};
            } elsif (/^-?snap(?:len)?$/i) {
                $params{snaplen} = $args{$_};
            } elsif (/^-?time(?:out)?$/i) {
                if ( ( $args{$_} !~ /^\d+$/ ) or ( $args{$_} <= 0 ) ) {
                    warn
                      "Invalid timeout `$args{$_}' - using $params{timeout}\n";
                } else {
                    $params{timeout} = $args{$_};
                }
            } elsif (/^-?verbose$/i) {
                $params{verbose} = 1;
            } else {
                PPC::_error( "Unknown parameter: `$_'" );
            }
        }
    }

    if ( !defined wantarray ) {
        $params{detail} = defined $params{detail} ? $params{detail} : 1;
    } else {
        $params{detail} = $params{detail} || 0;
    }

    if ( !PPC::Packet::_send_check_params( \%params ) ) {
        return;
    }

    if ( !defined( &{$params{callback}} ) ) {
        PPC::_error( "Callback does not exist - `$params{callback}'" );
    }

    my @pa;
    if ( ref $params{packet} eq "ARRAY" ) {
        @pa = map { $_ } @{$params{packet}};
    } else {
        push @pa, $params{packet};
    }

    my $pcapsend = PPC::Packet::_send_pcap_open( $params{device} );
    if ( !$pcapsend ) {
        return;
    }

    # recv
    my $err;
    my $pcaprecv
      = Net::Pcap::pcap_open_live( $params{device}, $params{snaplen}, 1,
        $params{timeout} * 500, \$err );
    if ( !defined $pcaprecv ) {
        PPC::_error( "Cannot open recv device - `$params{device}': $err" );
    }
    if ( $params{filter} ne '' ) {
        if (!defined(
                _sniff_filter(
                    $pcaprecv,       $params{device},
                    $params{filter}, $params{continue}
                )
            )
          ) {
            return;
        }
    }
    if ( $^O eq 'MSWin32' ) {
        Net::Pcap::pcap_setmintocopy( $pcaprecv, 1 );
    }

    # Ctrl-C
    my $STOP = 0;
    local $SIG{'INT'} = sub {
        $STOP = 1;
        print "\nStopped by user\n";
    };

    my @ret;
    my $sent  = 0;
    my $count = 0;
    $| = 1;
    while ( $count != $params{count} ) {
        last if ($STOP);
        for my $pk (@pa) {
            last if ($STOP);

            # send
            $pk = PPC::Packet::_send_pack_packet(\$pk);

            if ( Net::Pcap::pcap_sendpacket( $pcapsend, $pk->raw ) != 0 ) {
                my $err = sprintf "Error sending the packet: %s\n",
                  Net::Pcap::pcap_geterr($pcapsend);
                warn $err;
            } else {
                if ( $params{detail} ) {
                    print "Sent";
                    if ( $params{detail} > 1 ) {
                        print "\n" . $pk->print . "\n";
                    } else {
                        print " => ";
                    }
                }
            }

            # recv
            my $match = 0;
            my @recv;
            my ( $recv, $recv_r );
            my %header;
            my $starttime = time;
            while (1) {
                last if ($STOP);
                my $ret
                  = Net::Pcap::pcap_next_ex( $pcaprecv, \%header, \$recv_r );
                if ( $ret == 1 ) {
                    $recv = PPC::Packet->new(
                        raw        => $recv_r,
                        firstLayer => 'ETH'
                    );
                    no strict 'refs';
                    if ( &{$params{callback}}( $pk, $recv ) ) {
                        push @recv, $recv;
                        print "Received " if ($params{detail});
                        $match++;
                        if ( $params{detail} > 1 ) {
                            print "\n";
                            if ( $params{number} > 1 ) {
                                print "$match:\n";
                            }
                            print $recv->print . "\n";
                        }
                        last if ( $match == $params{number} );
                    }
                } elsif ( $ret == 0 ) {
                    print "[Receive Timeout] " if ($params{detail});
                    last;
                } else {
                    print "[Receive Error] " if ($params{detail});
                    last;
                }

                # Need to track time and timeout ourselves as PCAP timeout is
                # timeout *between* packets and is reset once a packet is seen
                if ( ( time - $starttime ) >= ( $params{timeout} ) ) {
                    print "[Receive Timeout] " if ($params{detail});
                    last;
                }
            }

            my %sr;
            $sr{sent} = $pk;

            if ($match) {
                $sr{recv} = \@recv;
            } else {
                $sr{recv} = undef;
            }
            push @ret, \%sr;

            print "\n" if ($params{detail});
            usleep $params{delay} * 1000000;
        }
        $count++;
    }
    Net::Pcap::pcap_close($pcapsend);
    Net::Pcap::pcap_close($pcaprecv);

    return bless \@ret, __PACKAGE__;
}

sub srp_match {
    my ( $s, $r ) = @_;

    # Never match packets with same MAC source (from yourself)
    if ( defined( $s->ref->{ETH} ) and defined( $r->ref->{ETH} ) ) {
        if ( $s->ref->{ETH}->src eq $r->ref->{ETH}->src ) {
            return 0;
        }
    }

    # ARP
    if ( defined( $s->ref->{ARP} ) and defined( $r->ref->{ARP} ) ) {
        if ( $r->ref->{ARP}->opCode == NF_ARP_OPCODE_REPLY ) {
            if ( $s->ref->{ARP}->dstIp eq $r->ref->{ARP}->srcIp ) {
                return 1;
            }
        }

        # ICMPv4
    } elsif ( defined( $s->ref->{ICMPv4} ) and defined( $r->ref->{ICMPv4} ) )
    {

        # ICMPv4 replies
        if ($s->ref->{ICMPv4}->match( $r->ref->{ICMPv4} )
            or

            # ICMPv4 errors
            (       ( $s->ref->{ICMPv4}->type == $r->ref->{ICMPv4}->type )
                and ( $s->ref->{ICMPv4}->code == $r->ref->{ICMPv4}->code )
            )
          ) {

            my @icmpTypes
              = qw(ICMPv4::Echo ICMPv4::AddressMask ICMPv4::Information ICMPv4::Timestamp);
            for my $it (@icmpTypes) {
                if ( defined( $s->ref->{$it} ) and defined( $r->ref->{$it} ) )
                {
                    if ((   $s->ref->{$it}->identifier
                            == $r->ref->{$it}->identifier
                        )
                        and ( $s->ref->{$it}->sequenceNumber
                            == $r->ref->{$it}->sequenceNumber )
                      ) {
                        return 1;
                    }
                }
            }
        }

        # ICMPv6
    } elsif ( defined( $s->ref->{ICMPv6} ) and defined( $r->ref->{ICMPv6} ) )
    {

        # ICMPv6 replies
        if ($s->ref->{ICMPv6}->match( $r->ref->{ICMPv6} )
            or

            # ICMPv6 errors
            (       ( $s->ref->{ICMPv6}->type == $r->ref->{ICMPv6}->type )
                and ( $s->ref->{ICMPv6}->code == $r->ref->{ICMPv6}->code )
            )
          ) {

            my @icmpTypes
              = qw(ICMPv6::Echo ICMPv6::NeighborSolicitation ICMPv6::NeighborAdvertisement ICMPv6::RouterSolicitation ICMPv6::RouterAdvertisement);
            for my $it (@icmpTypes) {
                if ( defined( $s->ref->{$it} ) and defined( $r->ref->{$it} ) )
                {
                    if ((   $s->ref->{$it}->identifier
                            == $r->ref->{$it}->identifier
                        )
                        and ( $s->ref->{$it}->sequenceNumber
                            == $r->ref->{$it}->sequenceNumber )
                      ) {
                        return 1;
                    }
                }
            }

            # MLD matches not in the module
        } elsif ( ( $s->ref->{ICMPv6}->type == 130 )
            and ( $r->ref->{ICMPv6}->type == 131 ) ) {
            return 1;
        }

        # TCP
    } elsif ( defined( $s->ref->{TCP} ) and defined( $r->ref->{TCP} ) ) {
        if ( $s->ref->{TCP}->getKey eq $r->ref->{TCP}->getKeyReverse ) {
            return 1

              # ICMP error (unreach, exceed ...)
        } elsif ( defined( $r->ref->{ICMPv4} )
            and ( $s->ref->{TCP}->getKey eq $r->ref->{TCP}->getKey ) ) {
            return 1;
        } elsif ( defined( $r->ref->{ICMPv6} )
            and ( $s->ref->{TCP}->getKey eq $r->ref->{TCP}->getKey ) ) {
            return 1;
        }

        # UDP
    } elsif ( defined( $s->ref->{UDP} ) and defined( $r->ref->{UDP} ) ) {

        # normal
        if ( $s->ref->{UDP}->getKey eq $r->ref->{UDP}->getKeyReverse ) {
            return 1

              # ICMP error (unreach, exceed ...)
        } elsif ( defined( $r->ref->{ICMPv4} )
            and ( $s->ref->{UDP}->getKey eq $r->ref->{UDP}->getKey ) ) {
            return 1;
        } elsif ( defined( $r->ref->{ICMPv6} )
            and ( $s->ref->{UDP}->getKey eq $r->ref->{UDP}->getKey ) ) {
            return 1;
        }
    }

    return 0;
}

sub list {
    my ( $self, $arg ) = @_;

    if ( defined($arg) and ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) ) {
        PPC::_help( __PACKAGE__,
            "ACCESSORS/list - return list of all sent and recv packets" );
    }

    my @rets;
    my $retType = wantarray;

    for my $i ( 0 .. $#{$self} ) {
        if ( defined $retType ) {
            push @rets, $self->[$i]->{sent};
        } else {
            print $self->[$i]->{sent} . "\n";
        }
        if ( defined $self->[$i]->{recv} ) {
            for my $j ( 0 .. $#{$self->[$i]->{recv}} ) {
                if ( defined $retType ) {
                    push @rets, $self->[$i]->{recv}[$j];
                } else {
                    print $self->[$i]->{recv}[$j] . "\n";
                }
            }
        }
    }

    if ( !defined $retType ) {
        return;
    } elsif ($retType) {
        return @rets;
    } else {
        return \@rets;
    }
}

sub listr {
    return listrecv(@_);
}

sub listrecv {
    my ( $self, $arg ) = @_;

    if ( defined($arg) and ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "ACCESSORS/listrecv - return list of all received packets" );
    }

    my @rets;
    my $retType = wantarray;

    for my $i ( 0 .. $#{$self} ) {
        if ( defined $self->[$i]->{recv} ) {
            for ( @{$self->[$i]->{recv}} ) {
                if ( defined $retType ) {
                    push @rets, $_;
                } else {
                    print "$_\n";
                }
            }
        }
    }

    if ( !defined $retType ) {
        return;
    } elsif ($retType) {
        return @rets;
    } else {
        return \@rets;
    }
}

sub lists {
    return listsent(@_);
}

sub listsent {
    my ( $self, $arg ) = @_;

    if ( defined($arg) and ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "ACCESSORS/listsent - return list of all sent packets" );
    }

    my @rets;
    my $retType = wantarray;

    for my $i ( 0 .. $#{$self} ) {
        if ( defined $retType ) {
            push @rets, $self->[$i]->{sent};
        } else {
            print $self->[$i]->{sent} . "\n";
        }
    }

    if ( !defined $retType ) {
        return;
    } elsif ($retType) {
        return @rets;
    } else {
        return \@rets;
    }
}

sub listt {
    return listtime(@_);
}

sub listtime {
    my ( $self, $arg ) = @_;

    if ( defined($arg) and ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "ACCESSORS/listtime - return list of all time intervals" );
    }

    my @rets;
    my $retType = wantarray;

    for my $i ( 0 .. $#{$self} ) {
        if ( defined $self->[$i]->{recv} ) {
            for my $j ( 0 .. $#{$self->[$i]->{recv}} ) {
                my $time = tv_interval(
                    [split /\./, $self->[$i]->{sent}->timestamp],
                    [split /\./, $self->[$i]->{recv}[$j]->timestamp]
                  );
                if ( defined $retType ) {
                    push @rets, $time;
                } else {
                    printf "$time\n";
                }
            }
        }
    }

    if ( !defined $retType ) {
        return;
    } elsif ($retType) {
        return @rets;
    } else {
        return \@rets;
    }
}

sub recv {
    my ( $self, $arg, $arg2 ) = @_;

    if ( defined($arg) and ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) ) {
        PPC::_help( __PACKAGE__,
            "ACCESSORS/recv - return srp received packets" );
    }

    my @rets;
    my $retType = wantarray;

    if ( defined $arg ) {
        if ( $arg =~ /^\d+$/ ) {
            if ( ( $arg > 0 ) and ( $arg <= ( $#{$self} + 1 ) ) ) {
                if ( defined $arg2 ) {
                    if ( $arg2 =~ /^\d+$/ ) {
                        if (    ( $arg2 > 0 )
                            and
                            ( $arg2 <= ( $#{$self->[$arg - 1]->{recv}} + 1 ) )
                          ) {
                            if ( defined $self->[$arg - 1]->{recv} ) {
                                if ( defined $retType ) {
                                    return $self->[$arg - 1]
                                      ->{recv}[$arg2 - 1];
                                } else {
                                    print $self->[$arg - 1]->{recv}[$arg2 - 1]
                                      . "\n";
                                }
                            } else {
                                if ( !defined $retType ) {
                                    _errorNRP( $arg,$arg2 );
                                }
                                return;
                            }
                        } else {
                            if ( !defined $retType ) {
                                PPC::_error(
                                    "Not a valid sent/recv number - `$arg,$arg2'"
                                );
                            }
                            return;
                        }
                    } else {
                        if ( !defined $retType ) {
                            _errorNAN( $arg2 );
                        }
                        return;
                    }
                } else {
                    if ( defined( $self->[$arg - 1]->{recv}[0] ) ) {
                        if ( defined($retType) ) {
                            return $self->[$arg - 1]->{recv}[0];
                        } else {
                            print $self->[$arg - 1]->{recv}[0] . "\n";
                        }
                    } else {
                        if ( !defined $retType ) {
                            _errorNRP( $arg,1 );
                        }
                        return;
                    }
                }
            } else {
                if ( !defined $retType ) {
                    _errorNVPN( $arg );
                }
                return;
            }
        } else {
            if ( !defined $retType ) {
                _errorNAN( $arg );
            }
            return;
        }
    } else {
        for my $i ( 0 .. $#{$self} ) {
            if ( defined $self->[$i]->{recv} ) {
                for my $j ( 0 .. $#{$self->[$i]->{recv}} ) {
                    if ( defined $retType ) {
                        push @rets, $self->[$i]->{recv}[$j];
                    } else {
                        printf "%3i,%-3i: " . $self->[$i]->{recv}[$j] . "\n",
                          $i + 1, $j + 1;
                    }
                }
            } else {
                if ( defined $retType ) {
                    push @rets, undef;
                } else {
                    printf "%3i    : No recv packet\n", $i + 1;
                }
            }
        }
    }

    if ( !defined $retType ) {
        return;
    } elsif ($retType) {
        return @rets;
    } else {
        return \@rets;
    }
}

sub sent {
    my ( $self, $arg ) = @_;

    if ( defined($arg) and ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) ) {
        PPC::_help( __PACKAGE__, "ACCESSORS/sent - return srp sent packets" );
    }

    my @rets;
    my $retType = wantarray;

    if ( defined $arg ) {
        if ( $arg =~ /^\d+$/ ) {
            if ( ( $arg > 0 ) and defined( $self->[$arg - 1] ) ) {
                if ( defined $retType ) {
                    return $self->[$arg - 1]->{sent};
                } else {
                    print $self->[$arg - 1]->{sent} . "\n";
                }
            } else {
                if ( !defined $retType ) {
                    _errorNVPN( $arg );
                }
                return;
            }
        } else {
            if ( !defined $retType ) {
                _errorNAN( $arg );
            }
            return;
        }
    } else {
        my $c = 1;
        for my $i ( 0 .. $#{$self} ) {
            if ( defined $retType ) {
                push @rets, $self->[$i]->{sent};
            } else {
                printf "%3i: %s\n", $c, $self->[$i]->{sent};
            }
            $c++;
        }
    }

    if ( !defined $retType ) {
        return;
    } elsif ($retType) {
        return @rets;
    } else {
        return \@rets;
    }
}

sub time {
    my ( $self, $arg, $arg2 ) = @_;

    if ( defined($arg) and ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) ) {
        PPC::_help( __PACKAGE__,
            "ACCESSORS/time - return delay between sent and recv" );
    }

    my @rets;
    my $retType = wantarray;

    if ( defined $arg ) {
        if ( $arg =~ /^\d+$/ ) {
            if ( ( $arg > 0 ) and ( $arg <= ( $#{$self} + 1 ) ) ) {
                if ( defined $arg2 ) {
                    if ( $arg2 =~ /^\d+$/ ) {
                        if (    ( $arg2 > 0 )
                            and
                            ( $arg2 <= ( $#{$self->[$arg - 1]->{recv}} + 1 ) )
                          ) {
                            if (defined $self->[$arg - 1]->{recv}[$arg2 - 1] )
                            {
                                my $time = tv_interval(
                                    [  split /\./,  $self->[$arg - 1]->{sent}
                                          ->timestamp
                                    ],
                                    [  split /\./,  $self->[$arg - 1]
                                          ->{recv}[$arg2 - 1]->timestamp
                                    ]
                                );
                                if ( defined $retType ) {
                                    return $time;
                                } else {
                                    print "$time\n";
                                }
                            } else {
                                if ( !defined $retType ) {
                                    _errorNRP( $arg,$arg2 );
                                }
                                return;
                            }
                        } else {
                            if ( !defined $retType ) {
                                PPC::_error(
                                    "Not a valid sent/recv number - `$arg,$arg2'"
                                );
                            }
                            return;
                        }
                    } else {
                        if ( !defined $retType ) {
                            _errorNAN( $arg2 );
                        }
                        return;
                    }
                } else {
                    if ( defined $self->[$arg - 1]->{recv}[0] ) {
                        my $time = tv_interval(
                            [split /\./, $self->[$arg - 1]->{sent}->timestamp],
                            [split /\./, $self->[$arg - 1]->{recv}[0]->timestamp]
                        );
                        if ( defined $retType ) {
                            return $time;
                        } else {
                            print "$time\n";
                        }
                    } else {
                        if ( !defined $retType ) {
                            _errorNRP( $arg,1 );
                        }
                        return;
                    }
                }
            } else {
                if ( !defined $retType ) {
                    _errorNVPN( $arg );
                }
                return;
            }
        } else {
            if ( !defined $retType ) {
                _errorNAN( $arg );
            }
            return;
        }
    } else {
        for my $i ( 0 .. $#{$self} ) {
            if ( defined $self->[$i]->{recv} ) {
                for my $j ( 0 .. $#{$self->[$i]->{recv}} ) {
                    my $time = tv_interval(
                        [split /\./, $self->[$i]->{sent}->timestamp],
                        [split /\./, $self->[$i]->{recv}[$j]->timestamp]
                      );
                    if ( defined $retType ) {
                        push @rets, $time;
                    } else {
                        printf "%3i,%-3i: $time\n" , $i + 1, $j + 1;
                    }
                }
            } else {
                if ( defined $retType ) {
                    push @rets, undef;
                } else {
                    printf "%3i    : No time interval\n", $i + 1;
                }
            }
        }
    }

    if ( !defined $retType ) {
        return;
    } elsif ($retType) {
        return @rets;
    } else {
        return \@rets;
    }
}

sub report {
    my ( $self, @args ) = @_;

    my %params = ( file => '' );

    if ( @args == 1 ) {
        my ($arg) = @args;
        if ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) {
            PPC::_help( __PACKAGE__,
                "ACCESSORS/report - srp summary report" );
        }
        ( $params{file} ) = $arg;
    } else {
        if ( ( @args % 2 ) == 1 ) {
            $params{file} = shift @args;
        }
        my %args = @args;
        for ( keys(%args) ) {
            if (/^-?file$/i) {
                $params{file} = $args{$_};
            } else {
                PPC::_error( "Unknown parameter: `$_'" );
            }
        }
    }

    my $OUT;
    if ( $params{file} eq '' ) {
        $OUT = \*STDOUT;
    } else {
        if ( ref $params{file} eq 'GLOB' ) {
            $OUT = $params{file};
        } else {
            if ( !( open( $OUT, '>', "$params{file}" ) ) ) {
                PPC::_error( "Cannot open file - `$params{file}'" );
            }
        }
    }

    for my $i ( 0 .. $#{$self} ) {
        printf $OUT "Packet %i\n", $i + 1;

        printf $OUT "  Sent: %s (%f)\n",
          scalar localtime( $self->[$i]->{sent}->timestamp ),
          $self->[$i]->{sent}->timestamp;
        print $OUT $self->[$i]->{sent}->print . "\n";

        print $OUT "  Recv";
        if ( defined $self->[$i]->{recv} ) {
            for my $r ( 0 .. $#{$self->[$i]->{recv}} ) {
                if ( $#{$self->[$i]->{recv}} > 0 ) {
                    printf $OUT "\n  %4i", $r + 1;
                }
                printf $OUT ": %s (%f)\n",
                  scalar localtime( $self->[$i]->{recv}[$r]->timestamp ),
                  $self->[$i]->{recv}[$r]->timestamp;
                print $OUT $self->[$i]->{recv}[$r]->print . "\n";
                printf $OUT "  Interval = %f secs\n",
                  tv_interval(
                    [ split /\./, $self->[$i]->{sent}->timestamp ],
                    [ split /\./, $self->[$i]->{recv}[$r]->timestamp ]
                  );
            }
        } else {
            print $OUT ": [No recv packet]\n";
        }
        print $OUT "\n";
    }

    if ( $params{file} ne '' ) {
        if ( ref $params{file} ne 'GLOB' ) {
            close $OUT;
        }
    }
}

sub _errorNAN {
    my ( $arg ) = @_;
    PPC::_error( "Not a valid number - `$arg'" );
}

sub _errorNRP {
    my ( $arg1, $arg2 ) = @_;
    PPC::_error( "No recv packet for - `$arg1,$arg2'" );
}

sub _errorNVPN {
    my ( $arg ) = @_;
    PPC::_error( "Not a valid packet number - `$arg'" );
}

1;

__END__

########################################################
# Start POD
########################################################

=head1 NAME

PPC::Packet::SRP - PPC send and receive packets accessors

=head1 SYNOPSIS

 use PPC::Packet;
 use PPC::Packet::SRP;

 $packet = PPC::Packet->new([Net::Frame::Layer::* objects]);
 $ret = srp $srp;

 $ret->list;
 $ret->sent;
 $ret->recv;
 $ret->time;

=head1 DESCRIPTION

SRP provides the send and receive packet capability to B<PPC>.  This builds 
upon the individual send and capture routines in B<PPC::Packet> by providing 
a single command to send a packet and capture replies (if any).  Send and 
received packets are stored as B<PPC::Packet> objects in an object 
structure that can be accessed with accessors from this package.

=head1 COMMANDS

=head2 srp - send and receive packets

 [$srp =] srp [OPTIONS]
 [$srp =] PPC::Packet::SRP->new([OPTIONS]);

Send and receive packets.  Looks for match of sent packet in the receive
capture.  Returns B<PPC::Packet::SRP> object of structure:

 $srp->[count]->{sent}               = PPC::Packet object
              ->{recv}->[number]     = PPC::Packet object or undef

=over 4

=item B<new>

Traditional constructor.  Simply calls B<srp>.

=back

For accessors to the return structure, see B<PPC::SRP>.

  Option     Description                       Default Value
  ------     -----------                       -------------
  callback   Sub to call for packet matching   (see below)
  continue   Continue on error (0 = off)       (yes)
  count      Number of packets to send         1
             negative number = send forever
  delay      Delay between packets sent (secs) 0
             decimal for fractional secs
  detail     Print detail status during        0 if wantarray
             operation (0=off, 1=more, 2=most) 1 if not wantarray
  device     Device to send / recv on          device if defined
  filter     Recv filter                       (allow all)
  number     Number of packets to capture      1
             use 0 to capture until timeout
  packet     $packet, \@packets                (none)
  snaplen    Recv packet length                MTU if "interface" command
                                                 else 68
  timeout    Timeout for recv in seconds       2
  verbose    Show options as set (1 = on)      (off)

Single option indicates B<packet>.

Callback is a sub to call to determine if a received packet matches the
current sent packet.  Provided subs are:

=over 4

=item B<srp_match>

Attempts to match ARP, ICMPv4/v6, TCP, UDP.  This is the default.

=back

A custom callback sub can be defined from within the shell and called.
Callback input is both the current send packet and the current receive
packet both as B<PPC::Packet> objects.  Callbacks are in the form:

  sub SUB_NAME {
      my ($send, $recv) = @_;

      ...
      if MATCH
        return 1
      else
        return 0
  }

=head1 ACCESSORS

=head2 list - return list of all sent and recv packets

 [@list = ] $srp->list;

Print list of all sent / recv packets in chronological order.  Optional 
return value is list of B<PPC::Packet> objects.

=head2 listrecv - return list of all received packets

 [@list =] $srp->listrecv

Return array of all received packets B<PPC::Packet> objects resultant.  
The list is ordered in the order received.  If any packets weren't received, 
they are skipped.  There will be no undefined values in the returned array.

Alias:

=over 4

=item B<listr>

=back

=head2 listsent - return list of all sent packets

 [@list =] $srp->listsent

Return array of all sent packets B<PPC::Packet> objects resultant.  
The list is ordered in the order sent.  There will be no undefined values in 
the returned array.

Alias:

=over 4

=item B<lists>

=back

=head2 listtime - return list of all time intervals

 [@list =] $srp->listtime

Return array of all time intervals between sent and received packets 
B<PPC::Packet> objects resultant.  The list is ordered in the 
order sent and received.  If any packets weren't received, the time 
interval is not provided and skipped.  There will be no undefined values 
in the returned array.

Alias:

=over 4

=item B<listt>

=back

=head2 recv - return srp received packets

 [$ret =] $srp->recv([# [,#]])

Return array of all received packets.  Optional number returns only that 
received packet.  Packets are numbered 1 .. {last packet}.  If B<number> 
option was used when B<srp> was called, second optional number specifies 
the received packet for the B<srp> group.

=head2 sent - return srp sent packets

 [$ret =] $srp->sent([#])

Return array of all sent packets.  Optional number returns only that
sent packet.  Packets are numbered 1 .. {last packet}.

=head2 time - return delay between sent and recv

 [$ret =] $srp->time([# [,#]])

Return array of all time intervals between sent and received packets.  
Optional number returns only time interval for sent packet number and 
first received packet.  Packets are numbered 1 .. {last packet}.  If 
B<number> option was used when B<srp> was called, second optional number 
specifies time interval for the sent to the received packet for the 
B<srp> group.

=head2 report - srp summary report

 $srp->report([OPTIONS])

Print summary report of all sent/received packets and timestamps.

  Option     Description                       Default Value
  ------     -----------                       -------------
  file       Output file name or handle        (none - STDOUT)

Single option indicates file.

=head1 SEE ALSO

L<PPC::Packet>

=head1 ACKNOWLEDGEMENTS

Special thanks to Patrice E<lt>GomoRE<gt> Auffret without whose
Net::Frame::[...] modules, this would not be possible.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2012, 2016 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
