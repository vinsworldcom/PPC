package PPC::Layer::VRRP;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

my $minver_VRRP = 1.00;
my $HAVE_VRRP   = 0;
my $useString = "use Net::Frame::Layer::VRRP $minver_VRRP qw( :consts )";
eval $useString;
if ( !$@ ) {
    $HAVE_VRRP = 1;
}

use Exporter;

our @EXPORT = qw ( VRRP );

our @ISA = qw ( PPC::Layer Exporter );

########################################################

sub VRRP {
    my %params;

    if ( !$HAVE_VRRP ) {
        PPC::Layer::_err_not_installed( "VRRP", $minver_VRRP );
    }

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__, "COMMANDS/VRRP - create VRRP layer",
                "Net::Frame::Layer::VRRP" );
        }
        $params{ipAddresses} = $arg;
    } else {
        my %args = @_;
        for ( keys(%args) ) {
            $params{$_} = $args{$_};
        }
    }

    my $p = PPC::Layer::_layer( "VRRP", %params );
    if ( !defined wantarray ) {
        print $p->print . "\n";
    }
    return $p;
}

1;

package PPC;
eval $useString;
1;

__END__

=head1 COMMANDS

=head2 VRRP - create VRRP layer

 $vrrp = VRRP [(Net::Frame::Layer::VRRP options)]

Creates B<$vrrp> variable as VRRP layer.  Uses options from
B<Net::Frame::Layer::VRRP>.

Single option indicates ipAddresses.

=cut
