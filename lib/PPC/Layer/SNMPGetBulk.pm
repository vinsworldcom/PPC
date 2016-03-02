package PPC::Layer::SNMPGetBulk;

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

our @EXPORT = qw ( SNMPGetBulk );

our @ISA = qw ( PPC::Layer Exporter );

########################################################

sub SNMPGetBulk {
    my %params;

    if ( !$HAVE_SNMP ) {
        PPC::Layer::_err_not_installed( "SNMP", $minver_SNMP );
    }

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__,
                "COMMANDS/SNMPGetBulk - create SNMP GetBulk layer",
                "Net::Frame::Layer::SNMP" );
        }
        $params{community} = $arg;
    } else {
        my %args = @_;
        for ( keys(%args) ) {
            $params{$_} = $args{$_};
        }
    }

    my $p = PPC::Layer::_layer( "SNMP->GetBulk", %params );
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

=head2 SNMPGetBulk - create SNMP GetBulk layer

 $snmpgetbulk= SNMPGetBulk [(Net::Frame::Layer::SNMP options)]

Creates B<$snmpgetbulk> variable as SNMP GetBulk layer.  Uses options from
B<Net::Frame::Layer::SNMP>.

Single option indicates community.

=cut
