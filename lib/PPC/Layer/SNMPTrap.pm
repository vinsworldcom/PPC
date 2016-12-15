package PPC::Layer::SNMPTrap;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

my $minver_SNMP = 1.01;
my $HAVE_SNMP   = 0;
my $useString = "use Net::Frame::Layer::SNMP $minver_SNMP qw( :consts :subs )";
eval $useString;
if ( !$@ ) {
    $HAVE_SNMP = 1;
}

use Exporter;

our @EXPORT = qw ( SNMPTrap );

our @ISA = qw ( PPC::Layer Exporter );

########################################################

sub SNMPTrap {
    my %params;

    if ( !$HAVE_SNMP ) {
        PPC::Layer::_err_not_installed( "SNMP", $minver_SNMP );
    }

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__,
                "COMMANDS/SNMPTrap - create SNMP Trap layer",
                "Net::Frame::Layer::SNMP"
            );
        }
        $params{community} = $arg;
    } else {
        my %args = @_;
        for ( keys(%args) ) {
            $params{$_} = $args{$_};
        }
    }

    my $p = PPC::Layer::_layer( "SNMP->Trap", %params );
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

=head2 SNMPTrap - create SNMP Trap layer

 $snmptrap = SNMPTrap [(Net::Frame::Layer::SNMP options)]

Creates B<$snmptrap> variable as SNMP Trap layer.  Uses options from
B<Net::Frame::Layer::SNMP>.

Single option indicates community.

=cut
