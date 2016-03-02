use strict;
use warnings;

use Test::More tests => 60;
use FindBin qw( $Bin );

# Need PPC, PPC::Layer loaded - so load PPC
use PPC;

#########################

my %test = (
    GRE => {
        name => 'GRE',
        nfl => 'GRE',
        option => "protocol",
        value => 1,
        expect => 1
    },
    HSRP => {
        name => 'HSRP',
        nfl => 'HSRP',
        option => 'virtualIp',
        value => '1.1.1.1',
        expect => pack "H*", '01010101'
    },
    IGMP => {
        name => 'IGMP',
        nfl => 'IGMP',
        option => 'groupAddress',
        value => '1.1.1.1',
        expect => pack "H*", '01010101'
    },
    LLC => {
        name => 'LLC',
        nfl => 'LLC',
        option => 'dsap',
        value => 1,
        expect => 1
    },
    NTP => {
        name => 'NTP',
        nfl => 'NTP',
        option => 'refId',
        value => 1,
        expect => 1
    },
    PIM => {
        name => 'PIM',
        nfl => 'PIM',
        option => 'type',
        value => 1,
        expect => 1
    },
    PPP => {
        name => 'PPP',
        nfl => 'PPP',
        option => 'protocol',
        value => 1,
        expect => 1
    },
    SNMPGet => {
        name => 'SNMPGet',
        nfl => 'SNMP',
        option => 'community',
        value => "'ppc'",
        expect => 'ppc'
    },
    SNMPGetBulk => {
        name => 'SNMPGetBulk',
        nfl => 'SNMP',
        option => 'community',
        value => "'ppc'",
        expect => 'ppc'
    },
    SNMPGetNext => {
        name => 'SNMPGetNext',
        nfl => 'SNMP',
        option => 'community',
        value => "'ppc'",
        expect => 'ppc'
    },
    SNMPInform => {
        name => 'SNMPInform',
        nfl => 'SNMP',
        option => 'community',
        value => "'ppc'",
        expect => 'ppc'
    },
    SNMPReport => {
        name => 'SNMPReport',
        nfl => 'SNMP',
        option => 'community',
        value => "'ppc'",
        expect => 'ppc'
    },
    SNMPResponse => {
        name => 'SNMPResponse',
        nfl => 'SNMP',
        option => 'community',
        value => "'ppc'",
        expect => 'ppc'
    },
    SNMPSet => {
        name => 'SNMPSet',
        nfl => 'SNMP',
        option => 'community',
        value => "'ppc'",
        expect => 'ppc'
    },
    SNMPTrap => {
        name => 'SNMPTrap',
        nfl => 'SNMP',
        option => 'community',
        value => "'ppc'",
        expect => 'ppc'
    },
    SNMPv2Trap => {
        name => 'SNMPv2Trap',
        nfl => 'SNMP',
        option => 'community',
        value => "'ppc'",
        expect => 'ppc'
    },
    STP => {
        name => 'STP',
        nfl => 'STP',
        option => 'rootIdentifier',
        value => "'1/55:44:33:22:11:00'",
        expect => '1/55:44:33:22:11:00'
    },
    Syslog => {
        name => 'SYSLOG',
        nfl => 'Syslog',
        option => 'content',
        value => "'test message'",
        expect => 'test message'
    },
    VLAN => {
        name => 'VLAN',
        nfl => '8021Q',
        option => 'id',
        value => 123,
        expect => 123
    },
);

my $ret;

for my $layer ( sort ( keys ( %test ) ) ) {

    SKIP: {
        my $nfl = "Net::Frame::Layer::" . $test{$layer}->{nfl};
        eval "use $nfl;";
        skip "$nfl required", 3 if $@;

        is( ref ( $ret = eval "PPC::Layer::" . $layer . "::" . $test{$layer}->{name} ), "Net::Frame::Layer::" . $test{$layer}->{nfl}, "layers $layer" );
        is( ref ( $ret = eval "PPC::Layer::" . $layer . "::" . $test{$layer}->{name} . "(" . $test{$layer}->{value} . ")" ), "Net::Frame::Layer::" . $test{$layer}->{nfl}, "layers $layer $test{$layer}->{option}" );
        my $accessor = $test{$layer}->{option};
        is(  $ret->$accessor, $test{$layer}->{expect}, "layers $layer $test{$layer}->{option} verfiy" );
    }
}

SKIP: {
    eval "use Net::Frame::Layer::VRRP;";
    skip "Net::Frame::Layer::VRRP required", 3 if $@;

    # VRRP
    is( ref ( $ret = PPC::Layer::VRRP::VRRP), 'Net::Frame::Layer::VRRP', "layers VRRP" );
    is( ref ( $ret = PPC::Layer::VRRP::VRRP(['1.1.1.1'])), 'Net::Frame::Layer::VRRP', "layers VRRP ipAddresses" );
    is( [$ret->ipAddresses]->[0], '1.1.1.1', "layers VRRP ipAddresses verify" );
}
