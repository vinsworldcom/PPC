# Need to test after PPC::Macro since PPC::Layer uses PPC::Macro

use strict;
use warnings;

use Test::More tests => 41;

# Need PPC::Macro loaded - so load PPC
use PPC;

#########################

my $ret;
# for evals
local $SIG{__DIE__} = sub { $ret = $_[0]; };

  eval { PPC::Layer::ETHER('invalid'); };
is( $ret, "Not a valid type - `invalid'\n", "layer ETHER invalid" );
is( ref ( $ret = PPC::Layer::ETHER ), 'Net::Frame::Layer::ETH', "layer ETHER" );
is( ref ( $ret = PPC::Layer::ETHER(1) ), 'Net::Frame::Layer::ETH', "layer ETHER type" );
is( $ret->type, 1, "layer ETHER type verfiy" );

is( ref ( $ret = PPC::Layer::ETHER4 ), 'Net::Frame::Layer::ETH', "layer ETHER4" );
is( ref ( $ret = PPC::Layer::ETHER4('11:11:11:11:11:11') ), 'Net::Frame::Layer::ETH', "layer ETHER4 dst" );
is( $ret->dst, '11:11:11:11:11:11', "layer ETHER4 dst verfiy" );

is( ref ( $ret = PPC::Layer::ETHER6 ), 'Net::Frame::Layer::ETH', "layer ETHER6" );
is( ref ( $ret = PPC::Layer::ETHER6('11:11:11:11:11:11') ), 'Net::Frame::Layer::ETH', "layer ETHER6 dst" );
is( $ret->dst, '11:11:11:11:11:11', "layer ETHER6 dst verfiy" );

is( ref ( $ret = PPC::Layer::ARP ), 'Net::Frame::Layer::ARP', "layer ARP" );
is( ref ( $ret = PPC::Layer::ARP('1.1.1.1') ), 'Net::Frame::Layer::ARP', "layer ARP dst" );
is( $ret->dstIp, '1.1.1.1', "layer ARP dst verify" );

is( ref ( $ret = PPC::Layer::IPv4 ), 'Net::Frame::Layer::IPv4', "layer IPv4" );
is( ref ( $ret = PPC::Layer::IPv4('1.1.1.1') ), 'Net::Frame::Layer::IPv4', "layer IPv4 dst" );
is( $ret->dst, '1.1.1.1', "layer IPv4 dst verify" );

SKIP: {
    eval "use Net::Frame::Layer::IPv6;";
    skip "Net::Frame::Layer::IPv6 required", 3 if $@;
    
    is( ref ( $ret = PPC::Layer::IPv6 ), 'Net::Frame::Layer::IPv6', "layer IPv6" );
    is( ref ( $ret = PPC::Layer::IPv6('2001:db8::1') ), 'Net::Frame::Layer::IPv6', "layer IPv6 dst" );
    is( $ret->dst, '2001:db8::1', "layer IPv6 dst verify" );
}

SKIP: {
    eval "use Net::Frame::Layer::ICMPv4;";
    skip "Net::Frame::Layer::ICMPv4 required", 7 if $@;
    
      eval { PPC::Layer::ICMPv4('invalid'); };
    is( $ret, "Not a valid type - `invalid'\n", "layer ICMPv4 invalid" );
    is( ref ( $ret = PPC::Layer::ICMPv4 ), 'Net::Frame::Layer::ICMPv4', "layer ICMPv4" );
    is( ref ( $ret = PPC::Layer::ICMPv4(234) ), 'Net::Frame::Layer::ICMPv4', "layer ICMPv4 type" );
    is( $ret->type, 234, "layer ICMPv4 type verify" );

    is( ref ( $ret = PPC::Layer::ECHOv4 ), 'Net::Frame::Layer::ICMPv4::Echo', "layer ECHOv4" );
    is( ref ( $ret = PPC::Layer::ECHOv4('ping') ), 'Net::Frame::Layer::ICMPv4::Echo', "layer ECHOv4 payload" );
    is( $ret->payload, 'ping', "layer ECHOv4 payload verify" );
}

SKIP: {
    eval "use Net::Frame::Layer::ICMPv6;";
    skip "Net::Frame::Layer::ICMPv6 required", 7 if $@;
    
      eval { PPC::Layer::ICMPv6('invalid'); };
    is( $ret, "Not a valid type - `invalid'\n", "layer ICMPv6 invalid" );
    is( ref ( $ret = PPC::Layer::ICMPv6 ), 'Net::Frame::Layer::ICMPv6', "layer ICMPv6" );
    is( ref ( $ret = PPC::Layer::ICMPv6(234) ), 'Net::Frame::Layer::ICMPv6', "layer ICMPv6 type" );
    is( $ret->type, 234, "layer ICMPv6 type verify" );

    is( ref ( $ret = PPC::Layer::ECHOv6 ), 'Net::Frame::Layer::ICMPv6::Echo', "layer ECHOv6" );
    is( ref ( $ret = PPC::Layer::ECHOv6('ping') ), 'Net::Frame::Layer::ICMPv6::Echo', "layer ECHOv6 payload" );
    is( $ret->payload, 'ping', "layer ECHOv6 payload verify" );
}

# TCP
  eval { PPC::Layer::TCP('invalid'); };
is( $ret, "Not a valid port - `invalid'\n", "layer TCP invalid" );
is( ref ( $ret = PPC::Layer::TCP ), 'Net::Frame::Layer::TCP', "layer TCP" );
is( ref ( $ret = PPC::Layer::TCP(1234) ), 'Net::Frame::Layer::TCP', "layer TCP port" );
is( $ret->dst, 1234, "layer TCP port verify" );

# UDP
  eval { PPC::Layer::UDP('invalid'); };
is( $ret, "Not a valid port - `invalid'\n", "layer UDP invalid" );
is( ref ( $ret = PPC::Layer::UDP ), 'Net::Frame::Layer::UDP', "layer UDP" );
is( ref ( $ret = PPC::Layer::UDP(1234) ), 'Net::Frame::Layer::UDP', "layer UDP port" );
is( $ret->dst, 1234, "layer UDP port verify" );
