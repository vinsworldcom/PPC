package PPC::Layer::LLC;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

my $minver_LLC = 1.03;
my $HAVE_LLC   = 0;
my $useString = "use Net::Frame::Layer::LLC $minver_LLC qw( :consts )";
eval $useString;
if ( !$@ ) {
    $HAVE_LLC = 1;
}

use Exporter;

our @EXPORT = qw ( LLC );

our @ISA = qw ( PPC::Layer Exporter );

########################################################

sub LLC {
    my %params;

    if ( !$HAVE_LLC ) {
        PPC::Layer::_err_not_installed( "LLC", $minver_LLC );
    }

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__, "COMMANDS/LLC - create LLC layer",
                "Net::Frame::Layer::LLC" );
        }
        $params{dsap} = $arg;
    } else {
        my %args = @_;
        for ( keys(%args) ) {
            $params{$_} = $args{$_};
        }
    }

    my $p = PPC::Layer::_layer( "LLC", %params );
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

=head2 LLC - create LLC layer

 $llc = LLC [(Net::Frame::Layer::LLC options)]

Creates B<$llc> variable as LLC layer.  Uses options from
B<Net::Frame::Layer::LLC>.

Single option indicates dsap.

=cut
