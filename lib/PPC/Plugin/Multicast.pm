package PPC::Plugin::Multicast;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

use Net::IPv4Addr;
use Net::IPv6Addr;

use Exporter;

our @EXPORT = qw (
  Multicast
  MULTICAST_IPv4_BASE
  MULTICAST_IPv4_BASE
  MULTICAST_IPv4_ALL_HOSTS
  MULTICAST_IPv4_ALL_ROUTERS
  MULTICAST_IPv4_ALL_OSPF
  MULTICAST_IPv4_ALL_OSPF_DR
  MULTICAST_IPv4_RIPv2
  MULTICAST_IPv4_EIGRP
  MULTICAST_IPv4_PIMv2
  MULTICAST_IPv4_VRRP
  MULTICAST_IPv4_IGMPv3
  MULTICAST_IPv4_HSRPv2
  MULTICAST_IPv4_GLBP
  MULTICAST_IPv4_PTPv2
  MULTICAST_IPv4_mDNS
  MULTICAST_IPv4_LLMNR
  MULTICAST_IPv4_TEREDO
  MULTICAST_IPv4_NTP
  MULTICAST_IPv4_SLPv1
  MULTICAST_IPv4_SLPv1DA
  MULTICAST_IPv4_AUTORP_ANNOUNCE
  MULTICAST_IPv4_AUTORP_DISCOVER
  MULTICAST_IPv4_H323_GK
  MULTICAST_IPv4_SSDP
  MULTICAST_IPv4_SLPv2
  MULTICAST_IPv6_ALL_NODES
  MULTICAST_IPv6_ALL_ROUTERS
  MULTICAST_IPv6_ALL_OSPFv3
  MULTICAST_IPv6_ALL_OSPFv3_DR
  MULTICAST_IPv6_ISIS
  MULTICAST_IPv6_RIP
  MULTICAST_IPv6_EIGRP
  MULTICAST_IPv6_PIMv2
  MULTICAST_IPv6_MLDv2_REPORT
  MULTICAST_IPv6_ALL_DHCP
  MULTICAST_IPv6_ALL_LLMNR
  MULTICAST_IPv6_ALL_DHCP_SITE
  MULTICAST_IPv6_PTPv2
  ipv4McastMac
  ipv4MultiMac
  ipv4MulticastMac
  ipv6McastMac
  ipv6MultiMac
  ipv6MulticastMac
  ipv6SolicitNode
  ipv6SolNode
  ipv6SolicitedNode
);

our @ISA = qw ( PPC::Layer Exporter );

sub Multicast {
    PPC::_help_full( __PACKAGE__ );
}

########################################################

sub MULTICAST_IPv4_BASE        { '224.0.0.0' }
sub MULTICAST_IPv4_ALL_HOSTS   { '224.0.0.1' }
sub MULTICAST_IPv4_ALL_ROUTERS { '224.0.0.2' }
sub MULTICAST_IPv4_ALL_OSPF    { '224.0.0.5' }
sub MULTICAST_IPv4_ALL_OSPF_DR { '224.0.0.6' }
sub MULTICAST_IPv4_RIPv2       { '224.0.0.9' }
sub MULTICAST_IPv4_EIGRP       { '224.0.0.10' }
sub MULTICAST_IPv4_PIMv2       { '224.0.0.13' }
sub MULTICAST_IPv4_VRRP        { '224.0.0.18' }
sub MULTICAST_IPv4_IGMPv3      { '224.0.0.22' }
sub MULTICAST_IPv4_HSRPv2      { '224.0.0.102' }
sub MULTICAST_IPv4_GLBP        { '224.0.0.102' }
sub MULTICAST_IPv4_PTPv2       { '224.0.0.107' }
sub MULTICAST_IPv4_mDNS        { '224.0.0.251' }
sub MULTICAST_IPv4_LLMNR       { '224.0.0.252' }
sub MULTICAST_IPv4_TEREDO      { '224.0.0.253' }
sub MULTICAST_IPv4_NTP         { '224.0.1.1' }
sub MULTICAST_IPv4_SLPv1       { '224.0.1.22' }
sub MULTICAST_IPv4_SLPv1DA     { '224.0.1.35' }
sub MULTICAST_IPv4_AUTORP_ANNOUNCE { '224.0.1.39' }
sub MULTICAST_IPv4_AUTORP_DISCOVER { '224.0.1.40' }
sub MULTICAST_IPv4_H323_GK     { '224.0.1.41' }
sub MULTICAST_IPv4_SSDP        { '239.255.255.250' }
sub MULTICAST_IPv4_SLPv2       { '239.255.255.253' }

