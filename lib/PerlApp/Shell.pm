package PerlApp::Shell;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;
use Carp;

our $VERSION = "0.07";

use Cwd;
use Term::ReadLine;
use Exporter;
my $HAVE_LexPersist = 0;
eval "use PerlApp::Shell::LexPersist";
if ( !$@ ) {
    $HAVE_LexPersist = 1;
}
my $HAVE_ModRefresh = 0;
eval "use PerlApp::Shell::ModRefresh";
if ( !$@ ) {
    $HAVE_ModRefresh = 1;
}

our @EXPORT
  = qw (cd cls clear dir error help ls modules pwd session variables);

our @ISA = qw ( Exporter );

our $LASTERROR;

sub _shellCommands {
    return (
        cd        => 'change directory',
        cls       => 'clear screen',
        clear     => 'clear screen',
        debug     => 'print command',
        dir       => 'directory listing',
        error     => 'print last error',
        exit      => 'exit shell',
        help      => 'shell help - print this',
        ls        => 'directory listing',
        modules   => 'list used modules',
        pwd       => 'print working directory',
        session   => 'start / stop logging session',
        variables => 'list defined variables'
    );
}

sub new {
    my $self = shift;
    my $class = ref($self) || $self;

    # Default parameters
    my %params = (
        homedir => ( $^O eq "MSWin32" ) ? $ENV{USERPROFILE} : $ENV{HOME},
        package => __PACKAGE__,
        prompt  => 'Perl> '
    );

    my $lex = 0;
    if ( @_ == 1 ) {
        croak("Insufficient number of args - @_");
    } else {
        my %cfg = @_;
        for ( keys(%cfg) ) {
            if (/^-?homedir$/i) {
                if ( -d $cfg{$_} ) {
                    $params{homedir} = $cfg{$_};
                } else {
                    croak("Cannot find directory `$cfg{$_}'");
                }
            } elsif (/^-?execute$/i) {
                $params{execute} = $cfg{$_};
            } elsif (/^-?lex(?:ical)?$/i) {
                $lex = 1;
            } elsif (/^-?package$/i) {
                $params{package} = $cfg{$_};
            } elsif (/^-?prompt$/i) {
                $params{prompt} = $cfg{$_};
            } elsif (/^-?session$/i) {

                # assign, will test open in run()
                $params{session} = $cfg{$_};
            } elsif (/^-?skipvars$/i) {
                if ( ref $cfg{$_} eq 'ARRAY' ) {
                    $params{skipvars} = $cfg{$_};
                } else {
                    croak("Not array reference `$cfg{$_}'");
                }
            } else {
                croak("Unknown parameter `$_' => `$cfg{$_}'");
            }
        }
    }

    if ($lex) {
        if ($HAVE_LexPersist) {
            $params{shellLexEnv}
              = PerlApp::Shell::LexPersist->new( $params{package} );
        } else {
            croak(
                "-lexical specified, `Lexical::Persistence' required but not found"
            );
        }
    } else {
        $ENV{PERLSHELL_PACKAGE} = $params{package};
    }
    $ENV{PERLSHELL_HOME}   = $params{homedir};
    $ENV{PERLSHELL_PROMPT} = $params{prompt};
    if ( defined $params{skipvars} ) {
        $ENV{PERLSHELL_SKIPVARS} = join ';', @{$params{skipvars}};
    }

    # clean up object
    delete $params{homedir};
    delete $params{package};
    delete $params{prompt};
    delete $params{skipvars};
    return bless \%params, $class;
}

