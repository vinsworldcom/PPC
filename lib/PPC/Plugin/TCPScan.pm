package PPC::Plugin::TCPScan;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

use PPC::Plugin;
use PPC::Packet::SRP;
use PPC::Plugin::TCPFlags;

use Time::HiRes qw( tv_interval );
use Net::Frame::Layer qw( :subs );
use Net::Frame::Layer::IPv4 qw( :consts );
use Net::Frame::Layer::TCP  qw( :consts );
my $HAVE_NFL_IPv6 = 0;
eval "use Net::Frame::Layer::IPv6 qw( :consts )";
if ( !$@ ) {
    $HAVE_NFL_IPv6 = 1;
}

use constant TCPSCAN_INTERESTING => qw(
  7 9 11 13 17 19 20 21 22 23 25 37 42 43 53 70 79 80 81 88 101 102 107 109
  110 111 113 117 118 119 135 137 139 143 150 156 158 170 179 194 322 349
  389 443 445 464 507 512 513 514 515 520 522 526 529 530 531 532 540 543
  544 546 547 548 554 556 563 565 568 569 593 612 613 636 666 691 749 800
  989 990 992 993 994 995 1109 1110 1155 1034 1270 1433 1434 1477 1478 1512
  1524 1607 1711 1723 1731 1745 1755 1801 1863 1900 1944 2053 2106 2177 2234
  2382 2383 2393 2394 2460 2504 2525 2701 2702 2703 2704 2725 2869 3020 3074
  3126 3132 3268 3269 3306 3343 3389 3535 3540 3544 3587 3702 3776 3847 3882
  3935 4350 4500 5355 5357 5358 5678 5679 5720 6073 9535 9753 11320 47624
);
use constant TCPSCAN_LOW => ( 1 .. 1023 );
use constant TCPSCAN_ALL => ( 1 .. 65535 );
use constant TCPSCAN_DEFAULT => qw( 22 23 80 );

use Exporter;

our @EXPORT = qw (
  TCPScan
  tcpscan
);

our @ISA = qw ( PPC::Plugin PPC::Packet::SRP Exporter );

sub TCPScan {
    PPC::_help_full( __PACKAGE__ );
}

########################################################

