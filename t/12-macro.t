use strict;
use warnings;

use Test::More tests => 65;

# Need PPC::PPC_GLOBALS - so load PPC
use PPC;

#########################

my $ret;
# for evals
local $SIG{__DIE__} = sub { $ret = $_[0]; };

is( PPC::Macro::MAC_SRC, undef, "macro MAC_SRC not defined" );
  eval { PPC::Macro::MAC_SRC('invalid'); };
is( $ret, "Not a valid argument - \`invalid\'\n", "macro MAC_SRC invalid" );
is( PPC::Macro::MAC_SRC('00:00:00:00:00:00'), '00:00:00:00:00:00', "macro MAC_SRC valid" );
is( PPC::Macro::MAC_SRC(':clear'), undef, "macro MAC_SRC :clear" );

is( PPC::Macro::MAC_GW, undef, "macro MAC_GW not defined" );
  eval { PPC::Macro::MAC_GW('invalid'); };
is( $ret, "Not a valid argument - \`invalid\'\n", "macro MAC_GW invalid" );
is( PPC::Macro::MAC_GW('00:00:00:00:00:00'), '00:00:00:00:00:00', "macro MAC_GW valid" );
is( PPC::Macro::MAC_GW(':clear'), undef, "macro MAC_GW :clear" );

SKIP: {
    skip "developer-only tests - set PPC_IPv6", 4 unless $ENV{PPC_IPv6};

    is( PPC::Macro::MAC6_GW, undef, "macro MAC6_GW not defined" );
      eval { PPC::Macro::MAC6_GW('invalid'); };
    is( $ret, "Not a valid argument - \`invalid\'\n", "macro MAC6_GW invalid" );
    is( PPC::Macro::MAC6_GW('00:00:00:00:00:00'), '00:00:00:00:00:00', "macro MAC6_GW valid" );
    is( PPC::Macro::MAC6_GW(':clear'), undef, "macro MAC6_GW :clear" );
}

# requires Net::IPv4Addr which is dependency of Net::Frame
is( PPC::Macro::IPv4_SRC, undef, "macro IPv4_SRC not defined" );
  eval { PPC::Macro::IPv4_SRC('invalid'); };
is( $ret, "Not a valid argument - \`invalid\'\n", "macro IPv4_SRC invalid" );
is( PPC::Macro::IPv4_SRC('1.1.1.1'), '1.1.1.1', "macro IPv4_SRC valid" );
is( PPC::Macro::IPv4_SRC(':clear'), undef, "macro IPv4_SRC :clear" );

# requires Net::IPv4Addr which is dependency of Net::Frame
is( PPC::Macro::IPv4_GW, undef, "macro IPv4_GW not defined" );
  eval { PPC::Macro::IPv4_GW('invalid'); };
is( $ret, "Not a valid argument - \`invalid\'\n", "macro IPv4_GW invalid" );
is( PPC::Macro::IPv4_GW('1.1.1.1'), '1.1.1.1', "macro IPv4_GW valid" );
is( PPC::Macro::IPv4_GW(':clear'), undef, "macro IPv4_GW :clear" );

SKIP: {
    skip "developer-only tests - set PPC_IPv6", 12 unless $ENV{PPC_IPv6};

    # requires Net::IPv6Addr which is dependency of Net::Frame
    is( PPC::Macro::IPv6_SRC, undef, "macro IPv6_SRC not defined" );
      eval { PPC::Macro::IPv6_SRC('invalid'); };
    is( $ret, "Not a valid argument - \`invalid\'\n", "macro IPv6_SRC invalid" );
    is( PPC::Macro::IPv6_SRC('2001:db8::1'), '2001:db8::1', "macro IPv6_SRC valid" );
    is( PPC::Macro::IPv6_SRC(':clear'), undef, "macro IPv6_SRC :clear" );

    # requires Net::IPv6Addr which is dependency of Net::Frame
    is( PPC::Macro::IPv6_SRC_LL, undef, "macro IPv6_SRC_LL not defined" );
      eval { PPC::Macro::IPv6_SRC_LL('invalid'); };
    is( $ret, "Not a valid argument - \`invalid\'\n", "macro IPv6_SRC_LL invalid" );
    #  eval { PPC::Macro::IPv6_SRC_LL('2001:db8::1'); };
    #ok( $ret =~ /Not a valid IPv6 link local address \`2001:db8::1\'/, "macro IPv6_SRC_LL not valid LL" );
    is( PPC::Macro::IPv6_SRC_LL('fe80::1'), 'fe80::1', "macro IPv6_SRC_LL valid" );
    is( PPC::Macro::IPv6_SRC_LL(':clear'), undef, "macro IPv6_SRC_LL :clear" );

    # requires Net::IPv6Addr which is dependency of Net::Frame
    is( PPC::Macro::IPv6_GW, undef, "macro IPv6_GW not defined" );
      eval { PPC::Macro::IPv6_GW('invalid'); };
    is( $ret, "Not a valid argument - \`invalid\'\n", "macro IPv6_GW invalid" );
    is( PPC::Macro::IPv6_GW('2001:db8::1'), '2001:db8::1', "macro IPv6_GW valid" );
    is( PPC::Macro::IPv6_GW(':clear'), undef, "macro IPv6_GW :clear" );
}

my $sink;
local $SIG{__WARN__} = sub { $ret = $_[0]; };

  eval { PPC::Macro::D2B('a'); };
is( $ret, "Not a decimal number `a'\n", "D2B invalid" );
is( PPC::Macro::D2B(2), '10', "D2B 2->10" );
is( PPC::Macro::D2B(10), '1010', "D2B 10->1010" );
  eval { $sink = PPC::Macro::D2B(10,'a'); };
