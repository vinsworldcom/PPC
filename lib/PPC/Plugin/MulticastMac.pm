package PPC::Plugin::MulticastMac;

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
  MulticastMac
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

sub MulticastMac {
    PPC::_help_full( __PACKAGE__ );
}

########################################################

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

MulticastMac - Multicast MAC Addresses

=head1 SYNOPSIS

 use PPC::Plugin::MulticastMac;

=head1 DESCRIPTION

Returns multicast Layer 2 MAC address for provided Layer 3 multicast address.

=head1 COMMANDS

=head2 MulticastMac - provide help

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
