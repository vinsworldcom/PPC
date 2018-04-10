package PPC::Packet;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

use Time::HiRes qw( usleep );
use Net::Frame::Simple 1.06;
use Net::Pcap 0.17;

our $AUTOLOAD;

use Exporter;

our @EXPORT = qw(
  packet
  sendp
  sniff
  sniff_stats
  sniff_decode
  sniff_hexdump
  wireshark
);

our @ISA = qw ( PPC Net::Frame::Simple Exporter );

__PACKAGE__->cgBuildIndices;

########################################################

sub AUTOLOAD {
    my ($self) = shift;
    $AUTOLOAD =~ s/.*:://;
    
    # Layer plus Accessor
    if ( $AUTOLOAD =~ /_/ ) {
        my ($layer, $accessor) = split /_/, $AUTOLOAD, 2;
        for my $i ( 0 .. $#{[$self->layers]} ) {
            my $lyr = [$self->layers]->[$i];
            $lyr =~ s/^Net::Frame::Layer:://;
            $lyr =~ s/:://g;
            $lyr =~ s/=.*$//;
            if ( lc($lyr) eq $layer ) {
                return [$self->layers]->[$i]->$accessor(@_);
            }
        }
        PPC::_error("Unknown layer - `$layer'");

        # Accessor plus Numeric Layer
    } else {
        my ($accessor, $layer) = split /([0-9]{1,})$/, $AUTOLOAD;
        if (defined $layer) {
            if ($layer !~ /^[0-9]{1,}$/) {
                PPC::_error("Unknown layer - `$layer'");
            }
        } else {
            PPC::_error("No layer provided or unknown accessor - `$accessor'");
        }
        # DEBUG:  print "[$self->layers]->[$layer]->$accessor(@_)\n";
        return [$self->layers]->[$layer]->$accessor(@_);
    }
}

sub DESTROY { return }

sub new {
    shift @_;
    my $ret = Net::Frame::Simple->new( @_ );
    return bless $ret, __PACKAGE__
}

sub packet {
    my ($arg) = @_;

    if ( !defined($arg)
        or ( ( !ref $arg ) and ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) ) ) {
        PPC::_help( __PACKAGE__, "COMMANDS/packet - create packet" );
    }

    my $p = _ppack(@_);

    sub _ppack {
        my $ret = Net::Frame::Simple->new( layers => [@_] );
        return $ret;
    }
    if ( !defined wantarray ) {
        print $p->print;
    }
    return bless $p, __PACKAGE__;
}

sub payload {
    my ($self) = shift;
    my ($arg) = @_;

    if ( defined($arg)
        and ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) ) {
        PPC::_help( __PACKAGE__, "ACCESSORS/payload - get packet payload" );
    }

    return [$self->layers]->[-1]->payload(@_);
}

sub sendp {
    my %params = (
        count   => 1,
        delay   => 0,
        device  => $PPC::PPC_GLOBALS->{device},
        packet  => undef,
        verbose => 0
    );

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) {
            PPC::_help( __PACKAGE__, "COMMANDS/sendp - send packets" );
        }
        ( $params{packet} ) = $arg;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $params{packet} = shift;
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
            } elsif (/^-?device$/i) {
                $params{device} = $args{$_};
                if ( !_testpcap( $params{device} ) ) { return }
            } elsif (/^-?packet$/i) {
                $params{packet} = $args{$_};
            } elsif (/^-?verbose$/i) {
                $params{verbose} = 1;
            } else {
                PPC::_error( "Unknown parameter: `$_'" );
            }
        }
    }

    if ( !_send_check_params( \%params ) ) {
        return;
    }

    my @pa;
    if ( ref $params{packet} eq "ARRAY" ) {
        @pa = map { $_ } @{$params{packet}};
    } else {
        push @pa, $params{packet};
    }

    my $pcap = _send_pcap_open( $params{device} );
    if ( !$pcap ) {
        return;
    }

    # Ctrl-C
    my $STOP = 0;
    local $SIG{'INT'} = sub {
        $STOP = 1;
        print "\nStopped by user\n";
    };

    my @rets;
    my $retType = wantarray;

    my $count = 0;
    $| = 1;
    while ( $count != $params{count} ) {
        last if ($STOP);
        for my $pk (@pa) {
            last if ($STOP);

            $pk = _send_pack_packet(\$pk);

            if ( Net::Pcap::pcap_sendpacket( $pcap, $pk->raw ) != 0 ) {
                my $err = sprintf "Error sending the packet: %s\n",
                  Net::Pcap::pcap_geterr($pcap);
                warn $err;
            } else {
                print "." if ( !defined $retType );
                push @rets, $pk;
            }
            usleep $params{delay} * 1000000;
        }
        $count++;
    }
    Net::Pcap::pcap_close($pcap);

    if ( !defined $retType ) {
        printf "\nSent %i packet%s\n", scalar @rets,
          ( scalar @rets > 1 ) ? "s" : "";
        return;
    } elsif ($retType) {
        return @rets;
    } else {
        return \@rets;
    }
}