sub run {
    my $PerlApp_Shell = shift;

    # handle session if requested
    if ( defined $PerlApp_Shell->{session} ) {
        if ( !defined session( $PerlApp_Shell->{session} ) ) {
            croak("Cannot open session file `$PerlApp_Shell->{session}'");
        }
    }

    if ( exists $PerlApp_Shell->{shellLexEnv} ) {
        $PerlApp_Shell->{shell}
          = $PerlApp_Shell->{shellLexEnv}->get_package();
    } else {
        $PerlApp_Shell->{shell} = $ENV{PERLSHELL_PACKAGE};
    }
    $PerlApp_Shell->{shell} = Term::ReadLine->new( $PerlApp_Shell->{shell} );
    $PerlApp_Shell->{shell}->ornaments(0);

    #'use strict' is not used to allow "$p=" instead of "my $p=" at the prompt
    no strict 'vars';

    # will always exeucte without readline first time through (do ... while)
    while (1) {

        # do ... while loop won't support next and last
        # First check then clear {execute} to autopopulate
        # $PerlApp_Shell->{shellCmdLine}
        # otherwise, just do the readline.

        if ( defined $PerlApp_Shell->{execute} ) {
            $PerlApp_Shell->{shellCmdLine} = $PerlApp_Shell->{execute};

            # clear - it will never happen again
            delete $PerlApp_Shell->{execute};
        } else {
            $PerlApp_Shell->{shellCmdLine}
              .= $PerlApp_Shell->{shell}->readline(
                ( defined $PerlApp_Shell->{shellCmdLine} )
                ? 'More? '
                : $ENV{PERLSHELL_PROMPT}
              );
        }

        chomp $PerlApp_Shell->{shellCmdLine};

        # nothing
        if ( $PerlApp_Shell->{shellCmdLine} =~ /^\s*$/ ) {
            undef $PerlApp_Shell->{shellCmdLine};
            next;
        }

        # exit
        if ( $PerlApp_Shell->{shellCmdLine} =~ /^\s*exit\s*(;)?\s*$/ ) {
            if ( !defined $1 ) { $PerlApp_Shell->{shellCmdLine} .= ';'; }
            last;
        }

        # debug multiline
        if ( $PerlApp_Shell->{shellCmdLine} =~ /\ndebug$/ ) {
            $PerlApp_Shell->{shellCmdLine} =~ s/debug$//;
            print "$PerlApp_Shell->{shellCmdLine}\n";
            next;
        }

        # variables if in -lexical
        if ( exists $PerlApp_Shell->{shellLexEnv} ) {
            if ( $PerlApp_Shell->{shellCmdLine} =~ /^\s*variables\s*;\s*$/ ) {
                for my $var (
                    sort( keys(
                            %{  $PerlApp_Shell->{shellLexEnv}
                                  ->get_context('_')
                            }
                    ) )
                  ) {
                    print "$var\n";
                }
                undef $PerlApp_Shell->{shellCmdLine};
                next;
            }
        }

        # Complete statement
        %{$PerlApp_Shell->{shellCmdComplete}} = (
            'parenthesis' => 0,
            'bracket'     => 0,
            'brace'       => 0
        );
        if ( my @c = ( $PerlApp_Shell->{shellCmdLine} =~ /\(/g ) ) {
            $PerlApp_Shell->{shellCmdComplete}->{parenthesis}
              += scalar(@c);
        }
        if ( my @c = ( $PerlApp_Shell->{shellCmdLine} =~ /\)/g ) ) {
            $PerlApp_Shell->{shellCmdComplete}->{parenthesis}
              -= scalar(@c);
        }
        if ( my @c = ( $PerlApp_Shell->{shellCmdLine} =~ /\[/g ) ) {
            $PerlApp_Shell->{shellCmdComplete}->{bracket} += scalar(@c);
        }
        if ( my @c = ( $PerlApp_Shell->{shellCmdLine} =~ /\]/g ) ) {
            $PerlApp_Shell->{shellCmdComplete}->{bracket} -= scalar(@c);
        }
        if ( my @c = ( $PerlApp_Shell->{shellCmdLine} =~ /\{/g ) ) {
            $PerlApp_Shell->{shellCmdComplete}->{brace} += scalar(@c);
        }
        if ( my @c = ( $PerlApp_Shell->{shellCmdLine} =~ /\}/g ) ) {
            $PerlApp_Shell->{shellCmdComplete}->{brace} -= scalar(@c);
        }

        if ((      ( $PerlApp_Shell->{shellCmdLine} =~ /,\s*$/ )
                or ( $PerlApp_Shell->{shellCmdComplete}->{parenthesis} != 0 )
                or ( $PerlApp_Shell->{shellCmdComplete}->{bracket} != 0 )
                or ( $PerlApp_Shell->{shellCmdComplete}->{brace} != 0 )
            )
            or

            # valid endings are ; or }, but only if all groupings are closed
            (       ( $PerlApp_Shell->{shellCmdLine} !~ /(;|\})\s*$/ )
                and ( $PerlApp_Shell->{shellCmdComplete}->{parenthesis} == 0 )
                and ( $PerlApp_Shell->{shellCmdComplete}->{bracket} == 0 )
                and ( $PerlApp_Shell->{shellCmdComplete}->{brace} == 0 )
            )
          ) {
            $PerlApp_Shell->{shellCmdLine} .= "\n";
            next;
        }

        # import subs if not default package
        # use redundant code in the if block so no variables are
        # created at top level in case we're not using LexPersist
        if ( exists $PerlApp_Shell->{shellLexEnv} ) {
            if ( $PerlApp_Shell->{shellLexEnv}->get_package() ne __PACKAGE__ )
            {
                my $sp = $PerlApp_Shell->{shellLexEnv}->get_package();
                my $p  = __PACKAGE__;
                eval "package $sp; $p->import;";
                if ($HAVE_ModRefresh) {
                    PerlApp::Shell::ModRefresh->refresh($sp);
                }
            }

            # execute
            eval {
                $PerlApp_Shell->{shellLexEnv}
                  ->do( $PerlApp_Shell->{shellCmdLine} );
            };
        } else {
            if ( $ENV{PERLSHELL_PACKAGE} ne __PACKAGE__ ) {
                my $sp = $ENV{PERLSHELL_PACKAGE};
                my $p  = __PACKAGE__;
                eval "package $sp; $p->import;";
                if ($HAVE_ModRefresh) {
                    PerlApp::Shell::ModRefresh->refresh($sp);
                }
            }
            $PerlApp_Shell->{shellCmdLine}
              = "package "
              . $ENV{PERLSHELL_PACKAGE} . ";\n"
              . $PerlApp_Shell->{shellCmdLine}
              . "\nBEGIN {\$ENV{PERLSHELL_PACKAGE} = __PACKAGE__}";

            # execute
            eval $PerlApp_Shell->{shellCmdLine};
        }

        # error from execute?
        if ($@) {
            warn $@;
            $LASTERROR = $PerlApp_Shell->{shellCmdLine};
        }

        # logging if requested and no error
        if ( defined( $ENV{PERLSHELL_SESSION} ) and !$@ ) {

            # don't log session start command
            $PerlApp_Shell->{shellCmdLine} =~ s/\s*session\s*.*//;

            # clean up command if we added stuff while not in -lex mode
            $PerlApp_Shell->{shellCmdLine} =~ s/^package .*;\n//;
            $PerlApp_Shell->{shellCmdLine}
              =~ s/(?:\n)?BEGIN \{\$ENV\{PERLSHELL_PACKAGE\} = __PACKAGE__\}//;

            open( my $OUT, '>>', $ENV{PERLSHELL_SESSION} );
            print $OUT "$PerlApp_Shell->{shellCmdLine}\n"
              if ( $PerlApp_Shell->{shellCmdLine} ne '' );
            close $OUT;
        }

        # reset to normal before next input
        undef $PerlApp_Shell->{shellCmdLine};
        print "\n";
    }
}