sub MULTICAST_IPv6_ALL_NODES     { 'ff02::1' }
sub MULTICAST_IPv6_ALL_ROUTERS   { 'ff02::2' }
sub MULTICAST_IPv6_ALL_OSPFv3    { 'ff02::5' }
sub MULTICAST_IPv6_ALL_OSPFv3_DR { 'ff02::6' }
sub MULTICAST_IPv6_ISIS          { 'ff02::8' }
sub MULTICAST_IPv6_RIP           { 'ff02::9' }
sub MULTICAST_IPv6_EIGRP         { 'ff02::a' }
sub MULTICAST_IPv6_PIMv2         { 'ff02::d' }
sub MULTICAST_IPv6_MLDv2_REPORT  { 'ff02::16' }
sub MULTICAST_IPv6_ALL_DHCP      { 'ff02::1:2' }
sub MULTICAST_IPv6_ALL_LLMNR     { 'ff02::1:3' }
sub MULTICAST_IPv6_ALL_DHCP_SITE { 'ff05::1:3' }
sub MULTICAST_IPv6_PTPv2         { 'ff02::6b' }

sub ipv4McastMac {
    return ipv4MulticastMac(@_);
}

sub ipv4MultiMac {
    return ipv4MulticastMac(@_);
}

sub ipv4MulticastMac {
    my ($arg) = @_;

    if ( !defined($arg) or ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "SUBROUTINES/ipv4MulticastMac - return IPv4 Multicast MAC" );
    }

    my $retType = wantarray;

    my $addr = Net::IPv4Addr::ipv4_parse($arg);
    if ( !Net::IPv4Addr::ipv4_in_network( '224.0.0.0/4', "$addr/32" ) ) {
        PPC::_error( "Not a valid IPv4 multicast address - `$arg'" );
    }

    # Grab last 3 octets (24 bits)
    my ( undef, @addr ) = split /\./, $addr;

    my $mac;

    # Multicast Mac is last 23 bits of IPv4 address
    # Need to "mask" octet 2 ($addr[0] from above) with 0x7f (01111111)
    $addr[0] &= 0x7f;
    for (@addr) {
        $mac .= sprintf "%02x:", $_;
    }
    $mac =~ s/:$//;

    $mac = "01:00:5e:" . $mac;

    if ( !defined $retType ) {
        print "$mac\n";
        return;
    } else {
        return $mac;
    }
}

sub ipv6McastMac {
    return ipv6MulticastMac(@_);
}

sub ipv6MultiMac {
    return ipv6MulticastMac(@_);
}

sub ipv6MulticastMac {
    my ($arg) = @_;

    if ( !defined($arg) or ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "SUBROUTINES/ipv6MulticastMac - return IPv6 Multicast MAC" );
    }

    my $retType = wantarray;

    my $addr = Net::IPv6Addr->new($arg);

    # See:  https://rt.cpan.org/Public/Bug/Display.html?id=79325
    # Would like to use the following, but bug:
    # if (!$addr->in_network('ff00::', 8)) {
    my $testAddr = sprintf "0" x (
        4 - length(
            substr(
                $addr->to_string_preferred, 0,
                index( $addr->to_string_preferred, ':' )
            )
        )
      )
      . substr( $addr->to_string_preferred,
        0, index( $addr->to_string_preferred, ':' ) );
    if ( substr( $testAddr, 0, 2 ) ne 'ff' ) {
        PPC::_error( "Not a valid IPv6 multicast address - `$arg'" );
    }

    my ( undef, undef, undef, undef, undef, undef, @addr ) = split /:/,
      $addr->to_string_preferred;

    my $mac;
    for (@addr) {
        $mac .= sprintf "0" x ( 4 - length($_) ) . "$_:";
    }
    $mac =~ s/:$//;
    $mac
      = "33:33:"
      . substr( $mac, -9, 2 ) . ":"
      . substr( $mac, -7, 5 ) . ":"
      . substr( $mac, -2 );

    if ( !defined $retType ) {
        print "$mac\n";
        return;
    } else {
        return $mac;
    }
}

sub ipv6SolicitNode {
    return ipv6SolicitedNode(@_);
}

sub ipv6SolNode {
    return ipv6SolicitedNode(@_);
}

sub ipv6SolicitedNode {
    my ($arg) = @_;

    if ( !defined($arg) or ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "SUBROUTINES/ipv6SolicitedNode - return IPv6 Solicited Node Address"
        );
    }

    my $retType = wantarray;

    my %solnode;
    my $addr = Net::IPv6Addr->new($arg);
    my ( undef, undef, undef, undef, undef, undef, @addr ) = split /:/,
      $addr->to_string_preferred;

    my $mac;
    for (@addr) {
        $mac .= sprintf "0" x ( 4 - length($_) ) . "$_:";
    }
    $mac =~ s/:$//;

    $solnode{address} = "ff02::1:ff" . substr( $mac, -7 );
    $solnode{mac}
      = "33:33:ff:" . substr( $mac, -7, 5 ) . ":" . substr( $mac, -2 );

    if ( !defined $retType ) {
        print "$solnode{address}\n$solnode{mac}\n";
        return;
    } elsif ($retType) {
        return bless %solnode, __PACKAGE__;
    } else {
        return bless \%solnode, __PACKAGE__;
    }
}