sub sniff {
    my %params = (
        callback  => 'PPC::sniff_stats',
        continue  => 1,
        count     => -1,
        device    => $PPC::PPC_GLOBALS->{device},
        filter    => '',
        promisc   => 1,
        savefile  => '',
        snaplen   => 68,
        verbose   => 0,
        wireshark => 0,
    );

    if (    defined( $PPC::PPC_GLOBALS->{interface} )
        and defined( $PPC::PPC_GLOBALS->{interface}->mtu ) ) {
        $params{snaplen} = $PPC::PPC_GLOBALS->{interface}->mtu;
    }

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) {
            PPC::_help( __PACKAGE__, "COMMANDS/sniff - capture traffic" );
        }
        ( $params{filter} ) = $arg;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $params{filter} = shift;
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
                if ( ( $args{$_} !~ /^\d+$/ ) or ( $args{$_} <= 0 ) ) {
                    warn "Invalid count `$args{$_}' - looping forever\n";
                } else {
                    $params{count} = $args{$_};
                }
            } elsif (/^-?device$/i) {
                $params{device} = $args{$_};
                if ( !_testpcap( $params{device} ) ) { return }
            } elsif (/^-?filter$/i) {
                $params{filter} = $args{$_};
            } elsif (/^-?promisc(?:uous)?$/i) {
                $params{promisc} = $args{$_};
            } elsif (/^-?snap(?:len)?$/i) {
                $params{snaplen} = $args{$_};
            } elsif (/^-?save(?:file)?$/i) {
                $params{savefile} = $args{$_};
            } elsif (/^-?verbose$/i) {
                $params{verbose} = 1;
            } elsif (/^-?wireshark$/i) {
                $params{wireshark} = 1;
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

    if ( !defined( $params{device} ) ) {
        PPC::_error( "No device currently set" );
    }

    if ( $params{wireshark} ) {
        my $command_line = "-i $params{device} -s $params{snaplen} -klS ";
        if ( $params{count} != -1 ) {
            $command_line .= "-c$params{count} ";
        }
        if ( $params{filter} ne '' ) {
            $command_line .= "-f $params{filter} ";
        }
        if ( $params{promisc} == 0 ) {
            $command_line .= "-p ";
        }
        if ( $params{savefile} ne '' ) {
            $command_line .= "-w $params{savefile} ";
        }
        if ( $^O eq 'MSWin32' ) {
            system(
                "start \"\" \"$PPC::PPC_GLOBALS->{wireshark}\" $command_line"
            );
        } else {
            system("$PPC::PPC_GLOBALS->{wireshark} $command_line &");
        }
    } else {
        if (    ( $params{callback} ne '' )
            and ( !defined( &{$params{callback}} ) ) ) {
            PPC::_error("Callback does not exist - `$params{callback}'");
        }

        my $err;
        my $pcap
          = Net::Pcap::pcap_open_live( $params{device}, $params{snaplen},
            $params{promisc}, 5, \$err );
        if ( !defined $pcap ) {
            PPC::_error("Cannot open device - `$params{device}': $err");
        }

        if ( $params{filter} ne '' ) {
            if (!defined(
                    _sniff_filter(
                        $pcap,           $params{device},
                        $params{filter}, $params{continue}
                    )
                )
              ) {
                return;
            }
        }

        # Ctrl-C
        # local $SIG{'INT'} = sub {
        # Net::Pcap::pcap_breakloop($pcap);
        # print "\nStopped by user\n"
        # };
        my $STOP = 0;
        local $SIG{'INT'} = sub {
            $STOP = 1;
            print "\nStopped by user\n";
        };

        # savefile
        my %SCUD = (
            callback => $params{callback},
            h_save   => undef,
            packet   => ''
        );
        if ( $params{savefile} ne '' ) {
            if (!defined(
                    $SCUD{h_save}
                      = Net::Pcap::pcap_dump_open( $pcap, $params{savefile} )
                )
              ) {
                warn
                  "Cannot write to - `$params{savefile}'\nContinuing with no savefile\n";
            }
        }

        #        my %stats;
        $| = 1;

        # Net::Pcap::pcap_loop($pcap, $params{count}, \&_sniff_main, \%SCUD);
        my $i = 0;
        while ( $i != $params{count} ) {
            last if ($STOP);
            my $ret
              = Net::Pcap::pcap_dispatch( $pcap, 1, \&_sniff_main, \%SCUD );
            $i += $ret;
        }

        #        pcap_stats($pcap, \%stats);

        if ( defined( $SCUD{h_save} ) ) {
            Net::Pcap::pcap_dump_close( $SCUD{h_save} );
        }
        Net::Pcap::pcap_close($pcap);

        #        printf "\n%i packets received by capture\n%i packets dropped by capture\n", $stats{ps_recv}, $stats{ps_drop};

        return $SCUD{packet};
    }
}

