use strict;
use warnings;

use Test::More tests => 15;
BEGIN { use_ok('PPC::Interface') };

#########################

my @ret;

ok( @ret = PPC::Interface->interfaces(), "interfaces" );
my $if;
is( ref ( $if = PPC::Interface->new($ret[0]) ), 'PPC::Interface', "interface $ret[0]" );
is( $if->name, $ret[0], "interface name" );

SKIP: {
    skip "developer-only tests - set PPC_INTERFACE to interface name", 11 unless $ENV{PPC_INTERFACE};

    is( ref ( $if = PPC::Interface->new($ENV{PPC_INTERFACE}) ), 'PPC::Interface', "interface $ENV{PPC_INTERFACE}" );

    isnt( $if->devicename, '', "interface devicename" );
    like( $if->mtu, qr/^\d{1,5}$/, "interface mtu" );

    like( $if->mac, qr/(?:[0-9a-f]{2}:){5}[0-9a-f]{2}/i, "interface mac" );

    # WARN - Net::IPv4Addr bug sends undefined to Carp
    # DIE  - Net::IPv4Addr croaks on error, I prefer to handle nicely
    local $SIG{__WARN__} = sub { return; };
    local $SIG{__DIE__}  = sub { return; };
    my $addr;

    # IPv4:  requires Net::IPv4Addr which is dependency of Net::Frame
    use Net::IPv4Addr;
    like( $if->ipv4_gateway_mac, qr/(?:[0-9a-f]{2}:){5}[0-9a-f]{2}/i, "interface ipv4_gateway_mac" );
      eval { $addr = Net::IPv4Addr::ipv4_parse($if->ipv4); };
    is( $if->ipv4, $addr, "interface ipv4" );
      eval { $addr = Net::IPv4Addr::ipv4_parse($if->ipv4_default_gateway); };
    is( $if->ipv4_default_gateway, $addr, "interface ipv4_default_gateway" );

    SKIP: {
        skip "developer-only tests - set PPC_IPv6", 4 unless $ENV{PPC_IPv6};

        # IPv6:  requires Net::IPv6Addr which is dependency of Net::Frame
        use Net::IPv6Addr;
        like( $if->ipv6_gateway_mac, qr/(?:[0-9a-f]{2}:){5}[0-9a-f]{2}/i, "interface ipv6_gateway_mac" );
          eval { $addr = Net::IPv6Addr::ipv6_parse($if->ipv6); };
        is( $if->ipv6, $addr, "interface ipv6" );
          eval { $addr = Net::IPv6Addr::ipv6_parse($if->ipv6_link_local); };
        is( $if->ipv6_link_local, $addr, "interface ipv6_link_local" );
          eval { $addr = Net::IPv6Addr::ipv6_parse($if->ipv6_default_gateway); };
        is( $if->ipv6_default_gateway, $addr, "interface ipv6_default_gateway" );
    }
}
