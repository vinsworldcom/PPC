package PPC::Layer::PPP;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

my $minver_PPP = '';
my $HAVE_PPP   = 0;
eval "use Net::Frame::Layer::PPP $minver_PPP qw( :consts )";
if ( !$@ ) {
    $HAVE_PPP = 1;
}

use Exporter;

our @EXPORT = qw ( PPP );

our @ISA = qw ( PPC::Layer Exporter );

########################################################

sub PPP {
    my %params;

    if ( !$HAVE_PPP ) {
        PPC::Layer::_err_not_installed( "PPP", $minver_PPP );
    }

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__, "COMMANDS/PPP - create PPP layer",
                "Net::Frame::Layer::PPP" );
        }
        $params{protocol} = $arg;
    } else {
        my %args = @_;
        for ( keys(%args) ) {
            $params{$_} = $args{$_};
        }
    }

    my $p = PPC::Layer::_layer( "PPP", %params );
    if ( !defined wantarray ) {
        print $p->print . "\n";
    }
    return $p;
}

1;

package PPC;
eval "use Net::Frame::Layer::PPP $minver_PPP qw( :consts )";
1;

__END__

=head1 COMMANDS

=head2 PPP - create PPP layer

 $ppp = PPP [(Net::Frame::Layer::PPP options)]

Creates B<$ppp> variable as PPP layer.  Uses options from
B<Net::Frame::Layer::PPP>.

Single option indicates protocol.

=cut
