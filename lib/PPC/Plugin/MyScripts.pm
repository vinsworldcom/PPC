package PPC::Plugin::MyScripts;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

use Exporter;

our @EXPORT = qw(
  MyScripts
  myscripts
);

our @ISA = qw ( PPC Exporter );

# Set global config
my $home_dir = ( $^O eq "MSWin32" ) ? $ENV{USERPROFILE} : $ENV{HOME};
if ( $home_dir !~ /[\/\\]$/ ) {
    $home_dir .= '/';
}
$PPC::PPC_GLOBALS->add( 'myscripts_dir' => $home_dir );

sub MyScripts {
    PPC::_help_full(__PACKAGE__);
}

########################################################

sub myscripts {
    my ($arg) = @_;

    if ( !$PPC::PPC_GLOBALS->exists('myscripts_dir') ) {
        PPC::_error( "Cannot find config - `myscripts_dir'" );
    }

    if ( defined($arg) and ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "COMMANDS/myscripts - execute scripts from my script directory" );
    }

    my $errmode = PPC::config( 'errmode' => 'continue' );
    my $scripts_dir
      = PPC::config( 'scripts_dir' => PPC::config('myscripts_dir') );

    PPC::scripts(@_);

    PPC::config( 'errmode'     => $errmode );
    PPC::config( 'scripts_dir' => $scripts_dir );
}

sub import {
    my $pkg = shift;
    my @symbols;

    my ($dir) = @_;
    if ( ( defined $dir ) and ( -d $dir ) ) {
        if ( $dir !~ /[\/\\]$/ ) {
            $dir .= '/';
        }
        PPC::config( 'myscripts_dir' => $dir );
        shift @_;
    }
    @_ = ( $pkg, @_ );
    __PACKAGE__->export_to_level(1, @_)
}

1;

__END__

=head1 NAME

MyScripts - My Scripts Directory

=head1 SYNOPSIS

 use PPC::Plugin::MyScripts ['dir'];

=head1 DESCRIPTION

This module implements a C<myscritps> command similar to the C<scripts> 
command that allows for a custom directory without changing the 
B<scripts_dir> default.

=head1 METHODS

There are no public methods.

=over 4

=item B<import>

Not called by user, allows the ['dir'] optional argument passed in the 
B<use> statement as show in SYNOPSIS to be used as the B<myscripts_dir>.

=back

=head1 COMMANDS

=head2 MyScripts - provide help

Provides help from the B<PPC> shell.

=head2 myscripts - execute scripts from my script directory

 [@scripts =] myscripts ["script"]

Shortcut to B<file> command to open a script in the custom B<myscripts_dir> 
directory without having to provide the path.  Called with no argument lists 
contents of my scripts directory.  Optional return value is array of files 
in the B<myscripts_dir> directory.

See B<file> for additional options, including passing parameters to a script.

=head1 SEE ALSO

L<PPC>

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