########################################################

sub address {
    my $self = shift;
    return $self->{address};
}

sub mac {
    my $self = shift;
    return $self->{mac};
}

1;

__END__

=head1 NAME

Multicast - Multicast Helper Module

=head1 SYNOPSIS

 use PPC::Plugin::Multicast;

=head1 DESCRIPTION

Provides routines for simplifying multicast Layer 2 and 3 addressing.

=head1 COMMANDS

=head2 Multicast - provide help

Provides help from the B<PPC> shell.

=head1 SUBROUTINES

=head2 ipv4MulticastMac - return IPv4 Multicast MAC

 [$ipv4MultiMac =] ipv4MulticastMac "ipv4_mcast_address"

Return Layer 2 multicast MAC address for provided Layer 3 IPv4 multicast address.

Alias:

=over 4

=item B<ipv4McastMac>

=item B<ipv4MultiMac>

=back

=head2 ipv6MulticastMac - return IPv6 Multicast MAC

 [$ipv6MultiMac =] ipv6MulticastMac "ipv6_mcast_address"

Return Layer 2 multicast MAC address for provided Layer 3 IPv6 multicast address.

Alias:

=over 4

=item B<ipv6McastMac>

=item B<ipv6MultiMac>

=back

=head2 ipv6SolicitedNode - return IPv6 Solicited Node Address

 [$ipv6SolNode =] ipv6SolicitedNode "ipv6_address"

Return IPv6 Solicited Node IPv6 address and MAC address for provided
B<name> or B<address>.

Alias:

=over 4

=item B<ipv6SolNode>

=item B<ipv6SolicitNode>

=back

Returns B<address> and B<mac> accessed with:

=over 4

=item B<address>

 $ipv6SolNode->address

Solicited node IPv6 address.

=item B<mac>

 $ipv6SolNode->mac

Solicited node MAC address.

=back

=head1 MACROS

=over 4

=item B<MULTICAST_IPv4_BASE>

=item B<MULTICAST_IPv4_ALL_HOSTS>

=item B<MULTICAST_IPv4_ALL_ROUTERS>

=item B<MULTICAST_IPv4_ALL_OSPF>

=item B<MULTICAST_IPv4_ALL_OSPF_DR>

=item B<MULTICAST_IPv4_RIPv2>

=item B<MULTICAST_IPv4_EIGRP>

=item B<MULTICAST_IPv4_PIMv2>

=item B<MULTICAST_IPv4_VRRP>

=item B<MULTICAST_IPv4_IGMPv3>

=item B<MULTICAST_IPv4_HSRPv2>

=item B<MULTICAST_IPv4_GLBP>

=item B<MULTICAST_IPv4_PTPv2>

=item B<MULTICAST_IPv4_mDNS>

=item B<MULTICAST_IPv4_LLMNR>

=item B<MULTICAST_IPv4_TEREDO>

=item B<MULTICAST_IPv4_NTP>

=item B<MULTICAST_IPv4_SLPv1>

=item B<MULTICAST_IPv4_SLPv1DA>

=item B<MULTICAST_IPv4_AUTORP_ANNOUNCE>

=item B<MULTICAST_IPv4_AUTORP_DISCOVER>

=item B<MULTICAST_IPv4_H323_GK>

=item B<MULTICAST_IPv4_SSDP>

=item B<MULTICAST_IPv4_SLPv2>

Various IPv4 well-known multicast addresses.

=item B<MULTICAST_IPv6_ALL_NODES>

=item B<MULTICAST_IPv6_ALL_ROUTERS>

=item B<MULTICAST_IPv6_ALL_OSPFv3>

=item B<MULTICAST_IPv6_ALL_OSPFv3_DR>

=item B<MULTICAST_IPv6_ISIS>

=item B<MULTICAST_IPv6_RIP>

=item B<MULTICAST_IPv6_EIGRP>

=item B<MULTICAST_IPv6_PIMv2>

=item B<MULTICAST_IPv6_MLDv2_REPORT>

=item B<MULTICAST_IPv6_ALL_DHCP>

=item B<MULTICAST_IPv6_ALL_LLMNR>

=item B<MULTICAST_IPv6_ALL_DHCP_SITE>

=item B<MULTICAST_IPv6_PTPv2>

Various IPv6 well-known multicast addresses.

=back

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
