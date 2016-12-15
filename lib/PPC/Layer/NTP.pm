package PPC::Layer::NTP;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

my $minver_NTP = 1.02;
my $HAVE_NTP   = 0;
my $useString = "use Net::Frame::Layer::NTP $minver_NTP qw( :consts )";
eval $useString;
if ( !$@ ) {
    $HAVE_NTP = 1;
}

use Exporter;

our @EXPORT = qw ( NTP );

our @ISA = qw ( PPC::Layer Exporter );

########################################################

sub NTP {
    my %params;

    if ( !$HAVE_NTP ) {
        PPC::Layer::_err_not_installed( "NTP", $minver_NTP );
    }

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__, "COMMANDS/NTP - create NTP layer",
                "Net::Frame::Layer::NTP" );
        }
        $params{refId} = $arg;
    } else {
        my %args = @_;
        for ( keys(%args) ) {
            $params{$_} = $args{$_};
        }
    }

    my $p = PPC::Layer::_layer( "NTP", %params );
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

=head2 NTP - create NTP layer

 $ntp = NTP [(Net::Frame::Layer::NTP options)]

Creates B<$ntp> variable as NTP layer.  Uses options from
B<Net::Frame::Layer::NTP>.

Single option indicates refId.

=cut