sub sniff_stats {
    my ( $user_data, $header, $packet ) = @_;
    printf "len=%s, caplen=%s, tv_sec=%s, tv_usec=%s\n",
      map { $header->{$_} } qw(len caplen tv_sec tv_usec);
    return;
}

sub sniff_decode {
    my ( $user_data, $header, $packet ) = @_;
    print $user_data->{packet}->print . "\n";
    return;
}

sub sniff_hexdump {
    my ( $user_data, $header, $packet ) = @_;
    PPC::hexdump $packet;
    return;
}

sub wireshark {
    my %params = ( wireshark => '' );

    my %args;
    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) {
            PPC::_help( __PACKAGE__,
                "COMMANDS/wireshark - configure or use wireshark" );
        }
        ( $params{wireshark} ) = $arg;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $params{wireshark} = shift;
        }
        %args = @_;
    }

    if ( defined( $params{wireshark} ) and ( $params{wireshark} ne '' ) ) {
        $PPC::PPC_GLOBALS->{wireshark} = $params{wireshark};
    }
    if ( defined wantarray ) {
        return $PPC::PPC_GLOBALS->{wireshark};
    } else {
        print $PPC::PPC_GLOBALS->{wireshark} . "\n";
    }

    if ( keys(%args) != 0 ) {
        sniff( @_, wireshark => 1 );
    }
}

sub _send_check_params {
    my ($params) = @_;
    if ( $params->{verbose} ) {
        for ( sort( keys( %{$params} ) ) ) {
            printf "%-15s => %s\n", $_,
              defined( $params->{$_} ) ? $params->{$_} : '[undef]';
        }
        print "\n";
    }

    if ( !defined( $params->{device} ) ) {
        warn "No device currently set\n";
        return 0;
    }

    if ( !defined( $params->{packet} ) ) {
        warn "No packet to send\n";
        return 0;
    }

    return 1;
}

sub _send_pack_packet {
    my ($pk) = @_;

    my $send;
    if ( ( ref $$pk ) eq "PPC::Packet" ) {

        # need to pack to calc checksums / lengths, etc.
        $$pk->pack;

        # need to recreate to establish new sending timestamp
        # and new packet
        $send = PPC::Packet->new(
            raw        => $$pk->raw,
            firstLayer => 'ETH'
        );
    } else {
        $send = PPC::Packet->new(
            raw        => $$pk,
            firstLayer => 'ETH'
        );
    }
    return $send;
}

sub _send_pcap_open {
    my ($dev) = @_;

    my $err;
    # Windows only:
    # my %devinfo;
    # my $pcap = Net::Pcap::pcap_open( $dev, 100, 0, 1000, \%devinfo, \$err );
    my $pcap = Net::Pcap::pcap_open_live( $dev, 100, 0, 1000, \$err );
    if ( !defined($pcap) ) {
        warn "Cannot open device - `$dev': $err\n";
        return 0;
    }
    return $pcap;
}

