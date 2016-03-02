use strict;
use warnings;

use Test::More tests => 30;

# Need PPC, PPC::Layer loaded - so load PPC
use PPC;

#########################

my $ret;

use Net::Frame::Layer qw(:subs);
use Net::Frame::Layer::ETH;
use Net::Frame::Layer::IPv4;
use Net::Frame::Layer::TCP;
is( ref ( $ret = PPC::Packet::packet(
    Net::Frame::Layer::ETH->new(),
    Net::Frame::Layer::IPv4->new(),
    Net::Frame::Layer::TCP->new()
    ) ), 'PPC::Packet', "packet packet");

# AUTOLOAD accessors
like( $ret->dst0, qr/(?:[0-9a-f]{2}:){5}[0-9a-f]{2}/i, "packet AUTOLOAD dst0 (Ethernet dst MAC)" );
like( $ret->src0, qr/(?:[0-9a-f]{2}:){5}[0-9a-f]{2}/i, "packet AUTOLOAD src0 (Ethernet src MAC)" ); 
like( $ret->dst1, qr/^(?:\d{1,3}\.){3}\d{1,3}$/, "packet AUTOLOAD dst1 (IPv4 dst addr)" );
like( $ret->src1, qr/^(?:\d{1,3}\.){3}\d{1,3}$/, "packet AUTOLOAD src1 (IPv4 dst addr)" );
like( $ret->dst2, qr/^\d{1,5}$/, "packet AUTOLOAD dst2 (TCP dst port)" );
like( $ret->src2, qr/^\d{1,5}$/, "packet AUTOLOAD src2 (TCP src port)" );

my $port = $ret->dst2(1234);
is( $ret->dst2, 1234, "packet AUTOLOAD set dst2(1234) (TCP dst port)" );

SKIP: {
    skip "developer-only tests - set PPC_INTERFACE to interface name", 22 unless $ENV{PPC_INTERFACE};

    my $if;
    is( ref ( $if = PPC::interface($ENV{PPC_INTERFACE}) ), 'PPC::Interface', "interface set to $ENV{PPC_INTERFACE}" );

    my $packet = PPC::Packet::packet( PPC::ETHER, PPC::IPv4(getHostIpv4Addr 'www.google.com'), PPC::TCP(80) );

    # verify packet
    is( [$packet->layers]->[0]->dst, $if->ipv4_gateway_mac, "packet 0 dst $ENV{PPC_INTERFACE} verify" );
    is( [$packet->layers]->[0]->src, $if->mac, "packet 0 src $ENV{PPC_INTERFACE} verify" );
    like( [$packet->layers]->[1]->dst, qr/^(?:\d{1,3}\.){3}\d{1,3}$/, "packet 1 dst $ENV{PPC_INTERFACE} verify" );
    is( [$packet->layers]->[1]->src, $if->ipv4, "packet 1 src $ENV{PPC_INTERFACE} verify" );

    # sendp
    is( ref ( $ret = PPC::sendp($packet) ), 'ARRAY', "packet sendp" );
    is( [$ret->[0]->layers]->[0]->dst, [$packet->layers]->[0]->dst, "packet sendp 0 dst verify" );
    is( [$ret->[0]->layers]->[0]->src, [$packet->layers]->[0]->src, "packet sendp 0 src verify" ); 
    like( [$ret->[0]->layers]->[1]->dst, qr/^(?:\d{1,3}\.){3}\d{1,3}$/, "packet sendp 1 dst verify" );
    is( [$ret->[0]->layers]->[1]->src, [$packet->layers]->[1]->src, "packet sendp 1 src verify" );

    # sendp options
    my @packets = ( $packet, $packet );
    is( ref ( $ret = PPC::sendp(\@packets) ), 'ARRAY', 'packet sendp \@packets' );
    is( scalar @{$ret}, 2, 'packet sendp \@packets ret = 2' );

    is( ref ( $ret = PPC::sendp(\@packets, count=>2) ), 'ARRAY', 'packet sendp \@packets,count=>2' );
    is( scalar @{$ret}, 4, 'packet sendp \@packets ret = 4' );

    my $start = time;
    is( ref ( $ret = PPC::sendp(\@packets, delay=>2) ), 'ARRAY', 'packet sendp \@packets,delay=>2' );
    cmp_ok( time, '>=', $start+2, 'packet sendp delay >= 2' );

    # sniff
    my $stdout;
    my %params = ( 'count' => 1 );
    chomp( ( $stdout, $ret ) = invoke(\&PPC::sniff, %params));
    is( ref $ret, 'PPC::Packet', "packet sniff 1 return PPC::Packet" );
    like( $stdout, qr/^len=\d+,\s+caplen=\d+,\s+tv_sec=\d+,\s+tv_usec=\d+$/, "packet sniff 1 display stats" );
    
    $params{callback} = 'sniff_decode';
    chomp( ( $stdout, $ret ) = invoke(\&PPC::sniff, %params));
    is( ref $ret, 'PPC::Packet', "packet sniff 1 decode return PPC::Packet" );
    like( $stdout, qr/^ETH:\s+dst:/, "packet sniff 1 display decode" );

    $params{callback} = 'sniff_hexdump';
    chomp( ( $stdout, $ret ) = invoke(\&PPC::sniff, %params));
    is( ref $ret, 'PPC::Packet', "packet sniff 1 hexdump return PPC::Packet" );
    like( $stdout, qr/^0x00000:\s+/, "packet sniff 1 display hexdump" );
}

sub invoke {
    my $sub = shift;
    my ( $stdout, $ret );
    {
        local *STDOUT;
        open *STDOUT, '>', \$stdout
          or die "Cannot open STDOUT to a scalar: $!";
        $ret = &{$sub} (@_);
        close *STDOUT
          or die "Cannot close redirected STDOUT: $!";
    }
    return ( $stdout, $ret );
}
