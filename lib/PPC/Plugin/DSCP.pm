package PPC::Plugin::DSCP;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

use Exporter;

our @EXPORT = qw(
  DSCP

  DSCP0
  DSCP2
  DSCP4
  DSCP6
  DSCP8
  DSCP10
  DSCP12
  DSCP14
  DSCP16
  DSCP18
  DSCP20
  DSCP22
  DSCP24
  DSCP26
  DSCP28
  DSCP30
  DSCP32
  DSCP34
  DSCP36
  DSCP38
  DSCP40
  DSCP42
  DSCP44
  DSCP46
  DSCP48
  DSCP50
  DSCP52
  DSCP54
  DSCP56
  DSCP58
  DSCP60
  DSCP62

  CS0
  CS1
  CS2
  CS3
  CS4
  CS5
  CS6
  CS7

  BE
  AF11
  AF12
  AF13
  AF21
  AF22
  AF23
  AF31
  AF32
  AF33
  AF41
  AF42
  AF43
  EF
);

our @ISA = qw ( PPC Exporter );

use constant DSCP0  => 0x00;
use constant DSCP2  => 0x08;
use constant DSCP4  => 0x10;
use constant DSCP6  => 0x18;
use constant DSCP8  => 0x20;
use constant DSCP10 => 0x28;
use constant DSCP12 => 0x30;
use constant DSCP14 => 0x38;
use constant DSCP16 => 0x40;
use constant DSCP18 => 0x48;
use constant DSCP20 => 0x50;
use constant DSCP22 => 0x58;
use constant DSCP24 => 0x60;
use constant DSCP26 => 0x68;
use constant DSCP28 => 0x70;
use constant DSCP30 => 0x78;
use constant DSCP32 => 0x80;
use constant DSCP34 => 0x88;
use constant DSCP36 => 0x90;
use constant DSCP38 => 0x98;
use constant DSCP40 => 0xa0;
use constant DSCP42 => 0xa8;
use constant DSCP44 => 0xb0;
use constant DSCP46 => 0xb8;
use constant DSCP48 => 0xc0;
use constant DSCP50 => 0xc8;
use constant DSCP52 => 0xd0;
use constant DSCP54 => 0xd8;
use constant DSCP56 => 0xe0;
use constant DSCP58 => 0xe8;
use constant DSCP60 => 0xf0;
use constant DSCP62 => 0xf8;

use constant CS0 => 0x00;
use constant CS1 => 0x20;
use constant CS2 => 0x40;
use constant CS3 => 0x60;
use constant CS4 => 0x80;
use constant CS5 => 0xa0;
use constant CS6 => 0xc0;
use constant CS7 => 0xe0;

use constant BE   => 0x00;
use constant AF11 => 0x28;
use constant AF12 => 0x30;
use constant AF13 => 0x38;
use constant AF21 => 0x48;
use constant AF22 => 0x50;
use constant AF23 => 0x58;
use constant AF31 => 0x68;
use constant AF32 => 0x70;
use constant AF33 => 0x78;
use constant AF41 => 0x88;
use constant AF42 => 0x90;
use constant AF43 => 0x98;
use constant EF   => 0xb8;

sub DSCP {
    PPC::_help_full( __PACKAGE__ );
}

1;

__END__

=head1 NAME

DSCP - Distributed Services Code Point constants

=head1 SYNOPSIS

 use PPC::Plugin::DSCP;

=head1 DESCRIPTION

This module implements DSCP values as constants.

=head1 COMMANDS

=head2 DSCP - provide help

Provides help from the B<PPC> shell.

=head1 CONSTANTS

=over 4

=item B<DSCP0>

=item B<DSCP2>

=item B<DSCP4>

=item B<DSCP6>

=item B<DSCP8>

=item B<DSCP10>

=item B<DSCP12>

=item B<DSCP14>

=item B<DSCP16>

=item B<DSCP18>

=item B<DSCP20>

=item B<DSCP22>

=item B<DSCP24>

=item B<DSCP26>

=item B<DSCP28>

=item B<DSCP30>

=item B<DSCP32>

=item B<DSCP34>

=item B<DSCP36>

=item B<DSCP38>

=item B<DSCP40>

=item B<DSCP42>

=item B<DSCP44>

=item B<DSCP46>

=item B<DSCP48>

=item B<DSCP50>

=item B<DSCP52>

=item B<DSCP54>

=item B<DSCP56>

=item B<DSCP58>

=item B<DSCP60>

=item B<DSCP62>

=item B<CS0>

=item B<CS1>

=item B<CS2>

=item B<CS3>

=item B<CS4>

=item B<CS5>

=item B<CS6>

=item B<CS7>

=item B<BE>

=item B<AF11>

=item B<AF12>

=item B<AF13>

=item B<AF21>

=item B<AF22>

=item B<AF23>

=item B<AF31>

=item B<AF32>

=item B<AF33>

=item B<AF41>

=item B<AF42>

=item B<AF43>

=item B<EF>

DSCP constants.

=back

=head1 SEE ALSO

L<PPC>, L<Net::Frame::Layer>

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
