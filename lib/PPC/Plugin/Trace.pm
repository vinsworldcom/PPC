package PPC::Plugin::Trace;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

use PPC::Plugin;
use PPC::Packet::SRP;

use Time::HiRes qw( tv_interval );
use Net::Frame::Layer qw( :subs );
use Net::Frame::Layer::IPv4 qw( :consts );
my $HAVE_NFL_ICMPv4 = 0;
eval "use Net::Frame::Layer::ICMPv4 qw( :consts )";
if ( !$@ ) {
    $HAVE_NFL_ICMPv4 = 1;
}
my $HAVE_NFL_ICMPv4ECHO = 0;
eval "use Net::Frame::Layer::ICMPv4::Echo";
if ( !$@ ) {
    $HAVE_NFL_ICMPv4ECHO = 1;
}
my $HAVE_NFL_IPv6 = 0;
eval "use Net::Frame::Layer::IPv6 qw( :consts )";
if ( !$@ ) {
    $HAVE_NFL_IPv6 = 1;
}
my $HAVE_NFL_ICMPv6 = 0;
eval "use Net::Frame::Layer::ICMPv6 qw( :consts )";
if ( !$@ ) {
    $HAVE_NFL_ICMPv6 = 1;
}
my $HAVE_NFL_ICMPv6ECHO = 0;
eval "use Net::Frame::Layer::ICMPv6::Echo";
if ( !$@ ) {
    $HAVE_NFL_ICMPv6ECHO = 1;
}

use Exporter;

our @EXPORT = qw (
  Trace
  traceroute
  trace
);

our @ISA = qw ( PPC::Plugin PPC::Packet::SRP Exporter );

sub Trace {
    PPC::_help_full(__PACKAGE__);
}

########################################################

sub traceroute {
    return trace(@_);
}

