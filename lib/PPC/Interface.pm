package PPC::Interface;

use strict;
use warnings;
use Carp;

our @ISA;

my %interfaceModule = (

    # Platform    # Module
    'MSWin32' => 'PPC::Interface::Win32',
    'linux'   => 'PPC::Interface::Linux',
    'darwin'  => 'PPC::Interface::Darwin',
    'Example' => 'PPC::Interface::Example',

    # 'UserAdd'  => 'PPC::Interface::<name>

    # LEAVE THIS LINE
    'FOUND' => 0,
);

# Platform dependent module require / import / @ISA
for ( keys(%interfaceModule) ) {
    if ( $^O eq $_ ) {

        # Must translate from :: to
        # PPC/Interface/name.pm
        my $interfaceModule = $interfaceModule{$_};
        $interfaceModule =~ s/::/\//g;

        require "$interfaceModule.pm";
        $interfaceModule{$_}->import;
        unshift @ISA, $interfaceModule{$_};

        $interfaceModule{FOUND} = 1;
        last;
    }
}

if ( !$interfaceModule{FOUND} ) {
    carp "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
      .  "! No PPC::Interface:: module found for architecture - $^O\n"
      .  "! Architectures are defined in PPC::Interface.\n"
      .  "! See PPC::Interface and PPC::Interface::Example.\n"
      .  "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n";
}

1;

__END__

=head1 NAME

PPC::Interface - PPC Interface abstraction layer

=head1 SYNOPSIS

  use PPC::Interface;

=head1 DESCRIPTION

This module provides an abstration layer between B<PPC> and the underlying 
module to handle the interface subroutines per Operating System or other 
architecture type.

=head1 TO DO

Currently only accounts for 'MSWin32', need to add more possibilities.

=head1 SEE ALSO

L<PPC::Interface::Example>, L<PPC::Interface::Win32>

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
