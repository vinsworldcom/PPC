package PPC::Layer::SNMPSet;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

my $minver_SNMP = 1.01;
my $HAVE_SNMP   = 0;
eval "use Net::Frame::Layer::SNMP $minver_SNMP qw( :consts :subs )";
if ( !$@ ) {
    $HAVE_SNMP = 1;
}

use Exporter;

our @EXPORT = qw ( SNMPSet );

our @ISA = qw ( PPC::Layer Exporter );

########################################################

sub SNMPSet {
    my %params;

    if ( !$HAVE_SNMP ) {
        PPC::Layer::_err_not_installed( "SNMP", $minver_SNMP );
    }

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__,
                "COMMANDS/SNMPSet - create SNMP Set layer",
                "Net::Frame::Layer::SNMP" );
        }
        $params{community} = $arg;
    } else {
        my %args = @_;
        for ( keys(%args) ) {
            $params{$_} = $args{$_};
        }
    }

    my $p = PPC::Layer::_layer( "SNMP->Set", %params );
    if ( !defined wantarray ) {
        print $p->print . "\n";
    }
    return $p;
}

1;

package PPC;
eval "use Net::Frame::Layer::SNMP $minver_SNMP qw( :consts :subs )";
1;

__END__

=head1 COMMANDS

=head2 SNMPSet - create SNMP Set layer

 $snmpset= SNMPSet [(Net::Frame::Layer::SNMP options)]

Creates B<$snmpset> variable as SNMP Set layer.  Uses options from
B<Net::Frame::Layer::SNMP>.

Single option indicates community.

=cut