sub error {
    my $err = $LASTERROR;
    undef $LASTERROR;

    if ( defined wantarray ) {
        return $err;
    } else {
        if ( defined $err ) {
            print $err . "\n";
        }
    }
}

########################################################
# commands
########################################################

sub cd {
    my ($arg) = @_;

    my $ret = getcwd;
    if ( !defined $arg ) {
        chdir $ENV{PERLSHELL_HOME};
    } else {
        if ( -e $arg ) {
            chdir $arg;
        } else {
            print "Cannot find directory `$arg'\n";
        }
    }
    if ( defined wantarray ) {
        return $ret;
    }
}

sub cls {
    return clear();
}

sub clear {
    if ( $^O eq "MSWin32" ) {
        system('cls');
    } else {
        system('clear');
    }
}

sub help {
    my %cmds = _shellCommands();
    for my $h ( sort( keys(%cmds) ) ) {
        printf "%-15s %s\n", $h, $cmds{$h};
    }
}

sub dir {
    return ls(@_);
}

sub ls {
    my (@arg) = @_;

    my $dircmd;
    if ( $^O eq "MSWin32" ) {
        $dircmd = 'dir';
    } else {
        $dircmd = 'ls';
    }

    my @ret;
    my $retType = wantarray;
    if ( !defined $retType ) {
        system( $dircmd, @arg );
    } else {
        @ret = `$dircmd @arg`;
        if ($retType) {
            return @ret;
        } else {
            return \@ret;
        }
    }
}

