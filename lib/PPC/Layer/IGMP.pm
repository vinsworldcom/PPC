package PPC::Layer::IGMP;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

my $minver_IGMP = 1.01;
my $HAVE_IGMP   = 0;
my $useString = "use Net::Frame::Layer::IGMP $minver_IGMP qw( :consts )";
eval $useString;
if ( !$@ ) {
    $HAVE_IGMP = 1;
}

use Exporter;

our @EXPORT = qw ( IGMP );

our @ISA = qw ( PPC::Layer Exporter );

########################################################

sub IGMP {
    my %params;

    if ( !$HAVE_IGMP ) {
        PPC::Layer::_err_not_installed( "IGMP", $minver_IGMP );
    }

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__, "COMMANDS/IGMP - create IGMP layer",
                "Net::Frame::Layer::IGMP" );
        }
        $params{groupAddress} = $arg;
    } else {
        my %args = @_;
        for ( keys(%args) ) {
            $params{$_} = $args{$_};
        }
    }

    my $p = PPC::Layer::_layer( "IGMP", %params );
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

=head2 IGMP - create IGMP layer

 $igmp = IGMP [(Net::Frame::Layer::IGMP options)]

Creates B<$igmp> variable as IGMP layer.  Uses options from
B<Net::Frame::Layer::IGMP>.

Single option indicates groupAddress.

=cut
