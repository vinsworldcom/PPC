package PPC::Layer::STP;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

my $minver_STP = 1.02;
my $HAVE_STP   = 0;
my $useString = "use Net::Frame::Layer::STP $minver_STP qw( :consts )";
eval $useString;
if ( !$@ ) {
    $HAVE_STP = 1;
}

use Exporter;

our @EXPORT = qw ( STP );

our @ISA = qw ( PPC::Layer Exporter );

########################################################

sub STP {
    my %params;

    if ( !$HAVE_STP ) {
        PPC::Layer::_err_not_installed( "STP", $minver_STP );
    }

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__, "COMMANDS/STP - create STP layer",
                "Net::Frame::Layer::STP" );
        }
        $params{rootIdentifier} = $arg;
    } else {
        my %args = @_;
        for ( keys(%args) ) {
            $params{$_} = $args{$_};
        }
    }

    my $p = PPC::Layer::_layer( "STP", %params );
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

=head2 STP - create STP layer

 $stp = STP [(Net::Frame::Layer::STP options)]

Creates B<$stp> variable as STP layer.  Uses options from
B<Net::Frame::Layer::STP>.

Single option indicates rootIdentifier.

=cut