sub _sniff_filter {

    # pcap, device, filter(string), continue (if error)
    my ( $p, $d, $f, $c ) = @_;

    my ( $net, $mask, $err, $filter );
    if ( Net::Pcap::pcap_lookupnet( $d, \$net, \$mask, \$err ) != 0 ) {
        warn "Filter get netmask failed for `$d': $err\n";
        if ($c) {
            warn "Continuing with no filter\n";
        } else {
            return undef;
        }
    } else {
        if ( Net::Pcap::pcap_compile( $p, \$filter, $f, 1, $mask ) != 0 ) {
            warn "Filter compilation failed\n";
            if ($c) {
                warn "Continuing with no filter\n";
            } else {
                return undef;
            }
        } else {
            if ( Net::Pcap::pcap_setfilter( $p, $filter ) != 0 ) {
                warn "Filter apply failed\n";
                if ($c) {
                    warn "Continuing with no filter\n";
                } else {
                    return undef;
                }
            } else {
                Net::Pcap::pcap_freecode($filter);
            }
        }
    }
    return $filter;
}

sub _sniff_main {
    my ( $user_data, $header, $packet ) = @_;

    # last packet
    $user_data->{packet} = PPC::Packet->new(
        raw => $packet, 
        firstLayer => 'ETH',
        timestamp => $header->{tv_sec} . "." . $header->{tv_usec}
    );

    # savefile
    if ( defined( $user_data->{h_save} ) ) {
        Net::Pcap::pcap_dump( $user_data->{h_save}, $header, $packet );
    }

    # user callback
    no strict 'refs';
    if ( $user_data->{callback} ne '' ) {
        &{$user_data->{callback}}( $user_data, $header, $packet );
    }
}

1;

__END__

########################################################
# Start POD
########################################################

=head1 NAME

PPC::Packet - Perl Packet Crafter Packet Object

=head1 SYNOPSIS

 use PPC::Packet;

 $packet = PPC::Packet->new([Net::Frame::Simple options]);
 $ret = sendp $packet;

 sniff;

=head1 DESCRIPTION

Packet provides the key packet construction ability to B<PPC>.  Once packets 
are constructed, they can be sent.  Packets can also be captured.

=head1 METHODS

=head2 new - create PPC::Packet object

 [$packet =] PPC::Packet->new([Net::Frame::Simple options]);

Creates B<$packet> from provided information.  PPC::Packet is a subclass 
of B<Net::Frame::Simple>.  See B<Net::Frame::Simple> for usage.

=head1 COMMANDS

=head2 packet - create packet

 [$packet =] packet $layer1[,$layer2[,...]]

Creates B<$packet> from provided B<$layer(s)>.  This is essentially a 
shortcut to:

 [$packet =] PPC::Packet->new( -layers => [@_]);

Where C<@_> represents the C<$layer1>, C<$layer2>, arguments from above 
usage example.

=head2 sendp - send packets

 [$packet =] sendp $packet [OPTIONS]
 [@packets =] sendp \@packets [OPTIONS]

Sends packets to the network.  Returns array of packets sent as 
B<PPC::Packet> objects.

  Option     Description                       Default Value
  ------     -----------                       -------------
  count      Number of packets to send         1
             negative number = send forever
  delay      Delay between packets sent (secs) 0
             decimal for fractional secs
  device     Device to send on                 device if defined
  packet     $packet, \@packets                (none)
  verbose    Show options as set (1 = on)      (off)

Option B<packet> may be created by C<packet> command or may be a string
of packed hex digits from C<H2S> macro.  Option B<packet> may be a
single scalar or reference to an array of packets to be sent in order.

Single option indicates B<packet>.

=head2 sniff - capture traffic

 [$last =] sniff [OPTIONS]

Captures traffic from the network.  Ctrl-C to stop.  Returns last packet
captured as B<PPC::Packet> object.

  Option     Description                       Default Value
  ------     -----------                       -------------
  callback   Sub to call when packet catpured  (see below)
  continue   Continue on error (0 = off)       (yes)
  count      Number of packets to capture      (forever)
  device     Device to capture on              device if defined
  filter     Capture filter                    (allow all)
  promisc    Capture in promiscuous mode       (on)
  savefile   File to write packets             (none)
  snaplen    Capture packet length             MTU if "interface" command
                                                 else 68
  verbose    Show options as set (1 = on)      (off)
  wireshark  Start Wireshark for capture       (off)
             (1 = on)

Single option indicates B<filter>.

Callback is a sub to call to process the packet once one is captured.
Provided subs are:

=over 4

=item B<sniff_stats>

Print packet statistics.  This is the default.

=item B<sniff_decode>

Decode packet.

=item B<sniff_hexdump>

Hexdump packet.

=back

