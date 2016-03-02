package PPC::Layer::GRE;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

my $minver_GRE = 1.05;
my $HAVE_GRE   = 0;
eval "use Net::Frame::Layer::GRE $minver_GRE qw( :consts )";
if ( !$@ ) {
    $HAVE_GRE = 1;
}

use Exporter;

our @EXPORT = qw ( GRE );

our @ISA = qw ( PPC::Layer Exporter );

########################################################

sub GRE {
    my %params;

    if ( !$HAVE_GRE ) {
        PPC::Layer::_err_not_installed( "GRE", $minver_GRE );
    }

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__, "COMMANDS/GRE - create GRE layer",
                "Net::Frame::Layer::GRE" );
        }
        $params{protocol} = $arg;
    } else {
        my %args = @_;
        for ( keys(%args) ) {
            $params{$_} = $args{$_};
        }
    }

    my $p = PPC::Layer::_layer( "GRE", %params );
    if ( !defined wantarray ) {
        print $p->print . "\n";
    }
    return $p;
}

1;

package PPC;
eval "use Net::Frame::Layer::GRE $minver_GRE qw( :consts )";
1;

__END__

=head1 COMMANDS

=head2 GRE - create GRE layer

 $gre = GRE [(Net::Frame::Layer::GRE options)]

Creates B<$gre> variable as GRE layer.  Uses options from
B<Net::Frame::Layer::GRE>.

Single option indicates protocol.

=cut