ok( ( ( $ret =~ /Ignoring not a number pad \`a\'/ ) and ( $sink eq '1010' ) ), "D2B padding invalid" );
is( PPC::Macro::D2B(10,8), '00001010', "D2B padding 10->00001010" );

  eval { PPC::Macro::D2H('a'); };
is( $ret, "Not a decimal number `a'\n", "D2H invalid" );
is( PPC::Macro::D2H(10), 'a', "D2H 2->a" );
is( PPC::Macro::D2H(16), '10', "D2H 16->10" );

  eval { PPC::Macro::H2B('g'); };
is( $ret, "Not a hex number `g'\n", "H2B invalid" );
is( PPC::Macro::H2B(2), '10', "H2B 2->10" );
is( PPC::Macro::H2B(0xa), '1010', "H2B 0xa->1010" );
is( PPC::Macro::H2B(16), '10000', "H2B 16->10000" );
  eval { $sink = PPC::Macro::H2B(16,'a'); };
ok( ( ( $ret =~ /Ignoring not a number pad \`a\'/ ) and ( $sink eq '10000' ) ), "H2B padding invalid" );
is( PPC::Macro::H2B(16,8), '00010000', "H2B padding 16->00010000" );

  eval { PPC::Macro::H2D('g'); };
is( $ret, "Not a hex number `g'\n", "H2D invalid" );
is( PPC::Macro::H2D(2), '2', "H2D 2->2" );
is( PPC::Macro::H2D(10), '10', "H2D 10->10" );
is( PPC::Macro::H2D('10'), '10', "H2D 10[string]->10" );
is( PPC::Macro::H2D(0x10), '16', "H2D 0x10->16" );
is( PPC::Macro::H2D('0x10'), '16', "H2D 0x10[string]->16" );

is( PPC::Macro::H2S('414243313233'), 'ABC123', "H2S 414243313233->ABC123" );

is( PPC::Macro::S2H('ABC123'), '414243313233', "S2H ABC123->414243313233" );
use Net::Frame::Simple;
use Net::Frame::Layer::ETH;
use Net::Frame::Layer::IPv4;
use Net::Frame::Layer::TCP;
$ret = Net::Frame::Simple->new(
    layers => [
        ( $sink = Net::Frame::Layer::ETH->new ),
        Net::Frame::Layer::IPv4->new,
        Net::Frame::Layer::TCP->new,
    ]
);
is( PPC::Macro::S2H($sink), 'ffffffffffff0000000000000800', "S2H Net::Frame::Layer::ETH" );
like( PPC::Macro::S2H($ret), qr/^ffffffffffff00000000000008004500/, "S2H Net::Frame::Simple" );

SKIP: {
    skip "developer-only tests - set PPC_INTERFACE to interface name", 9 unless $ENV{PPC_INTERFACE};

    # need to use PPC::interface sub (instead of PPC::Interface->new)
    # as that sub set's the Macros values through $PPC_GLOBALS.
    is( ref ( $ret = PPC::interface($ENV{PPC_INTERFACE}) ), 'PPC::Interface', "interface set to $ENV{PPC_INTERFACE}" );
    
    like( PPC::Macro::MAC_SRC(), qr/(?:[0-9a-f]{2}:){5}[0-9a-f]{2}/i, "macro MAC_SRC $ENV{PPC_INTERFACE}" );

    # WARN - Net::IPv4Addr bug sends undefined to Carp
    # DIE  - Net::IPv4Addr croaks on error, I prefer to handle nicely
    local $SIG{__WARN__} = sub { return; };
    local $SIG{__DIE__}  = sub { return; };
    my $addr;

    # IPv4:  requires Net::IPv4Addr which is dependency of Net::Frame
    like( PPC::Macro::MAC_GW(), qr/(?:[0-9a-f]{2}:){5}[0-9a-f]{2}/i, "macro MAC_GW $ENV{PPC_INTERFACE}" );
    use Net::IPv4Addr;
      eval { $addr = Net::IPv4Addr::ipv4_parse($ret->ipv4); };
    is( PPC::Macro::IPv4_SRC(), $addr, "macro IPv4_SRC $ENV{PPC_INTERFACE}" );
      eval { $addr = Net::IPv4Addr::ipv4_parse($ret->ipv4_default_gateway); };
    is( PPC::Macro::IPv4_GW(), $addr, "macro IPv4_GW $ENV{PPC_INTERFACE}" );

    SKIP: {
        skip "developer-only tests - set PPC_IPv6", 4 unless $ENV{PPC_IPv6};

        # IPv6:  requires Net::IPv6Addr which is dependency of Net::Frame
        use Net::IPv6Addr;
        like( PPC::Macro::MAC6_GW(), qr/(?:[0-9a-f]{2}:){5}[0-9a-f]{2}/i, "macro MAC6_GW $ENV{PPC_INTERFACE}" );
          eval { $addr = Net::IPv6Addr::ipv6_parse($ret->ipv6); };
        is( PPC::Macro::IPv6_SRC(), $addr, "macro IPv6_SRC $ENV{PPC_INTERFACE}" );
          eval { $addr = Net::IPv6Addr::ipv6_parse($ret->ipv6_link_local); };
        is( PPC::Macro::IPv6_SRC_LL(), $addr, "macro IPv6_SRC_LL $ENV{PPC_INTERFACE}" );
          eval { $addr = Net::IPv6Addr::ipv6_parse($ret->ipv6_default_gateway); };
        is( PPC::Macro::IPv6_GW, $addr, "macro IPv6_GW $ENV{PPC_INTERFACE}" );
    }
}
