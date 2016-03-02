package PPC::Layer::HSRP;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

my $minver_HSRP = 1.00;
my $HAVE_HSRP   = 0;
eval "use Net::Frame::Layer::HSRP $minver_HSRP qw( :consts )";
if ( !$@ ) {
    $HAVE_HSRP = 1;
}

use Exporter;

our @EXPORT = qw ( HSRP );

our @ISA = qw ( PPC::Layer Exporter );

########################################################

sub HSRP {
    my %params;

    if ( !$HAVE_HSRP ) {
        PPC::Layer::_err_not_installed( "HSRP", $minver_HSRP );
    }

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__, "COMMANDS/HSRP - create HSRP layer",
                "Net::Frame::Layer::HSRP" );
        }
        $params{virtualIp} = $arg;
    } else {
        my %args = @_;
        for ( keys(%args) ) {
            $params{$_} = $args{$_};
        }
    }

    my $p = PPC::Layer::_layer( "HSRP", %params );
    if ( !defined wantarray ) {
        print $p->print . "\n";
    }
    return $p;
}

1;

package PPC;
eval "use Net::Frame::Layer::HSRP $minver_HSRP qw( :consts )";
1;

__END__

=head1 COMMANDS

=head2 HSRP - create HSRP layer

 $hsrp = HSRP [(Net::Frame::Layer::HSRP options)]

Creates B<$hsrp> variable as HSRP layer.  Uses options from
B<Net::Frame::Layer::HSRP>.

Single option indicates virtualIp.

=cut
