use strict;
use warnings;

use Test::More tests => 41;

# Need PPC, PPC::Packet loaded - so load PPC
use PPC;

#########################

my $ret;
my $stdout;

use Net::Frame::Layer qw(:subs);

SKIP: {
    skip "developer-only tests - set PPC_INTERFACE to interface name", 41 unless $ENV{PPC_INTERFACE};

    my $if;
    is( ref ( $if = PPC::interface($ENV{PPC_INTERFACE}) ), 'PPC::Interface', "interface set to $ENV{PPC_INTERFACE}" );

    my $packet = PPC::Packet::packet( PPC::ETHER, PPC::IPv4(getHostIpv4Addr 'www.google.com'), PPC::TCP(80) );

    # srp
    is( ref ( $ret = PPC::srp($packet) ), 'PPC::Packet::SRP', "srp returns PPC::Packet::SRP object" );

    # sent()
    is( [$ret->sent(1)->layers]->[0]->dst, [$packet->layers]->[0]->dst, "srp sent(1) 0 dst verify" );
    is( [$ret->sent(1)->layers]->[0]->src, [$packet->layers]->[0]->src, "srp sent(1) 0 src verify" ); 
    like( [$ret->sent(1)->layers]->[1]->dst, qr/^(?:\d{1,3}\.){3}\d{1,3}$/, "srp sent(1) 1 dst verify" );
    is( [$ret->sent(1)->layers]->[1]->src, [$packet->layers]->[1]->src, "srp sent(1) 1 src verify" );

    is( [$ret->sent(1,1)->layers]->[0]->dst, [$packet->layers]->[0]->dst, "srp sent(1,1) 0 dst verify" );
    is( [$ret->sent(1,1)->layers]->[0]->src, [$packet->layers]->[0]->src, "srp sent(1,1) 0 src verify" ); 
    like( [$ret->sent(1,1)->layers]->[1]->dst, qr/^(?:\d{1,3}\.){3}\d{1,3}$/, "srp sent(1,1) 1 dst verify" );
    is( [$ret->sent(1,1)->layers]->[1]->src, [$packet->layers]->[1]->src, "srp sent(1,1) 1 src verify" );

    # recv()
    is( [$ret->recv(1)->layers]->[0]->dst, [$packet->layers]->[0]->src, "srp recv(1) 0 dst verify" );
    is( [$ret->recv(1)->layers]->[0]->src, [$packet->layers]->[0]->dst, "srp recv(1) 0 src verify" ); 
    is( [$ret->recv(1)->layers]->[1]->dst, [$packet->layers]->[1]->src, "srp recv(1) 1 dst verify" );
    like( [$ret->recv(1)->layers]->[1]->src, qr/^(?:\d{1,3}\.){3}\d{1,3}$/, "srp recv(1) 1 src verify" );

    is( [$ret->recv(1,1)->layers]->[0]->dst, [$packet->layers]->[0]->src, "srp recv(1,1) 0 dst verify" );
    is( [$ret->recv(1,1)->layers]->[0]->src, [$packet->layers]->[0]->dst, "srp recv(1,1) 0 src verify" ); 
    is( [$ret->recv(1,1)->layers]->[1]->dst, [$packet->layers]->[1]->src, "srp recv(1,1) 1 dst verify" );
    like( [$ret->recv(1,1)->layers]->[1]->src, qr/^(?:\d{1,3}\.){3}\d{1,3}$/, "srp recv(1,1) 1 src verify" );

    # time()
    like( $ret->time(1), qr/\d+/, "srp time(1) verify" );
    like( $ret->time(1,1), qr/\d+/, "srp time(1,1) verify" );

    # list()
    is( ref $ret->list, 'ARRAY', "srp list returns ARRAY" );

    # sent, recv, time and list version with multiple packets with 1 not received
    # $packet2 should *not* generate a receive
    my $packet2 = PPC::Packet::packet( PPC::ETHER, PPC::IPv4('8.8.8.8'), PPC::TCP(80) );
    my @packets = ( $packet2, $packet );
    $ret = PPC::srp(\@packets);
    is( $#{$ret->list}, 2, "srp \$ret->list ARRAY of size 3" );
    is( $#{$ret->listrecv}, 0, "srp \$ret->listrecv ARRAY of size 1" );
    is( $#{$ret->listsent}, 1, "srp \$ret->listsent ARRAY of size 2" );
    is( $#{$ret->listtime}, 0, "srp \$ret->listtime ARRAY of size 1" );
    is( $#{$ret->recv}, 1, "srp \$ret->recv ARRAY of size 2" );
    is( $ret->recv->[0], undef, "srp \$ret->recv->[0] undef" );
    is( $#{$ret->sent}, 1, "srp \$ret->sent ARRAY of size 2" );
    is( $#{$ret->time}, 1, "srp \$ret->time ARRAY of size 2" );
    is( $ret->time->[0], undef, "srp \$ret->time->[0] undef" );

    chomp( $stdout = invoke2(\&PPC::Packet::SRP::list, $ret));
    like( $stdout, qr/^PPC::Packet=ARRAY.*\nPPC::Packet=ARRAY.*\nPPC::Packet=ARRAY.*$/, "srp \$ret->list display" );
    chomp( $stdout = invoke2(\&PPC::Packet::SRP::listrecv, $ret));
    like( $stdout, qr/^PPC::Packet=ARRAY.*$/, "srp \$ret->listrecv display" );
    chomp( $stdout = invoke2(\&PPC::Packet::SRP::listsent, $ret));
    like( $stdout, qr/^PPC::Packet=ARRAY.*\nPPC::Packet=ARRAY.*$/, "srp \$ret->listsent display" );
    chomp( $stdout = invoke2(\&PPC::Packet::SRP::listtime, $ret));
    like( $stdout, qr/^0\.\d+$/, "srp \$ret->listtime display" );
    chomp( $stdout = invoke2(\&PPC::Packet::SRP::recv, $ret));
    like( $stdout, qr/^\s+1\s+:\s*No recv packet\n\s+2,1\s+:\s+PPC::Packet=ARRAY.*$/, "srp \$ret->recv display" );
    chomp( $stdout = invoke2(\&PPC::Packet::SRP::sent, $ret));
    like( $stdout, qr/^\s+1:\s+PPC::Packet=ARRAY.*\n\s+2:\s+PPC::Packet=ARRAY/, "srp \$ret->sent display" );
    chomp( $stdout = invoke2(\&PPC::Packet::SRP::time, $ret));
    like( $stdout, qr/^\s+1\s+:\s*No time interval\n\s+2,1\s+:\s+0\.\d+$/, "srp \$ret->time display" );

    # report()
    chomp( ( $stdout, $ret ) = invoke(\&PPC::Packet::SRP::report, $ret));
    like( $stdout, qr/^Packet 1\n\s+Sent:\s+/, "srp report display" );

    # srp options
    @packets = ( $packet, $packet );
    my $start = time;
    chomp( ( $stdout, $ret ) = invoke(\&PPC::Packet::SRP::srp, \@packets, count=>2,delay=>2,detail=>1));
    is( scalar @{$ret}, 4, 'srp \@packets, count=>2 [ret = 4]' );
    like( $stdout, qr/(?:Sent\s+\=\>\s+Received){1,4}/, 'srp \@packets, detail=>1' );
    cmp_ok( time, '>=', $start+6, 'srp \@packets, delay=>2' );
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

sub invoke2 {
    my $sub = shift;
    my $stdout;
    {
        local *STDOUT;
        open *STDOUT, '>', \$stdout
          or die "Cannot open STDOUT to a scalar: $!";
        &{$sub} (@_);
        close *STDOUT
          or die "Cannot close redirected STDOUT: $!";
    }
    return $stdout;
}