sub modules {
    my ($arg) = @_;

    my %rets;
    my $retType = wantarray;

    my $FOUND = 0;
    for my $m ( sort( keys(%INC) ) ) {
        my $t = $m;
        $t =~ s/\//::/g;
        $t =~ s/\.pm$//;
        my $value = $INC{$m};

        if ( defined $arg ) {
            if ( $t =~ /$arg/ ) {
                if ( !defined $retType ) {
                    printf "$t %s\n",
                      ( defined $value ) ? $value : "[NOT LOADED]";
                } else {
                    $rets{$t} = $value;
                }
                $FOUND = 1;
            }
        } else {
            if ( !defined $retType ) {
                printf "$t %s\n",
                  ( defined $value ) ? $value : "[NOT LOADED]";
            } else {
                $rets{$t} = $value;
            }
            $FOUND = 1;
        }
    }

    if ( !$FOUND ) {
        printf "Module(s) not found%s",
          ( defined $arg ) ? " - `$arg'\n" : "\n";
    }

    if ( !defined $retType ) {
        return;
    } elsif ($retType) {
        return %rets;
    } else {
        return \%rets;
    }
}

sub pwd {
    if ( !defined wantarray ) {
        print getcwd;
    } else {
        return getcwd;
    }
}

sub session {
    my ($arg) = @_;

    if ( !defined $arg ) {
        if ( defined $ENV{PERLSHELL_SESSION} ) {
            if ( !defined wantarray ) {
                print $ENV{PERLSHELL_SESSION} . "\n";
            }
            return $ENV{PERLSHELL_SESSION};
        } else {
            if ( !defined wantarray ) {
                print "No current session file\n";
            }
            return undef;
        }
    }

    if ( $arg eq ":close" ) {
        if ( defined $ENV{PERLSHELL_SESSION} ) {
            if ( !defined wantarray ) {
                print "$ENV{PERLSHELL_SESSION} closed\n";
            }
            $ENV{PERLSHELL_SESSION} = undef;
            return;
        } else {
            if ( !defined wantarray ) {
                print "No current session file\n";
            }
            return undef;
        }
    }

    if ( !defined $ENV{PERLSHELL_SESSION} ) {
        if ( -e $arg ) {
            if ( !defined wantarray ) {
                print "File `$arg' exists - will append\n";
            }
        }

        if ( open( my $fh, '>>', $arg ) ) {
            close $fh;
            $ENV{PERLSHELL_SESSION} = $arg;
            if ( !defined wantarray ) {
                print $ENV{PERLSHELL_SESSION} . "\n";
            }
            return $ENV{PERLSHELL_SESSION};
        } else {
            if ( !defined wantarray ) {
                print "Cannot open file `$arg' for writing\n";
            }
            return undef;
        }
    } else {
        if ( !defined wantarray ) {
            print "Session file already open - `$ENV{PERLSHELL_SESSION}'\n";
        }
        return;
    }
}

sub variables {

    my %SKIP = (
        '$LASTERROR' => 1,
        '$VERSION'   => 1,
        '@ISA'       => 1,
        '@EXPORT'    => 1
    );

    if ( !exists $ENV{PERLSHELL_PACKAGE} ) {
        print "In -lexical mode, try again on line by iteslf\n";
        return;
    }

    if ( defined $ENV{PERLSHELL_SKIPVARS} ) {
        for ( split /;/, $ENV{PERLSHELL_SKIPVARS} ) {
            $SKIP{"$_"} = 1;
        }
    }

    my @rets;
    my $retType = wantarray;

    no strict 'refs';
    for my $var ( sort( keys( %{$ENV{PERLSHELL_PACKAGE} . '::'} ) ) ) {
        if ( defined( ${$ENV{PERLSHELL_PACKAGE} . "::$var"} )
            and !defined( $SKIP{'$' . $var} ) ) {
            if ( !defined $retType ) {
                print "\$$var\n";
            } else {
                push @rets, "\$$var";
            }
        } elsif ( @{$ENV{PERLSHELL_PACKAGE} . "::$var"}
            and !defined( $SKIP{'@' . $var} ) ) {
            if ( !defined $retType ) {
                print "\@$var\n";
            } else {
                push @rets, "\@$var";
            }
        } elsif ( %{$ENV{PERLSHELL_PACKAGE} . "::$var"}
            and !defined( $SKIP{'%' . $var} ) ) {
            if ( !defined $retType ) {
                print "\%$var\n";
            } else {
                push @rets, "\%$var";
            }
        }
    }

    if ( !defined $retType ) {
        return;
    } elsif ($retType) {
        return @rets;
    } else {
        return \@rets;
    }
}

1;

__END__

########################################################
# Start POD
########################################################

=head1 NAME

PerlApp::Shell - Perl Shell