sub trace {
    my %params = (
        count    => 1,
        delay    => 0,
        family   => 4,
        packet   => undef,
        port     => 33434,       # not user settable except tcp
        port_tcp => 80,          # not user settable
        protocol => 'udp',
        target   => undef,
        timeout  => 2,
        ttl      => [1 .. 30],
        verbose  => 0
    );

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__, "SUBROUTINES/trace - traceroute" );
        }
        ( $params{target} ) = $arg;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $params{target} = shift;
        }
        my %args = @_;
        for ( keys(%args) ) {
            if (/^-?count$/i) {
                if ( ( $args{$_} =~ /^(?:\-)?\d+$/ ) and ( $args{$_} > 0 ) ) {
                    $params{count} = $args{$_};
                } else {
                    warn
                      "Invalid count `$args{$_}' - using $params{count}\n";
                }
            } elsif (/^-?delay$/i) {
                if (    ( $args{$_} =~ /^[0-9]*\.?[0-9]+$/ )
                    and ( $args{$_} > 0 ) ) {
                    $params{delay} = $args{$_};
                } else {
                    warn
                      "Invalid delay `$args{$_}' - using $params{delay}\n";
                }
            } elsif (/^-?family$/i) {
                if (defined(
                        my $ret = PPC::Plugin::_validate_family( $args{$_} )
                    )
                  ) {
                    $params{family} = $ret;
                } else {
                    warn
                      "Invalid family `$args{$_}' - using $params{family}\n";
                }
            } elsif (/^-?packet$/i) {
                if (   ( ref( $args{$_} ) eq 'PPC::Packet' )
                    or ( ref( $args{$_} ) eq 'HASH' ) ) {
                    $params{packet} = $args{$_};
                } else {
                    warn "Not a valid object type for packet arg - using default\n";
                }
            } elsif (/^-?proto(?:col)?$/i) {
                if ( $args{$_} =~ /^udp$/i ) {
                    $params{protocol} = 'udp';
                } elsif ( $args{$_} =~ /^tcp(?:\:(\d{1,5}))?$/i ) {
                    $params{protocol} = 'tcp';
                    my $p = $1;
                    if ( defined($p) ) {
                        if ( ( $p > 0 ) and ( $p <= 65535 ) ) {
                            $params{port} = $p;
                        } else {
                            warn "Invalid port `$p' - using $params{port}\n";
                        }
                    } else {
                        $params{port} = $params{port_tcp};
                    }
                } elsif ( $args{$_} =~ /^icmp$/i ) {
                    $params{protocol} = 'icmp';
                } else {
                    warn
                      "Invalid protocol `$args{$_}' - using $params{protocol}\n";
                }
            } elsif (/^-?target$/i) {
                $params{target} = $args{$_};
            } elsif (/^-?time(?:out)?$/i) {
                if ( ( $args{$_} =~ /^\d+$/ ) and ( $args{$_} > 0 ) ) {
                    $params{timeout} = $args{$_};
                } else {
                    warn
                      "Invalid timeout `$args{$_}' - using $params{timeout}\n";
                }
            } elsif (/^-?ttl$/i) {
                if ( ref( $args{$_} ) eq 'ARRAY' ) {
                    my $OK = 1;
                    for my $ttl ( @{$args{$_}} ) {
                        if (   ( $ttl !~ /^\d{1,3}$/ )
                            or ( $ttl <= 0 )
                            or ( $ttl > 255 ) ) {
                            my $err = sprintf
                              "Invalid ttl `$ttl' in `@{$args{$_}}' - using %i\n",
                              $#{$params{ttl}} + 1;
                            warn $err;
                            $OK = 0;
                            last;
                        }
                    }
                    if ($OK) {
                        $params{ttl} = $args{$_};
                    }
                } else {
                    if (   ( $args{$_} !~ /^\d{1,3}$/ )
                        or ( $args{$_} <= 0 )
                        or ( $args{$_} > 255 ) ) {
                        my $err = sprintf "Invalid ttl `$args{$_}' - using %i\n",
                          $#{$params{ttl}} + 1;
                        warn $err;
                    } else {
                        $params{ttl} = [1 .. $args{$_}];
                    }
                }
            } elsif (/^-?verbose$/i) {
                $params{verbose} = 1;
            } else {
                PPC::_error( "Unknown parameter: `$_'" );
            }
        }
    }

    if ( $params{verbose} ) {
        for ( sort( keys(%params) ) ) {
            if ( $_ eq 'ttl' ) {
                printf "%-15s => [ ", $_;
                print "$_ " for ( @{$params{$_}} );
                print "]\n";
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
            );

            if ( $params{protocol} eq 'tcp' ) {
                $layers[1]->protocol(NF_IPv4_PROTOCOL_TCP);
                $layers[2] = PPC::Layer::TCP( $params{port} );
            } elsif ( $params{protocol} eq 'icmp' ) {
                if ( !( $HAVE_NFL_ICMPv4 and $HAVE_NFL_ICMPv4ECHO ) ) {
                    PPC::_error( 
                      "Net::Frame::Layer::ICMPv4, ::ICMPv4::Echo required for icmp" );
                }
                $layers[1]->protocol(NF_IPv4_PROTOCOL_ICMPv4);
                $layers[2] = Net::Frame::Layer::ICMPv4->new;
                $layers[3] = Net::Frame::Layer::ICMPv4::Echo->new(
                    payload => 'traceroute' );
            } else {
                $layers[1]->protocol(NF_IPv4_PROTOCOL_UDP);
                $layers[2] = PPC::Layer::UDP( $params{port} );
            }
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
                dst => $params{target},
            );

            if ( $params{protocol} eq 'tcp' ) {
                $layers[1]->nextHeader(6); #NF_IPv6_PROTOCOL_TCP
                $layers[2] = PPC::Layer::TCP( $params{port} );
            } elsif ( $params{protocol} eq 'icmp' ) {
                if ( !( $HAVE_NFL_ICMPv6 and $HAVE_NFL_ICMPv6ECHO ) ) {
                    PPC::_error(
                        "Net::Frame::Layer::ICMPv6, ::ICMPv6::Echo required for icmp"
                    );
                }
                $layers[1]->nextHeader(58); #NF_IPv6_PROTOCOL_ICMPv6
                $layers[2] = Net::Frame::Layer::ICMPv6->new;
                $layers[3] = Net::Frame::Layer::ICMPv6::Echo->new(
                    payload => 'traceroute' );
            } else {
                $layers[1]->nextHeader(17); #NF_IPv6_PROTOCOL_UDP
                $layers[2] = PPC::Layer::UDP( $params{port} );
            }
        }
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

    print "Trace to:  $params{target}\n";
    my @trace;
    for my $ttl ( @{$params{ttl}} ) {
        if ($STOP) { last }

        $params{packet} = PPC::Packet::packet( @layers );

        for my $attr ( keys ( %attrs ) ) {
            $params{packet}->$attr($attrs{$attr});
            $params{packet}->pack;
        }

        if ( ref( $layers[1] ) eq 'Net::Frame::Layer::IPv4' ) {
            $layers[1]->ttl($ttl);
        } elsif ( ref( $layers[1] ) eq 'Net::Frame::Layer::IPv6' ) {
            $layers[1]->hopLimit($ttl);
        } else {
            PPC::_error( "Can't set TTL" );
        }
        if ( $params{protocol} eq 'udp' ) {
            $layers[2]->dst( $params{port} + $ttl );
        }
        $params{packet}->pack;

        my $group = PPC::Packet::SRP::srp(
            $params{packet},
            count   => $params{count},
            delay   => $params{delay},
            timeout => $params{timeout}
        );

        my $addr;
        for ( 1 .. $params{count} ) {
            if ( defined $group->recv( $_, 1 ) ) {
                $addr = [$group->recv( $_, 1 )->layers]->[1]->src;
                my $time = tv_interval(
                    [ split /\./, $group->sent($_)->timestamp ],
                    [ split /\./, $group->recv( $_, 1 )->timestamp ]
                );
                printf "%3i\t%-20s (%s secs)\n", $ttl, $addr, $time;
            } else {
                printf "%3i\t%-20s\n", $ttl, "[Request timed out]";
            }
        }
        push @trace, $group;

        # break loop if found $addr is the target
        if ( defined $addr ) {
            if ( $addr eq $params{target} ) {
                last;
            }
        }
    }

    return bless \@trace, __PACKAGE__;
}

