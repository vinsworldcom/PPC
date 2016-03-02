package PPC::Plugin::P0f;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

my $p0f_dir  = '';
my $p0f_ext  = '';
my $p0f_temp = '/tmp/';
if ( $^O eq 'MSWin32' ) {
    $p0f_temp = $ENV{'TEMP'};
    my @paths = split /;/, $ENV{'PATH'};
    my @exts  = split /;/, $ENV{'PATHEXT'};
    my $FOUND = 0;
    for my $path (@paths) {
        $path =~ s/\\$//;
        $path .= "\\";
        for my $ext (@exts) {
            my $p0f = $path . 'p0f' . "$ext";
            if ( -e $p0f ) {
                $p0f_dir = $path;
                $p0f_ext = $ext;
                $FOUND++;
                last;
            }
            if ($FOUND) { last }
        }
    }
    if ( !$FOUND ) {
        print "p0f.exe required\n";
        return 1;
    }
}

use Exporter;

our @EXPORT = qw(
  P0f
  p0f
  p0ffp
);

our @ISA = qw ( PPC Exporter );

# Set p0f global config
$PPC::PPC_GLOBALS->add( 'p0f'   => $p0f_dir . 'p0f' . $p0f_ext );
$PPC::PPC_GLOBALS->add( 'p0ffp' => $p0f_dir . 'p0f.fp' );

sub P0f {
    PPC::_help_full(__PACKAGE__);
}

########################################################

sub p0f {
    my %params = ( argv => '' );

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__,
                "COMMANDS/p0f - run p0f on provided packets" );
        }
        ( $params{packet} ) = $arg;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $params{packet} = shift;
        }
        my %args = @_;
        for ( keys(%args) ) {
            if (/^-?arg(?:v|s)?$/i) {
                $params{argv} = $args{$_};
            } else {
                PPC::_error("Unknown parameter: `$_'");
            }
        }
    }

    if ( !defined $params{packet} ) {
        PPC::_error('No packet to analyze');
    }

    my $temp_file = $p0f_temp . '/' . time . '.pcap';
    my $ret = PPC::wrpcap( $temp_file, $params{packet} );

    system( PPC::config('p0f') . ' -f '
          . PPC::config('p0ffp') . ' -r '
          . $temp_file . ' '
          . $params{argv} );

    unlink $temp_file;
}

sub p0ffp {
    my %params = ( p0ffp => '' );

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__,
                "COMMANDS/p0ffp - get or set p0f fingerprint database location"
            );
        }
        ( $params{p0ffp} ) = $arg;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $params{p0ffp} = shift;
        }

        #%args = @_
    }

    if ( defined( $params{p0ffp} )
        and ( $params{p0ffp} ne '' ) ) {
        PPC::config( 'p0ffp' => $params{p0ffp} );
    }
    if ( defined wantarray ) {
        return PPC::config('p0ffp');
    } else {
        print PPC::config('p0ffp') . "\n";
    }
}

1;

__END__

=head1 NAME

P0f - Passive OS Fingerprinting

=head1 SYNOPSIS

 use PPC::Plugin::P0f;

=head1 DESCRIPTION

This module implements P0f integration with C<p0f>.

=head1 COMMANDS

=head2 P0f - provide help

Provides help from the B<PPC> shell.

=head2 p0f - run p0f on provided packets

 p0f $packet | \@packet [OPTIONS]

Run C<p0f> on provided packets.  Single option is packet or reference to 
an array of packets, generally in B<PPC::Packet> objects.

  Option     Description                       Default Value
  ------     -----------                       -------------
  argv       Argument string to pass to the    (none)
               p0f external program

=head2 p0ffp - get or set p0f fingerprint database location

 [$p0ffp =] p0ffp 'p0f_fingerprint_database'

Get or set B<p0f> fingerprint database location.  No argument displays 
B<p0f> fingerprint database location.  Single argument sets B<p0f> 
fingerprint database location.  Optional return value is B<p0f> 
fingerprint database location.

=head1 SEE ALSO

C<p0f>, http://lcamtuf.coredump.cx/p0f3/

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
