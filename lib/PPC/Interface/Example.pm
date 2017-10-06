package PPC::Interface::Example;

use strict;
use warnings;

# use Other::Interface::Module;
# our @ISA;
# unshift @ISA, 'Other::Interface::Module';

########################################################
# Between the three lines above and any subs defined below,
# the following accessors *must* be provided:
#
# Function / sub           Description                        Example
# ->new                    Create new object                  
#
# ->interfaces             Return list of available           'eth0
#                            interface names                  'eth1'
#                                                            ...etc...
#                                                              
# ->mac                    MAC address                        '00:11:22:aa:bb:cc'
# ->ipv4_gateway_mac       IPv4 default gateway MAC address   '00:11:22:aa:bb:cc'
# ->ipv4                   IPv4 address                       '192.168.10.10'
# ->ipv4_default_gateway   IPv4 default gateway               '192.168.10.1'
#
# ->ipv6_gateway_mac       IPv6 default gateway MAC address   '00:11:22:aa:bb:cc'
# ->ipv6                   IPv6 address                       '2001:db8::a:b:c:d'
# ->ipv6_link_local        IPv6 link local address            'fe80::a:b:c:d'
# ->ipv6_default_gateway   IPv6 default gateway               '2001:db8::1'
#
# ->name                   Interface Name                     'Ethernet0'
# ->devicename             Device Name                        'eth0'
# ->mtu                    MTU                                '1500'
#
# ->error                  Last error message
# ->dump                   Show all paramaters
#     Using Win32::Net::Info for example, ->dump produces:
#
#     'adaptername' => '{73777781-5FB3-4C71-944A-AAAABBBB8AA7}'
#     'description' => 'Dell Wireless 1397 WLAN Mini-Card'
#     'device' => '\Device\NPF_{73777781-5FB3-4C71-944A-AAAABBBB8AA7}'
#     'ifName' => 'Wireless Network Connection'
#     'ifindex' => '11'
#     'ipv4' => '192.168.10.107'
#     'ipv4_default_gateway' => '192.168.10.1'
#     'ipv4_gateway_mac' => '58:6d:8f:78:ad:40'
#     'ipv4_mtu' => '1500'
#     'ipv4_netmask' => '255.255.255.0'
#     'ipv6' => '2001:470:1f07:157c:e429:88a4:2e48:8203'
#     'ipv6_default_gateway' => 'fe80::5a6d:8fff:fe78:ad40'
#     'ipv6_gateway_mac' => '58:6d:8f:78:ad:40'
#     'ipv6_link_local' => 'fe80::e429:88a4:2e48:8203'
#     'ipv6_mtu' => '1480'
#     'mac' => 'c0:cb:38:08:46:76'

1;

__END__

=head1 NAME

PPC::Interface::Example - PPC Interface abstraction layer for Example

=head1 SYNOPSIS

  use PPC::Interface::Example;

=head1 DESCRIPTION

This module provides an abstraction layer between B<PPC> and the underlying 
module to handle the interface subroutines.

This example shows the relevant routines needed.

=head1 SEE ALSO

L<PPC::Interface>, L<PPC::Interface::Win32>

=head1 ACKNOWLEDGEMENTS

Special thanks to Patrice E<lt>GomoRE<gt> Auffret without whose
Net::Frame::[...] modules, this would not be possible.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2012 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