sub tcpscan {
    my %scanType = (
        SYN    => NF_TCP_FLAGS_SYN,
        ACK    => NF_TCP_FLAGS_ACK,
        SYNACK => NF_TCP_FLAGS_SYN | NF_TCP_FLAGS_ACK,
        FIN    => NF_TCP_FLAGS_FIN,
        XMAS   => NF_TCP_FLAGS_FIN | NF_TCP_FLAGS_URG | NF_TCP_FLAGS_PSH
    );

    my %params = (
        count   => 1,
        delay   => 0,
        family  => 4,
        number  => 1,
        packet  => undef,
        port    => [TCPSCAN_DEFAULT],
        random  => 1,
        scan    => $scanType{SYN},
        target  => undef,
        timeout => 2,
        verbose => 0
    );

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__, "SUBROUTINES/tcpscan - TCP scan" );
        }
        ( $params{target} ) = $arg;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $params{target} = shift;
        }
        my %args = @_;
        for ( keys(%args) ) {
            if (/^-?count$/i) {
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
            } elsif (/^-?family$/i) {
                if (!defined(
                        my $ret = PPC::Plugin::_validate_family( $args{$_} )
                    )
                  ) {
                    warn
                      "Invalid family `$args{$_}' - using $params{family}\n";
                } else {
                    $params{family} = $ret;
                }
            } elsif (/^-?num(?:ber)?$/i) {
                if ( $args{$_} =~ /^\d+$/ ) {
                    $params{number} = $args{$_};
                } else {
                    warn
                      "Invalid number `$args{$_}' - using $params{number}\n";
                }
            } elsif (/^-?packet$/i) {
                if (   ( ref( $args{$_} ) eq 'PPC::Packet' )
                    or ( ref( $args{$_} ) eq 'HASH' ) ) {
                    $params{packet} = $args{$_};
                } else {
                    warn "Not a valid object type for packet arg - using default\n";
                }
            } elsif (/^-?port(?:s)?$/i) {
                if ( ref( $args{$_} ) eq 'ARRAY' ) {
                    my $OK = 1;
                    for my $port ( @{$args{$_}} ) {
                        if (   ( $port !~ /^\d{1,5}$/ )
                            or ( $port < 0 )
                            or ( $port > 65535 ) ) {
                            warn
                              "Invalid port `$port' in `@{$args{$_}}' - using default\n";
                            $OK = 0;
                            last;
                        }
                    }
                    if ($OK) {
                        $params{port} = $args{$_};
                    }
                } else {
                    if (   ( $args{$_} !~ /^\d{1,5}$/ )
                        or ( $args{$_} < 0 )
                        or ( $args{$_} > 65535 ) ) {
                        warn "Invalid port `$args{$_}' - using default\n";
                    } else {
                        $params{port} = [$args{$_}];
                    }
                }
            } elsif (/^-?rand(?:om)?$/i) {
                $params{random} = $args{$_};
            } elsif (/^-?scan(?:type)?$/i) {
                if ( exists $scanType{uc( $args{$_} )} ) {
                    $params{scan} = $scanType{uc( $args{$_} )};
                } elsif ( ( $args{$_} =~ /^\d+$/ )
                    and ( $args{$_} >= 0 )
                    and ( $args{$_} <= 255 ) ) {
                    $params{scan} = $args{$_};
                } else {
                    warn
                      "Invalid scantype `$args{$_}' - using $params{number}\n";
                }
            } elsif (/^-?target$/i) {
                $params{target} = $args{$_};
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

    if ( $params{random} ) {
        _fisher_yates_shuffle( $params{port} );
    }

    if ( $params{verbose} ) {
        for ( sort( keys(%params) ) ) {
            if ( $_ eq 'port' ) {
                printf "%-15s => [ ", $_;
                print "$_ " for ( @{$params{$_}} );
                print "]\n";
            } elsif ( $_ eq 'scan' ) {
                my %RscanType = reverse %scanType;
                if ( exists( $RscanType{$params{scan}} ) ) {
                    printf "%-15s => %s\n", $_, $RscanType{$params{scan}};
                } else {
                    printf "%-15s => Flags 0x%02x\n", $_, $params{scan};
                }
            } else {
                printf "%-15s => %s\n", $_,
                  defined( $params{$_} ) ? $params{$_} : '[undef]';
            }
        }
        print "\n";
    }

    if ( !defined $params{target} ) {
        PPC::_error( "No target" );
    }

    my @layers;
    if (    ( defined $params{packet} ) 
        and ( ref( $params{packet} ) eq 'PPC::Packet' ) ) {
        my $raw = PPC::decode( $params{packet} );
        for ( $raw->layers ) {
            push @layers, $_;
        }
        if ( ref( $layers[2] ) !~ /^Net::Frame::Layer::TCP/ ) {
            PPC::_error( "Not TCP in packet option" );
        }
        $layers[1]->dst( $params{target} );
    } else {
        if ( $params{family} == 4 ) {
            if (!(      PPC::Macro::MAC_GW()
                    and PPC::Macro::MAC_SRC()
                    and PPC::Macro::IPv4_SRC()
                )
              ) {
                PPC::_error( "Run `interface' command first" );
            }
            if ( !( $params{target} = getHostIpv4Addr( $params{target} ) ) ) {
                return;
            }

            $layers[0] = PPC::Layer::ETHER();
            $layers[1] = PPC::Layer::IPv4(
                dst      => $params{target},
                protocol => NF_IPv4_PROTOCOL_TCP
            );
        } else {
            if (!(      PPC::Macro::MAC6_GW()
                    and PPC::Macro::MAC_SRC()
                    and PPC::Macro::IPv6_SRC()
                )
              ) {
                PPC::_error( "Run `interface' command first" );
            }
            if ( !( $params{target} = getHostIpv6Addr( $params{target} ) ) ) {
                return;
            }

            $layers[0] = PPC::Layer::ETHER6();
            $layers[1] = PPC::Layer::IPv6(
                dst        => $params{target},
                nextHeader => 6 #NF_IPv6_PROTOCOL_TCP
            );
        }
        $layers[2] = PPC::Layer::TCP( flags => $params{scan} );
    }

    my %attrs;
    if (    ( defined $params{packet} ) 
        and ( ref $params{packet} eq 'HASH' ) ) {
        %attrs = %{$params{packet}};
    }

    # Ctrl-C
    my $STOP = 0;
    local $SIG{'INT'} = sub {
        $STOP = 1;
    };

    print  "TCP Scan target :  $params{target}\n";
    printf "Scan %4i ports :  ", $#{$params{port}}+1;
    print join " ", @{$params{port}};
    print "\n";
    my @scan;
    for my $port ( @{$params{port}} ) {
        if ($STOP) { last }

        $params{packet} = PPC::Packet::packet( @layers );

        for my $attr ( keys ( %attrs ) ) {
            $params{packet}->$attr($attrs{$attr});
            $params{packet}->pack;
        }

        $layers[2]->dst($port);
        $params{packet}->pack;

        my $group = PPC::Packet::SRP::srp(
            $params{packet},
            count   => $params{count},
            delay   => $params{delay},
            timeout => $params{timeout},
            number  => $params{number}
        );

        for my $c ( 1 .. $params{count} ) {
            for my $n ( 1 .. $params{number} ) {
                if ( defined $group->recv( $c, $n ) ) {
                    my $l3 = [$group->recv( $c, $n )->layers]->[2]->print;
                    my $time = tv_interval(
                        [ split /\./, $group->sent($c)->timestamp ],
                        [ split /\./, $group->recv( $c, $n )->timestamp ]
                    );
                    printf "Port %5i\t(%s secs)\n%s\n\n", $port, $time, $l3;
                } else {
                    printf "Port %5i\t%-20s\n\n", $port,
                      "[Request timed out]";
                }
            }
        }
        push @scan, $group;
    }

    return bless \@scan, __PACKAGE__;
}

#http://www.perlmonks.org/?node_id=1869
sub _fisher_yates_shuffle {
    my $array = shift;
    my $i     = @$array;
    while ( --$i ) {
        my $j = int rand( $i + 1 );
        @$array[$i, $j] = @$array[$j, $i];
    }
}

1;

__END__

=head1 NAME

TCPScan - TCP Scan

=head1 SYNOPSIS

 use PPC::Plugin::TCPScan;

 $scan = tcpscan 'target' [OPTIONS];
 $scan->sent([#]);
 $scan->recv([#]);
 $scan->report;

=head1 DESCRIPTION

This module provides the B<PPC> B<tcpscan> command and the accessors for the 
return structure of the B<PPC> B<tcpscan> command.

=head1 COMMANDS

=head2 TCPScan - provide help

Provides help from the B<PPC> shell.

=head1 SUBROUTINES

=head2 tcpscan - TCP scan

 [$scan =] tcpscan 'target' [OPTIONS]

The TCP scan command.  Uses B<srp> for the sending / receiving.  Returns 
structure:

 $scan->[group_number] = PPC::Packet::SRP object

For accessors to the return structure, see B<ACCESSORS>.

  Option     Description                        Default Value
  ------     -----------                        -------------
  count      Number of packets to send / group  1
  delay      Delay between packets sent (secs)  0
               decimal for fractional secs
  family     Address family IPv4/IPv6           IPv4
               Valid values for IPv4:
                 4, v4, ip4, ipv4
               Valid values for IPv6:
                 6, v6, ip6, ipv6
  number     Number of packets to capture       1
             use 0 to capture until timeout
  packet     $packet template to use            (none)
               or hash of attributes, e.g.,
               {tos1=>184,ttl1=>52}
  port       Ports to scan                      TCPSCAN_DEFAULT
  random     Randomize port list (0 = off)      (on)
  scan       Scan type                          SYN
               Valid values:
                 syn, ack, synack, fin, xmas
  target     Target                             (none)
  timeout    Timeout for recv in seconds        2
  verbose    Show options as set (1 = on)       (off)

Single option indicates B<target>.

=head1 ACCESSORS

Inherited from B<PPC::Plugin>.

=head1 CONSTANTS

=over 4

=item B<TCPSCAN_INTERESTING>

Ports:  7 9 11 13 17 19 20 21 22 23 25 37 42 43 53 70 79 80 81 88 101 102 107 109 110 111 113 117 118 119 135 137 139 143 150 156 158 170 179 194 322 349 389 443 445 464 507 512 513 514 515 520 522 526 529 530 531 532 540 543 544 546 547 548 554 556 563 565 568 569 593 612 613 636 666 691 749 800 989 990 992 993 994 995 1109 1110 1155 1034 1270 1433 1434 1477 1478 1512 1524 1607 1711 1723 1731 1745 1755 1801 1863 1900 1944 2053 2106 2177 2234 2382 2383 2393 2394 2460 2504 2525 2701 2702 2703 2704 2725 2869 3020 3074 3126 3132 3268 3269 3306 3343 3389 3535 3540 3544 3587 3702 3776 3847 3882 3935 4350 4500 5355 5357 5358 5678 5679 5720 6073 9535 9753 11320 47624

=item B<TCPSCAN_LOW>

All ports:  1 .. 1023

=item B<TCPSCAN_ALL>

All ports:  1 .. 65535

=item B<TCPSCAN_DEFAULT>

All ports:  22, 23, 80

=back

=head1 SEE ALSO

L<PPC::Plugin>, L<PPC::Packet::SRP>

=head1 ACKNOWLEDGEMENTS

Special thanks to Patrice E<lt>GomoRE<gt> Auffret without whose 
Net::Frame::[...] modules, this would not be possible.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2013, 2016 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
