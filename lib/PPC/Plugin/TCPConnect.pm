package PPC::Plugin::TCPConnect;

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
my $HAVE_Net_Telnet = 0;
eval "use Net::Telnet";
if ( !$@ ) {
    $HAVE_Net_Telnet = 1;
}

use Exporter;

our @EXPORT = qw (
  TCPConnect
  tcpconnect
  tcpsr
);

our @ISA = qw ( PPC::Plugin PPC::Packet::SRP Exporter );

sub TCPConnect {
    PPC::_help_full( __PACKAGE__ );
}

########################################################

sub tcpconnect {

    my %params = (
        ack     => 1,
        family  => 4,
        packet  => undef,
        port    => 80,
        socket  => 0,
        target  => undef,
        timeout => 2,
        verbose => 0
    );

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__, "SUBROUTINES/tcpconnect - TCP connect to host" );
        }
        ( $params{target} ) = $arg;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $params{target} = shift;
        }
        my %args = @_;
        for ( keys(%args) ) {
            if (/^-?ack$/i) {
                $params{ack} = $args{$_};
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
            } elsif (/^-?port$/i) {
                if (   ( $args{$_} !~ /^\d{1,5}$/ )
                    or ( $args{$_} < 0 )
                    or ( $args{$_} > 65535 ) ) {
                    warn "Invalid port `$args{$_}' - using default\n";
                } else {
                    $params{port} = $args{$_};
                }
            } elsif (/^-?target$/i) {
                $params{target} = $args{$_};
            } elsif (/^-?socket$/i) {
                if ( $HAVE_Net_Telnet ) {
                    $params{socket} = $args{$_};
                } else {
                    PPC::_error( "Net::Telnet required for -socket option" );
                }
            } elsif (/^-?time(?:out)?$/i) {
                if ( ( $args{$_} =~ /^\d+$/ ) and ( $args{$_} > 0 ) ) {
                    $params{timeout} = $args{$_};
                } else {
                    warn
                      "Invalid timeout `$args{$_}' - using $params{timeout}\n";
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
            printf "%-15s => %s\n", $_,
              defined( $params{$_} ) ? $params{$_} : '[undef]';
        }
        print "\n";
    }

    if ( !defined $params{target} ) {
        PPC::_error( "No target" );
    }

    if ( $params{socket} ) {
        my %hash = (
            host => $params{target},
            port => $params{port},
        );
        if ( ( ref $params{socket} ) eq 'HASH' ) {
            for ( keys ( %{$params{socket}} ) ) {
                $hash{$_} = $params{socket}->{$_};
            }
        }
        my $telnet = Net::Telnet->new( %hash ) 
          or PPC::_error( 
            "Unable to connect to `$params{target}:$params{port}'" );
        $hash{telnet} = $telnet;
        return bless \%hash, __PACKAGE__ ;
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
        $layers[2] = PPC::Layer::TCP(
            options => PPC::Macro::H2S('020405b40103030801010402')
        );
    }

    my %attrs;
    if (    ( defined $params{packet} ) 
        and ( ref $params{packet} eq 'HASH' ) ) {
        %attrs = %{$params{packet}};
    }

    print "TCP Connect to:  $params{target}\n";
    my @connect;

    # SYN
    $params{packet} = PPC::Packet::packet( @layers );

    for my $attr ( keys ( %attrs ) ) {
        $params{packet}->$attr($attrs{$attr});
        $params{packet}->pack;
    }
    
    $layers[2]->dst($params{port});
    $layers[2]->flags(NF_TCP_FLAGS_SYN);
    $params{packet}->pack;
    
    print "--SYN--\n" . $layers[2]->print . "\n";
    my $group = PPC::Packet::SRP::srp(
        $params{packet},
        count   => 1,
        timeout => $params{timeout}
    );

    push @connect, $group;

    # SYN-ACK
    if ( defined $group->recv( 1, 1 ) ) {
        print "--SYN-ACK--\n" . [$group->recv( 1, 1 )->layers]->[2]->print . "\n";

        # ACK
        if ( $params{ack}) {
            $params{packet} = PPC::Packet::packet( @layers );

            for my $attr ( keys ( %attrs ) ) {
                $params{packet}->$attr($attrs{$attr});
                $params{packet}->pack;
            }

            $layers[2]->seq($layers[2]->seq+1);
            $layers[2]->ack([$group->recv( 1, 1 )->layers]->[2]->seq+1);
            $layers[2]->flags(NF_TCP_FLAGS_ACK);
            $layers[2]->options('');
            $params{packet}->pack;

            print "--ACK--\n" . $layers[2]->print . "\n";
            my $group = PPC::Packet::SRP::srp(
                $params{packet},
                count   => 1,
                timeout => $params{timeout}
            );

            push @connect, $group;
        }
    } else {
        printf "%-20s\n\n", "[Request timed out]";
    }

    return bless \@connect, __PACKAGE__;
}

