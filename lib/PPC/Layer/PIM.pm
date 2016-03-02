package PPC::Layer::PIM;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

my $minver_PIM = 0.01;
my $HAVE_PIM   = 0;
eval "use Net::Frame::Layer::PIM $minver_PIM qw( :consts )";
if ( !$@ ) {
    $HAVE_PIM = 1;
}

use Exporter;

our @EXPORT = qw ( PIM );

our @ISA = qw ( PPC::Layer Exporter );

########################################################

sub PIM {
    my %params;

    if ( !$HAVE_PIM ) {
        PPC::Layer::_err_not_installed( "PIM", $minver_PIM );
    }

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__, "COMMANDS/PIM - create PIM layer",
                "Net::Frame::Layer::PIM" );
        }
        $params{type} = $arg;
    } else {
        my %args = @_;
        for ( keys(%args) ) {
            $params{$_} = $args{$_};
        }
    }

    my $p = PPC::Layer::_layer( "PIM", %params );
    if ( !defined wantarray ) {
        print $p->print . "\n";
    }
    return $p;
}

1;

package PPC;
eval "use Net::Frame::Layer::PIM $minver_PIM qw( :consts )";
1;

__END__

=head1 COMMANDS

=head2 PIM - create PIM layer

 $pim = PIM [(Net::Frame::Layer::PIM options)]

Creates B<$pim> variable as PIM layer.  Uses options from
B<Net::Frame::Layer::PIM>.

Single option indicates type.

=cut
