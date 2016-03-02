package PPC::Layer::VLAN;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

my $minver_8021Q = 1.03;
my $HAVE_8021Q   = 0;
eval "use Net::Frame::Layer::8021Q $minver_8021Q qw( :consts )";
if ( !$@ ) {
    $HAVE_8021Q = 1;
}

use Exporter;

our @EXPORT = qw ( VLAN );

our @ISA = qw ( PPC::Layer Exporter );

########################################################

sub VLAN {
    my %params;

    if ( !$HAVE_8021Q ) {
        PPC::Layer::_err_not_installed( "8021Q", $minver_8021Q );
    }

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__,
                "COMMANDS/VLAN - create Layer 2 802.1q frame",
                "Net::Frame::Layer::8021Q"
            );
        }
        $params{id} = $arg;
    } else {
        my %args = @_;
        for ( keys(%args) ) {
            $params{$_} = $args{$_};
        }
    }

    my $p = PPC::Layer::_layer( "8021Q", %params );
    if ( !defined wantarray ) {
        print $p->print . "\n";
    }
    return $p;
}

1;

package PPC;
eval "use Net::Frame::Layer::8021Q $minver_8021Q qw( :consts )";
1;

__END__

=head1 COMMANDS

=head2 VLAN - create Layer 2 802.1q frame

 $vlan = VLAN [(Net::Frame::Layer::8021Q options)]

Creates B<$vlan> variable as 802.1q frame.  Uses options from
B<Net::Frame::Layer::8021Q>.

Single option indicates VLAN.

=cut
