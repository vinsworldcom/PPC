package App::PerlShell::AddOns::ShellCommands;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

our $caller = caller;

my $App_PerlShell_AddOns_ShellCommands = "
package $caller;

our \$AUTOLOAD;

sub AUTOLOAD {
    my \$program = \$AUTOLOAD;
    my \$retType = wantarray;

    \$program =~ s/^.*:://;
    my \@rets = `\$program \@_`;

    if ( not defined \$retType ) {
        print \@rets;
        return;
    } elsif ( \$retType ) {
        return \@rets;
    } else {
        return \\\@rets;
    }
}

sub DESTROY { return }

1;
";

eval $App_PerlShell_AddOns_ShellCommands;

1;

__END__

########################################################
# Start POD
########################################################

=head1 NAME

App::PerlShell::AddOns::ShellCommands - Perl Shell Commands from OS Shell

=head1 SYNOPSIS

 plsh> use App::PerlShell::AddOns::ShellCommands;
 plsh> cat('filename.txt');

=head1 DESCRIPTION

B<App::PerlShell::AddOns::ShellCommands> provides an extension to 
B<App::PerlShell> to run commands from the operating system shell 
in the App::PerlShell.

=head1 SEE ALSO

L<App::PerlShell>

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2016 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