sub tcpsr {
    my ( $self, $arg ) = @_;

    if ( defined($arg) and ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "METHODS/tcpsr - send and receive data over TCP socket" );
    }

    if ( !defined $self->{telnet} ) {
        PPC::_error( "Object not valid, use -socket option" );
    }

    my @rets;
    my $retType = wantarray;
    
    if ( defined $arg ) {
        $self->{telnet}->print($arg);
        while (my $l = $self->{telnet}->getline) {
            push @rets, $l;
        }
        if ( $self->{telnet}->eof ) {
            $self->{telnet}->close;
        }
    } else {
        PPC::_error( "data required" );
    }

    if ( !defined $retType ) {
        print $_ for ( @rets )
    } elsif ( $retType ) {
        return @rets;
    } else {
        my $ret = join "", @rets;
        return $ret;
    }
}

sub close {
    my ( $self, $arg ) = @_;

    if ( defined($arg) and ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "METHODS/close - close TCP socket" );
    }

    if ( !defined $self->{telnet} ) {
        PPC::_error( "Object not valid, use -socket option" );
    }

    $self->{telnet}->close;
}

1;

__END__

=head1 NAME

TCPConnect - TCP Connect

=head1 SYNOPSIS

 use PPC::Plugin::TCPConnect;

 $conn = tcpconnect 'target' [OPTIONS];
 $conn->sent([#]);
 $conn->recv([#]);
 $conn->report;

=head1 DESCRIPTION

This module provides the B<PPC> B<tcpconnect> command and the accessors for the 
return structure of the B<PPC> B<tcpconnect> command.

=head1 COMMANDS

=head2 TCPConnect - provide help

Provides help from the B<PPC> shell.

=head1 SUBROUTINES

=head2 tcpconnect - TCP connect to host

 [$conn =] tcpconnect 'target' [OPTIONS]

The TCP connect command.  Uses B<srp> for the sending / receiving.  Returns 
structure:

 $conn->[group_number] = PPC::Packet::SRP object

For accessors to the return structure, see B<ACCESSORS>.

  Option     Description                        Default Value
  ------     -----------                        -------------
  ack        Complete the connection if SYN-ACK 1
               received (0 = no, 1 = yes)
  family     Address family IPv4/IPv6           IPv4
               Valid values for IPv4:
                 4, v4, ip4, ipv4
               Valid values for IPv6:
                 6, v6, ip6, ipv6
  packet     $packet template to use            (none)
               or hash of attributes, e.g.,
               {tos1=>184,ttl1=>52}
  port       Ports to connect to                80
  socket     (see below)                        (off)
  target     Target                             (none)
  timeout    Timeout for recv in seconds        2
  verbose    Show options as set (1 = on)       (off)

Single option indicates B<target>.

=over 4

=item B<socket>

Use Net::Telnet to create an actual socket over which data can be sent 
with tcpsend() method.  To pass B<Net::Telnet> options, set the C<socket> 
argument to a hash containing B<Net::Telnet> options.

This allows the following methods to be called.

=back

=head1 METHODS

=head2 tcpsr - send and receive data over TCP socket

 $conn->tcpsr $data;

If the C<socket> option is used in the C<tcpconnect> command, it creates a 
real socket connection with B<Net::Telnet> to the specified target on the 
specified port.  This method provides a way to send and recieve data over 
the TCP connection.

=head2 close - close TCP socket

 $conn->close;

If the C<socket> option is used in the C<tcpconnect> command, it creates a 
real socket connection with B<Net::Telnet> to the specified target on the 
specified port.  This method closes the socket.

=head1 ACCESSORS

Inherited from B<PPC::Plugin>.

=head1 SEE ALSO

L<PPC::Plugin>, L<PPC::Packet::SRP>

=head1 ACKNOWLEDGEMENTS

Special thanks to Patrice E<lt>GomoRE<gt> Auffret without whose 
Net::Frame::[...] modules, this would not be possible.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2016 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
