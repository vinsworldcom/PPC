package PPC::Interface::Linux;

# TODO:2016-02-10:vincen_m:Finish PPC::Interface::Linux IPv6 accessors
# ->ipv6_gateway_mac       IPv6 default gateway MAC address   '00:11:22:aa:bb:cc'
# ->ipv6                   IPv6 address                       '2001:db8::a:b:c:d'
# ->ipv6_link_local        IPv6 link local address            'fe80::a:b:c:d'
# ->ipv6_default_gateway   IPv6 default gateway               '2001:db8::1'

use strict;
use warnings;

use IO::Interface::Simple;
our @ISA;
unshift @ISA, 'IO::Interface::Simple';

########################################################

sub mac {
    return IO::Interface::Simple::hwaddr(@_);
}

sub ipv4_gateway_mac {
    my ($if) = @_;

    my $gateway = $if->ipv4_default_gateway;
    my @ret = `arp $gateway`;

    my $name = $if->name;
    for my $line ( @ret ) {
        if ( $line =~ /$name/ ) {
            my (undef, undef, $mac) = split /\s+/, $line;
            return $mac;
        }
    }
    return;
}

sub ipv4 {
    return IO::Interface::Simple::address(@_);
}

sub ipv4_default_gateway {
    my ($if) = @_;

    my @ret = `route -n`;

    my $gateway;
    my $name = $if->name;
    for my $line ( @ret ) {
        if ( ( $line =~ /^0\.0\.0\.0/ ) and ( $line =~ /$name/ ) ) {
            (undef, $gateway) = split /\s+/, $line;
            return $gateway;
        }
    }
    return;
}

sub ipv6_gateway_mac {
    warn "NOT IMPLEMENTED in PPC::Interface::Linux [IO::Interface::Simple]\n";
}

sub ipv6 {
    warn "NOT IMPLEMENTED in PPC::Interface::Linux [IO::Interface::Simple]\n";
}

sub ipv6_link_local {
    warn "NOT IMPLEMENTED in PPC::Interface::Linux [IO::Interface::Simple]\n";
}

sub ipv6_default_gateway {
    warn "NOT IMPLEMENTED in PPC::Interface::Linux [IO::Interface::Simple]\n";
}

sub devicename {
    return IO::Interface::Simple::name(@_);
}

sub error {
    PPC::_error( "Error with IO::Interface::Simple" );
}

sub dump {
    my ($if) = @_;
    print 
          "broadcast  = ",$if->broadcast,"\n",
          "devicename = ",$if->devicename,"\n",
          "index      = ",$if->index,"\n",
          "ipv4       = ",$if->ipv4,"\n",
          "dstaddr    = ",$if->dstaddr,"\n",
          "mac        = ",$if->mac,"\n",
          "metric     = ",$if->metric,"\n",
          "mtu        = ",$if->mtu,"\n",
          "name       = ",$if->name,"\n",
          "netmask    = ",$if->netmask,"\n";
}

1;

__END__

=head1 NAME

PPC::Interface::Linx - PPC Interface abstraction layer for Linux

=head1 SYNOPSIS

  use PPC::Interface::Linux;

=head1 DESCRIPTION

This module provides an abstraction layer between B<PPC> and the underlying 
module to handle the interface subroutines on Linux architectures.

=head1 ACCESSORS

The following accessors are provided for B<PPC> standard API to access the 
B<IO::Interface::Simple> API.  All other required B<PPC> standard API is 
provided directly by B<IO::Interface::Simple> API.

=over 4

=item B<mac>

=item B<ipv4_gateway_mac>

=item B<ipv4>

=item B<ipv4_default_gateway>

=item B<ipv6_gateway_mac>

=item B<ipv6>

=item B<ipv6_link_local>

=item B<ipv6_default_gateway>

=item B<devicename>

=item B<error>

=item B<dump>

=back

=head1 TO DO

Implement IPv6 accessors.

=head1 SEE ALSO

L<IO::Interface::Simple>

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