=head1 SYNOPSIS

 use PerlApp::Shell;
 my $shell = PerlApp::Shell->new();
 $shell->run;

=head1 DESCRIPTION

B<PerlApp::Shell> creates an interactive Perl shell.  From it, 
Perl commands can be executed.  There are some additional commands 
helpful in any interactive shell.

=head2 Why Yet Another Perl Shell?

I needed an interactive Perl Shell for some Perl applications I was 
writing and found several options on CPAN:

=over 2

=item *

Perl::Shell

=item *

perlconsole

=item *

Devel::REPL

=back

All of which are excellent modules, but none had everything I wanted 
without a ton of external dependencies.  I didn't want that trade off; 
I wanted functions B<without> dependencies.

I also wanted to emulate a shell - not necessarily a REPL 
(Read-Evaluate-Parse-Loop).  In the way sh, Bash, csh and others *nix or 
cmd.exe on Windows are a shell - I wanted a Perl Shell.  For example, 
many of the above modules will evaluate an expression:

 5+1
 6

If I enter "5+1" in cmd.exe or Bash, I don't get 6, I get an error.  In a 
Perl program, if I have a line "5+1;", I get an error in execution.  If I 
really want "6", I need to "print 5+1;".  And so it should be in the Perl 
Shell.

This is much closer to a command prompt / terminal than a REPL.  As such, 
some basic shell commands are provided, like 'ls', 'cd' and 'pwd' for 
example.

=head1 CAVEATS

For command recall using the up/down arrows in *nix, you will need 
B<Term::ReadLine::Gnu> installed.  This module will function fine without 
it as B<Term::ReadLine> is a core module; however, command recall using 
the up/down arrows will not work.

=head1 METHODS

=head2 new() - create a new Shell object

  my $shell = PerlApp::Shell->new([OPTIONS]);

Create a new B<PerlApp::Shell> object with OPTIONS as optional parameters.
Valid options are:

  Option     Description                             Default
  ------     -----------                             -------
  -execute   Valid Perl code ending statements with  (none)
             semicolon (;).
  -homedir   Specify home directory.                 $ENV{HOME} or
             Used for `cd' with no argument.         $ENV{USERPROFILE}
  -lexical   Require "my" for variables.             (off)
             Requires Lexical::Persistence
  -package   Package to impersonate.  Execute all    PerlApp::Shell
             commands as if in this package.
  -prompt    Shell prompt.                           Perl>
  -session   Session file to log commands.           (none)
  -skipvars  Variables to ignore in `variables'      $LASTERROR, @ISA,
             command.                                $VERSION, @EXPORT

=head2 run() - run the shell

  $shell->run();

Run the shell.  Provides interactive environment for entering commands.

=head1 COMMANDS

In the interactive shell, all valid Perl commands can be entered.  This 
includes constructs like 'for () {}' and 'if () {} ... else {}' as well 
as any subs from 'use'ed modules.  The following are also provided.

=over 4

=item B<cd> [('directory')]

Change directory to optional 'directory'.  No argument changes to 'homedir'.  
Optional return value is current directory (directory before change).

=item B<clear>

=item B<cls>

Clear screen.

=item B<debug>

Print command so far (don't execute) at multiline input 'More?' prompt.  Must 
be used as C<debug> only, no semicolon starting at first position in input.

=item B<dir> [('OPTIONS')]

=item B<ls> [('OPTIONS')]

Directory listing.  'OPTIONS' are system directory listing command options.  
Optional return value is array of output.

=item B<error>

Print last error.

=item B<exit>

Exit shell.

=item B<help>

Display shell help.

=item B<modules> [('SEARCH')]

Displays used modules.  With 'SEARCH', displays matching used modules.  
Optional return value is hash with module names as keys and file 
locations as values.

=item B<pwd>

Print working directory.  Optional return value is result.

=item B<session> ('file')

Open session file.  Only logs Perl commands.  Appends to already existing 
file.  Use C<session (':close')> to end.

=item B<variables>

List user defined variables currently active in current package in shell.

=back

=head1 EXPORT

cd, cls, clear, dir, error, help, ls, modules, pwd, session, variables

=head1 EXAMPLES

This distribution comes with a script (installed to the default
"bin" install directory) that not only demonstrates example uses but also
provides functional execution.

=head1 SEE ALSO

L<PerlApp::Config>, L<PerlApp::Shell::ModRefresh>, L<PerlApp::Shell::LexPersist>

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2015 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
