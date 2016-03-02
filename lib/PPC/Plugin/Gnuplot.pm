package PPC::Plugin::Gnuplot;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

eval "use Chart::Gnuplot";
if ($@) {
    print "Chart::Gnuplot required.\n";
    return 1;
}

use Exporter;

our @EXPORT = qw(
  Gnuplot
  gnuplot
  gnuterm
  gnuscript
  chart
  dataset
);

our @ISA = qw ( PPC Exporter );

# Set gnuplot global config
$PPC::PPC_GLOBALS->add( 'gnuplot'      => 'gnuplot' );
$PPC::PPC_GLOBALS->add( 'gnuplot_term' => 'wxt' );

# Update gnuplot program location for Windows by searching Path/PathExt
if ( $^O eq 'MSWin32' ) {
    my @paths = split /;/, $ENV{'PATH'};
    my @exts  = split /;/, $ENV{'PATHEXT'};
    my $FOUND = 0;
    for my $path (@paths) {
        $path =~ s/\\$//;
        $path .= "\\";
        for my $ext (@exts) {
            my $gnuplot
              = $path . PPC::config('gnuplot') . "$ext";
            if ( -e $gnuplot ) {
                PPC::config( 'gnuplot' => $gnuplot );
                $FOUND++;
                last;
            }
            if ($FOUND) { last }
        }
    }
}

sub Gnuplot {
    PPC::_help_full( __PACKAGE__ );
}

########################################################

sub gnuplot {
    my %params = ( gnuplot => '' );

    if ( !$PPC::PPC_GLOBALS->exists('gnuplot') ) {
        PPC::_error( "Chart::Gnuplot required." );
    }

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__,
                "COMMANDS/gnuplot - get or set gnuplot program" );
        }
        ( $params{gnuplot} ) = $arg;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $params{gnuplot} = shift;
        }

        #%args = @_
    }

    if ( defined( $params{gnuplot} ) and ( $params{gnuplot} ne '' ) ) {
        PPC::config( 'gnuplot' => $params{gnuplot} );
    }
    if ( defined wantarray ) {
        return PPC::config('gnuplot');
    } else {
        print PPC::config('gnuplot') . "\n";
    }
}

sub gnuterm {
    my %params = ( gnuplot_term => '' );

    if ( !$PPC::PPC_GLOBALS->exists('gnuplot_term') ) {
        PPC::_error( "Chart::Gnuplot required." );
    }

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__,
                "COMMANDS/gnuterm - get or set gnuplot terminal" );
        }
        ( $params{gnuplot_term} ) = $arg;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $params{gnuplot_term} = shift;
        }

        #%args = @_
    }

    if ( defined( $params{gnuplot_term} )
        and ( $params{gnuplot_term} ne '' ) ) {
        PPC::config( 'gnuplot_term' => $params{gnuplot_term} );
    }
    if ( defined wantarray ) {
        return PPC::config('gnuplot_term');
    } else {
        print PPC::config('gnuplot_term') . "\n";
    }
}

sub gnuscript {
    my ($arg) = @_;

    if ( !defined($arg) or ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "COMMANDS/gnuscript - return Gnuplot script" );
    }

    my @rets;
    my $retType = wantarray;

    if ( ( ref $arg ) ne "" ) {
        if ( ( ref $arg ) =~ /^Chart::Gnuplot/ ) {
            if ( defined $retType ) {
                push @rets, $arg->{_script};
            } else {
                printf "%s\n", $arg->{_script};
            }
            my $fh;
            if ( !open( $fh, '<', $arg->{_script} ) ) { 
                PPC::_error( "Cannot open file - `" . $arg->{_script} . "'" );
            }
            my @lines = <$fh>;
            close($fh);

            for my $line (@lines) {
                chomp $line;
                my @parts = split / /, $line;
                for my $part (@parts) {
                    if ( $part =~ /[\/\\]data['"]$/ ) {
                        $part =~ s/'//g;
                        $part =~ s/"//g;
                        if ( defined($retType) ) {
                            push @rets, $part;
                        } else {
                            printf "%s\n", $part;
                        }
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
    }

    PPC::_error( "Not a valid Chart::Gnuplot object - `$arg'" );
}

########################################################

sub chart {
    my %params;

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__, "METHODS/chart - create chart object",
                "Chart::Gnuplot" );
        }
        $params{title} = $arg;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $params{title} = shift;
        }
        my %args = @_;
        for ( keys(%args) ) {
            $params{$_} = $args{$_};
        }
    }

    return Chart::Gnuplot->new(
        gnuplot  => PPC::config('gnuplot'),
        terminal => PPC::config('gnuplot_term'),
        %params
    );
}

sub dataset {
    my %params;

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__,
                "METHODS/dataset - create dataset object",
                "Chart::Gnuplot" );
        }
        $params{ydata} = $arg;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $params{ydata} = shift;
        }
        my %args = @_;
        for ( keys(%args) ) {
            $params{$_} = $args{$_};
        }
    }

    return Chart::Gnuplot::DataSet->new(%params);
}

1;

__END__

=head1 NAME

Gnuplot - Gnuplot

=head1 SYNOPSIS

 use PPC::Plugin::Gnuplot;

=head1 DESCRIPTION

This module implements Gnuplot integration with L<Chart::Gnuplot>.

=head1 COMMANDS

=head2 Gnuplot - provide help

Provides help from the B<PPC> shell.

=head2 gnuplot - get or set gnuplot program

 [$gnuplot =] gnuplot 'path_and_gnuplot_program'

Get or set B<gnuplot> program location.  No argument displays B<gnuplot> 
program location.  Single argument sets B<gnuplot> program location.  
Optional return value is B<gnuplot> program location.

=head2 gnuterm - get or set gnuplot terminal

 [$gnuterm =] gnuterm 'gnuplot_term_type'

Get or set B<gnuplot> terminal type.  No argument displays B<gnuplot> 
terminal type.  Single argument sets B<gnuplot> terminal type.  
Optional return value is B<gnuplot> terminal type.

=head2 gnuscript - return Gnuplot script

 [$script =] gnuscript $chart

Return the B<gnuplot> script created for $chart.  See B<chart> below.

=head1 METHODS

=head2 chart - create chart object

 [$chart =] chart [OPTIONS];

Create B<Chart::Gnuplot> object.  See B<Chart::Gnuplot> for B<OPTIONS>.  
Return B<Chart::Gnuplot> object.

Single option indicates B<title>.

=head2 dataset - create dataset object

 [$dataset =] dataset [OPTIONS];

Create B<Chart::Gnuplot::DataSet> object.  See B<Chart::Gnuplot> for B<OPTIONS>.  
Return B<Chart::Gnuplot::DataSet> object.

Single option indicates B<ydata>.

=head1 EXAMPLES

 chart->plot2d(dataset([0,1,2,3,4,5]));

=head1 SEE ALSO

L<Chart::Gnuplot>

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
