package PerlApp::Shell::ModRefresh;
# TODO:2016-03-01:vincen_m:POD
########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

our $VERSION = "0.06";

use Module::Refresh;

our @ISA = qw( Module::Refresh );

sub refresh {
    my $self = shift;
    my $package = shift;

    return $self->new if !%Module::Refresh::CACHE;

    foreach my $mod ( sort keys %INC ) {
        $self->refresh_module_if_modified($mod, $package);
    }
    return ($self);
}

sub refresh_module_if_modified {
    my $self = shift;
    return $self->new if !%Module::Refresh::CACHE;
    my $mod = shift;
    my $package = shift;

    if (!$INC{$mod}) {
        return;
    } elsif ( !$Module::Refresh::CACHE{$mod} ) {
        $self->update_cache($mod);
    } elsif ( $self->mtime( $INC{$mod} ) ne $Module::Refresh::CACHE{$mod} ) {
        $self->refresh_module($mod, $package);
    }

}

sub refresh_module {
    my $self = shift;
    my $mod  = shift;
    my $package = shift;

    $self->unload_module($mod);

    local $@;
    my $name = $mod;
    $name =~ s/\//::/g;
    $name =~ s/\.pm$//;
    eval "package $package; require \"$mod\"; ($name)->import;";
    if ( $@ ) {
        warn $@;
    }

    $self->update_cache($mod);

    return ($self);
}

1;

__END__

########################################################
# Start POD
########################################################

=head1 NAME

PerlApp::Shell::ModRefresh - Perl Shell Module Refresh

=head1 SYNOPSIS

 use PerlApp::Shell;
 $shell->run;

=head1 DESCRIPTION

B<PerlApp::Shell::ModRefresh> provides an extension to B<PerlApp::Shell> to 
automatically refresh used modules if they change on disk between commands 
issued at the shell prompt.  It uses B<Module::Refresh> to accomplish this.  
If B<Module::Refresh> is not installed, this feature is not available.

=head1 METHODS

Several methods and accessors are provided and some override the 
B<Module::Refresh> ones.  These are called as-needed from the 
B<PerlApp::Shell> C<run> method.

=over 4

=item B<refresh>

=item B<refresh_module_if_modified>

=item B<refresh_module>

=back

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2016 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