1;

__END__

=head1 NAME

Trace - Traceroute

=head1 SYNOPSIS

 use PPC::Plugin::Trace;

 $trace = trace 'target' [OPTIONS];
 $trace->sent([#]);
 $trace->recv([#]);
 $trace->time([#]);

=head1 DESCRIPTION

This module provides the B<PPC> B<trace> command and the accessors for the 
return structure of the B<PPC> B<trace> command.

=head1 COMMANDS

=head2 Trace - provide help

Provides help from the B<PPC> shell.

=head1 SUBROUTINES

=head2 trace - traceroute

 [$trace =] $trace 'target' [OPTIONS]

The traceroute command.  Uses B<srp> for the sending / receiving.  Returns structure:

 $trace->[hop_number] = PPC::Packet::SRP object

For accessors to the return structure, see B<ACCESSORS>.

  Option     Description                        Default Value
  ------     -----------                        -------------
  count      Number of packets to send per hop  1
  delay      Delay between packets sent (secs)  0
               decimal for fractional secs
  family     Address family IPv4/IPv6           IPv4
               Valid values for IPv4:
                 4, v4, ip4, ipv4
               Valid values for IPv6:
                 6, v6, ip6, ipv6
  packet     $packet template to use            (none)
               or hash of attributes, e.g.,
               {tos1=>184,ttl1=>52}
  protocol   Upper layer protocol for packet    udp
               Valid values:
                 icmp, udp, tcp[:port]          80
  target     Target                             (none)
  timeout    Timeout for recv in seconds        2
  ttl        Max number of hops                 30
  verbose    Show options as set (1 = on)       (off)

Single option indicates B<target>.

=head1 ACCESSORS

Inherited from B<PPC::Plugin>.

=head1 EXAMPLES

=head2 Graph

  use PPC::Plugin::Trace;
  $t = trace 'www.google.com';

  use Graph::Easy;
  $graph = Graph::Easy->new;
  for (1..$#{$t->recv}) {
      $graph->add_edge(
        defined $t->recv($_) ? 
          [$t->recv($_)->layers]->[1]->src : 
          "No Reply " . ($_),
        defined $t->recv($_+1) ? 
          [$t->recv($_+1)->layers]->[1]->src : 
          "No Reply " . ($_+1),
        $_
      )
  };
  print $graph->as_txt;

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
