use strict;
use warnings;

use Test::More tests => 79;
BEGIN { use_ok('PPC') };

#########################

my ( $ret, $ret1 );
# for evals
local $SIG{__WARN__} = sub { $ret = $_[0]; };
local $SIG{__DIE__} = sub { $ret = $_[0]; };

# commands
$ret = PPC::commands();
ok ( $#{$ret} > 50, "commands all" );
$ret = PPC::commands( 'getHostIpv' );
is( $#{$ret}, 2, "commands filter" );
is( $ret->[0], 'getHostIpv4Addr', "commands 0" );
is( $ret->[1], 'getHostIpv4Addrs', "commands 1" );
is( $ret->[2], 'getHostIpv6Addr', "commands 2" );

# config
is( ref ( $ret = PPC::config() ), 'HASH', "config all" );
is( $ret->{conf_file}, 'ppc.conf', "config all conf_file" );
is( $ret->{device}, undef, "config all device" );
is( $ret->{errmode}, 'stop', "config all errmode" );
is( $ret->{file_prefix}, undef, "config all file_prefix" );
is( $ret->{help_cmd}, '-h', "config all help_cmd" );
ok( $ret->{scripts_dir} =~ /\/\.\.\/lib\/PPC\/scripts\/$/, "config all scripts_dir" );

is( PPC::config('conf_file'), 'ppc.conf', "config conf_file" );
is( PPC::config('device'), undef, "config device" );
is( PPC::config('errmode'), 'stop', "config erromode" );
is( PPC::config('file_prefix'), undef, "config file_prefix" );
is( PPC::config('help_cmd'), '-h', "config help_cmd" );
ok( PPC::config('scripts_dir') =~ /\/\.\.\/lib\/PPC\/scripts\/$/, "config scripts_dir" );

# constants
$ret = PPC::constants();
ok ( $#{$ret} > 50, "constants all" );
$ret = PPC::constants('Net::Frame::Layer::IPv4');
is( $#{$ret}, 30, "constants filter [e.g., Net::Frame::Layer::IPv4]" );
is( $ret->[0], 'NF_IPv4_DONT_FRAGMENT', "constants 0 [e.g., Net::Frame::Layer::IPv4]" );

# decode
use Net::Frame::Simple;
use Net::Frame::Layer::ETH;
use Net::Frame::Layer::IPv4;
use Net::Frame::Layer::TCP;
my $packet = Net::Frame::Simple->new(
    layers => [
        Net::Frame::Layer::ETH->new,
        Net::Frame::Layer::IPv4->new,
        Net::Frame::Layer::TCP->new,
    ]
);
is( ref PPC::decode($packet), 'PPC::Packet', "decode packet" );
is( ref PPC::decode($packet->raw), 'PPC::Packet', "decode raw" );

# device
is( $ret = PPC::device, undef, "device [none]" );
  eval { PPC::device('invalid'); };
like( $ret, qr/^Cannot open device - `invalid':/, "device invalid" );

# devices
is( ref ( $ret = PPC::devices() ), 'ARRAY', "devices" );
# device (con't)
is( PPC::device($ret->[0]), $ret->[0],  "device $ret->[0]" );

# dumper
# we can skip testing Data::Dumper

# file
  eval { PPC::file('invalid'); };
is( $ret, "Cannot find file - `invalid'\n", "file invalid" );

# hexdump
my $i;
is( ref ( $ret = PPC::hexdump($packet) ), 'ARRAY', "hexdump packet" );
$i = 0;
for ( qw ( ff ff ff ff ff ff 00 00  00 00 00 00 08 00 45 00 ) ) {
    is( $ret->[$i++], $_, "hexdump packet - $_" );
}

is( ref ( $ret = PPC::hexdump($packet->raw) ), 'ARRAY', "hexdump raw" );
$i = 0;
for ( qw ( ff ff ff ff ff ff 00 00  00 00 00 00 08 00 45 00 ) ) {
    is( $ret->[$i++], $_, "hexdump packet - $_" );
}

# interface
is( $ret = PPC::interface, undef, "interface [none]" );

# interface invalid error is dependent on PPC::Interface::<layer>
SKIP: {
    skip "developer-only tests - set PPC_DEVELOPER", 1 unless $ENV{PPC_DEVELOPER};

      eval { PPC::interface('invalid'); };
    is( $ret, "Interface `invalid' not found\n",  "interface invalid" );
}

# interfaces
is( ref ( $ret = PPC::interfaces() ), 'ARRAY', "interfaces" );
# interface (con't)
is( ref ( $ret1 = PPC::interface($ret->[0]) ), 'PPC::Interface',  "interface $ret->[0]" );

# nftxt
  eval { PPC::nftxt('invalid'); };
is( $ret, "Not a valid Net::Frame object - `invalid'\n", "nftxt invalid" );

SKIP: {
    skip "developer-only tests - set PPC_DEVELOPER", 1 unless $ENV{PPC_DEVELOPER};

    my $stdout;
    chomp( ( $stdout, $ret ) = invoke(\&PPC::nftxt, $packet));

my $regex = qr/Net::Frame::Layer::ETH->new\(
    dst => 'ff:ff:ff:ff:ff:ff',
    src => '00:00:00:00:00:00',
    type => '2048',
\);
Net::Frame::Layer::IPv4->new\(
    id => '\d+',
    ttl => '128',
    src => '127.0.0.1',
    dst => '127.0.0.1',
    protocol => '6',
    checksum => '\d+',
    flags => '0',
    offset => '0',
    version => '4',
    tos => '0',
    length => '40',
    hlen => '5',
    options => '',
    noFixLen => '0',
\);
Net::Frame::Layer::TCP->new\(
    src => '\d{1,5}',
    dst => '0',
    flags => '2',
    win => '65535',
    seq => '\d+',
    ack => '0',
    off => '5',
    x2 => '0',
    checksum => '\d+',
    urp => '0',
    options => '',
\);/;

    like( $stdout, $regex, "nftxt object" );
}

# scripts
is( ref ( $ret = PPC::scripts() ), 'ARRAY', "scripts directory listing" );
is( $#{$ret}, 47, "scripts found files" );


# wrpcap, rdpcap
is( ($ret = PPC::wrpcap('out.pcap', $packet) ), 1, "wrpcap write file" );
ok( -e 'out.pcap', "wrpcap wrote file exists" );
is( ref ( $ret = PPC::rdpcap('out.pcap')), 'ARRAY', "rdpcap read file" );
is( [$ret->[0]->layers]->[0]->dst, [$packet->layers]->[0]->dst, "wr/rdpcap verify 0 dst" );
is( [$ret->[0]->layers]->[0]->src, [$packet->layers]->[0]->src, "wr/rdpcap verify 0 src" );
is( [$ret->[0]->layers]->[0]->type, [$packet->layers]->[0]->type, "wr/rdpcap verify 0 type" );
is( [$ret->[0]->layers]->[1]->dst, [$packet->layers]->[1]->dst, "wr/rdpcap verify 1 dst" );
is( [$ret->[0]->layers]->[1]->src, [$packet->layers]->[1]->src, "wr/rdpcap verify 1 src" );
unlink 'out.pcap';

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
