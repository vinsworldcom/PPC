package PPC::Interface::Win32;

use strict;
use warnings;

use Win32::Net::Info;
our @ISA;
unshift @ISA, "Win32::Net::Info";

1;

__END__

=head1 NAME

PPC::Interface::Win32 - PPC Interface abstraction layer for Win32

=head1 SYNOPSIS

  use PPC::Interface::Win32;

=head1 DESCRIPTION

This module provides an abstration layer between B<PPC> and the underlying 
module to handle the interface subroutines on Win32 architectures.

=head1 SEE ALSO

L<Win32::Net::Info>

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