A custom callback sub can be defined from within the shell and called.
A custom callback sub can call the existing callbacks if statistics or
decode is required.  Callbacks are in the form:

  sub SUB_NAME {
      my ($user_data, $header, $packet) = @_;

      ...
  }

See B<Net::Pcap> for details.

  Name           Description
  ----           -----------
  $user_data     Hash reference:
                 {callback} = sub callback name
                 {h_save} = pcap_dump_open handle if save file
                 {packet} = PPC::Packet object

=head2 wireshark - configure or use wireshark

 [$wireshark =] wireshark [OPTIONS]

Configure or use B<wireshark> for capture.  No argument displays B<wireshark> 
program location.  Single argument sets B<wireshark> program location.  For 
B<OPTIONS>, see B<sniff> command.  Optional return value is B<wireshark> 
program location.

NOTE:  Optional return value overrides execution of B<wireshark> capture.

=head1 ACCESSORS

Accessors are available for fields in the sublayers of C<$packet> returned 
by the B<packet()> command above.  They are called by specifying the 
accessor and layer of the requested value in one of two ways.

=head2 Accessor plus Numeric Layer

For example:

 $packet = packet ETHER,IPv4,TCP;
 print $packet->src0;      # Ethernet source MAC address
 print $packet->dst0;      # Ethernet destination MAC address
 print $packet->src1;      # IPv4 source IP address
 print $packet->dst1;      # IPv4 destination IP address
 print $packet->ttl1;      # IPv4 time to live
 print $packet->src2;      # TCP source port
 print $packet->dst2;      # TCP destination port

The B<packet()> command returns a B<PPC::Packet> object which contains an 
array of B<Net::Frame::Layer::_layer_> objects.  In the above example, 
B<ETHER> returns a B<Net::Frame::Layer::ETH> object and is at array position 
0.  So calling 'src0' returns the B<src> accessor (if it exists) from the 
object at array position (layer) 0.  Likewise, a B<Net::Frame::Layer::IPv4> 
object is at array position 1, so B<Net::Frame::Layer::IPv4> accessors are 
available by calling them with a trailing 1.

These are essentially a shortcut for:

 [$packet->layers]->[1]->src;    # IPv4 source IP address
 $packet->src1;                  # same as above

They can also be used as setters by specifying the value to set.  For 
example:

 $packet->ttl1(5);    # Set time-to-live of Net::Frame::Layer::IPv4 
                      # object at layer 1 to the value of 5

An error is displayed if an invalid accessor or layer is specified.

=head2 Layer plus Accessor

For example:

 $packet = packet ETHER,IPv4,TCP;
 print $packet->eth_src;   # Ethernet source MAC address
 print $packet->eth_dst;   # Ethernet destination MAC address
 print $packet->ipv4_src;  # IPv4 source IP address
 print $packet->ipv4_dst;  # IPv4 destination IP address
 print $packet->ipv4_ttl;  # IPv4 time to live
 print $packet->tcp_src;   # TCP source port
 print $packet->tcp_dst;   # TCP destination port

The B<packet()> command returns a B<PPC::Packet> object which contains an 
array of B<Net::Frame::Layer::_layer_> objects.  In the above example, 
B<ETHER> returns a B<Net::Frame::Layer::ETH> object. The layer name is 
derived by taking the lowercase of the layer name after C<Net::Frame::Layer::>, 
removing any additional double-colons '::', appending an underscore '_' and 
adding the accessor name for that respective layer.  So 'src' from the 
B<Net::Frame::Layer::ETH> object is obtained with C<eth_src> and 'ttl' from 
the B<Net::Frame::Layer::IPv4> object is obtained with 'ipv4_ttl'.  ICMP 
Echo 'sequenceNumber' from the B<Net::Frame::Layer::ICMPv4::Echo> object is 
obtained with C<icmpv4echo_sequenceNumber>.

B<NOTE:> If the packet obejet contains more than one of the named layers, this 
method will only return the value from the frist encounterd layer.  If you need 
values from a second occurance of the given layer, see the Accessor plus 
Numeric Layer technique above.

=head2 payload - get packet payload

 [$payload =] $packet->payload();

The B<payload()> accessor is a special case which does not need a layer 
number.  This will return the payload of the packet from whatever top level 
layer if the payload exists.  This is essentially a shortcut for:

 [$packet->layers]->[-1]->payload;

=head1 SEE ALSO

L<PPC>, L<PPC::Layer>, L<PPC::Interface>, 
L<Net::Frame::Simple>, L<Net::Pcap>

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
