package PPC;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

use Pod::Find qw( pod_where );
use Pod::Usage;

our $VERSION = '1.11';

use FindBin qw( $Bin );

my $scripts = $Bin . '/../lib/PPC';
for (@INC) {
    if ( -e ( $_ . "/PPC/scripts/.ppcscriptdir" ) ) {
        $scripts = $_;
        last;
    }
}

use PerlApp::Config;
our $PPC_GLOBALS = PerlApp::Config->new(
    conf_file   => 'ppc.conf',
    device      => undef,
    errmode     => 'stop',                # continue, stop, debug
    file_prefix => undef,
    help_cmd    => '-h',
    interface   => undef,
    scripts_dir => "$scripts/scripts/",
    wireshark   => undef
);

if ( $^O eq 'MSWin32' ) {
    if ( -e 'C:/Program Files/Wireshark/wireshark.exe' ) {
        $PPC_GLOBALS->{wireshark}
          = 'C:/Program Files/Wireshark/wireshark.exe';
    }
} else {
    if ( -e '/usr/local/bin/wireshark' ) {
        $PPC_GLOBALS->{wireshark} = '/usr/local/bin/wireshark';
    }
}

########################################################

use Carp qw ( confess );
use PPC::Interface;
use PPC::Macro;
use PPC::Packet;
use PPC::Packet::SRP;
use PPC::Layer;

# Import PPC::Layer:: ...
# Look through @INC in case of perl install and not all in same directory
my $dir = $Bin;
for (@INC) {
    if ( -e ( $_ . "/PPC/Layer" ) ) {
        $dir = $_;
        last;
    }
}

# Either found $dir or $dir is still default of $Bin from above
opendir my $DIR, $dir . "/PPC/Layer";
my @layers = readdir $DIR;
closedir $DIR;
for my $layer (@layers) {
    next if ( ( $layer =~ /^\./ ) or ( $layer !~ /\.pm$/ ) );
    require "PPC/Layer/" . $layer;
    $layer =~ s/\.pm$//;
    ( "PPC::Layer::" . $layer )->import;
}

# for useful functions at the shell prompt
use Data::Dumper;
use Time::HiRes qw( usleep gettimeofday tv_interval );
use Net::IPv4Addr qw( :all );    # Required by Net::Frame so will have it

#use Net::IPv6Addr;            # DITTO, but it doesn't export - so no use

use Net::Frame 1.17;
use Net::Frame::Simple 1.08;
use Net::Frame::Layer qw( :subs );

# alias
*NFL:: = \*Net::Frame::Layer::;

# Net::Frame::Layer::inet6Aton doesn't function like it says:  it won't
# work with names, only numbers.  This is due to differences in Socket
# and Socket6 (required by Net::Frame::Layer).
# This override fixes that by using the getHostIpv6Addr() function to
# get a number.
# START:  Fix inet6Aton
#    no warnings;
# Net::Frame::Layer version - used by other Net::Frame::Layer::xxx modules
#    *Net::Frame::Layer::inet6Aton      = sub { Socket6::inet_pton(Socket6::AF_INET6(), getHostIpv6Addr shift()) };
# And the imported one
#    *inet6Aton                         = sub { Socket6::inet_pton(Socket6::AF_INET6(), getHostIpv6Addr shift()) };
#    use warnings;
# END:  Fix inet6Aton
use Net::Frame::Layer::ETH qw( :consts );
use Net::Frame::Layer::ARP qw( :consts );
use Net::Frame::Layer::IPv4 qw( :consts );
use Net::Frame::Layer::TCP qw( :consts );
use Net::Frame::Layer::UDP qw( :consts );

my $minver_IPv6 = 1.08;
my $HAVE_IPv6   = 0;
eval "use Net::Frame::Layer::IPv6 $minver_IPv6 qw( :consts )";
if ( !$@ ) {
    $HAVE_IPv6 = 1;
}
my $minver_ICMPv4 = 1.05;
my $HAVE_ICMPv4   = 0;
eval "use Net::Frame::Layer::ICMPv4 $minver_ICMPv4 qw( :consts )";
if ( !$@ ) {
    $HAVE_ICMPv4 = 1;
}
my $minver_ICMPv6 = 1.09;
my $HAVE_ICMPv6   = 0;
eval "use Net::Frame::Layer::ICMPv6 $minver_ICMPv6 qw( :consts )";
if ( !$@ ) {
    eval "use Net::Frame::Layer::ICMPv6::Echo";
    $HAVE_ICMPv6 = 1;
}
use Net::Pcap 0.17;

########################################################

sub commands {
    my ($arg) = @_;

    if ( defined($arg) and ( $arg eq $PPC_GLOBALS->{help_cmd} ) ) {
        _help( __PACKAGE__, "COMMANDS/commands - list commands" );
    }

    my @rets;
    my $retType = wantarray;

    my $cmd;
    my $stash = __PACKAGE__ . '::';

    no strict 'refs';

    my $regex = qr/^.*$/;
    if ( defined($arg) ) {
        $regex = qr/$arg/;
    }

    for my $name ( sort( keys( %{$stash} ) ) ) {
        next if ( $name =~ /^_/ );

        my $sub = *{"${stash}${name}"}{CODE};
        next unless defined $sub;

        my $proto = prototype($sub);
        next if defined $proto and length($proto) == 0;

        if ( $name =~ /$regex/ ) {
            if ( !defined($retType) ) {
                print "$name\n";
            } else {
                $cmd->{$name}++;
            }
        }
    }

    if ( defined($retType) ) {
        for ( sort( keys( %{$cmd} ) ) ) {
            push @rets, $_;
        }
    }

    if ( !defined($retType) ) {
        return;
    } elsif ($retType) {
        return @rets;
    } else {
        return \@rets;
    }
}

sub config {
    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq $PPC_GLOBALS->{help_cmd} ) {
            _help( __PACKAGE__,
                "COMMANDS/config - manipulate configuration" );
        }
    }
    $PPC_GLOBALS->config(@_);
}

sub constants {
    my ($mod) = @_;

    if ( defined($mod) and ( $mod eq $PPC_GLOBALS->{help_cmd} ) ) {
        _help( __PACKAGE__,
            "COMMANDS/constants - print available constants" );
    }

    my @rets;
    my $retType = wantarray;

    if ( !defined($mod) ) {
        $mod = "Net::Frame::Layer::";
    }

    my $FOUND = 0;
    for my $c ( sort( keys(%constant::declared) ) ) {
        if ( $c =~ /^$mod/ ) {
            my @p = split /::/, $c;
            if ( !defined($retType) ) {
                print "$p[$#p]\n";
            } else {
                push @rets, $p[$#p];
            }
            $FOUND = 1;
        }
    }

    if ( !$FOUND ) {
        print "Module may not be loaded or doesn't provide any constants.\n";
        return;
    }

    if ( !defined($retType) ) {
        return;
    } elsif ($retType) {
        return @rets;
    } else {
        return \@rets;
    }
}

sub decode {
    my %params = (
        firstLayer => undef,
        packet     => undef
    );

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq $PPC_GLOBALS->{help_cmd} ) {
            _help( __PACKAGE__, "COMMANDS/decode - decode packet" );
        }
        ( $params{packet} ) = $arg;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $params{packet} = shift;
        }
        my %args = @_;
        for ( keys(%args) ) {
            if (/^-?packet$/i) {
                $params{packet} = $args{$_};
            } elsif (/^-?first(?:Layer)?$/i) {
                $params{firstLayer} = $args{$_};
            } else {
                _error("Unknown parameter: `$_'");
            }
        }
    }

    if ( !defined( $params{packet} ) ) {
        _error("No packet provided");
    }

    if ( ( ref $params{packet} ) ne "" ) {
        if ( ( ref $params{packet} ) =~ /^Net::Frame::Layer::/ ) {
            if ( !defined( $params{firstLayer} ) ) {
                $params{firstLayer} = $params{packet}->layer;
            }
            $params{packet}->pack;
        }
        $params{packet} = $params{packet}->raw;
    }

    if ( !defined( $params{firstLayer} ) ) {
        $params{firstLayer} = 'ETH';
    }

    my $ret = PPC::Packet->new(
        raw        => $params{packet},
        firstLayer => $params{firstLayer}
    );
    if ( defined wantarray ) {
        return $ret;
    } else {
        print $ret->print . "\n";
    }
}

sub device {
    my ($dev) = @_;

    if ( defined($dev) and ( $dev eq $PPC_GLOBALS->{help_cmd} ) ) {
        _help( __PACKAGE__, "COMMANDS/device - set device" );
    }

    if ( !defined($dev) ) {
        if ( !defined( $PPC_GLOBALS->{device} ) ) {
            if ( !defined wantarray ) {
                _error("No device currently set");
            }
            return;
        }
    } else {
        if ( _testpcap($dev) ) {
            $PPC_GLOBALS->{device} = $dev;
        } else {
            return;
        }
    }

    if ( defined wantarray ) {
        return $PPC_GLOBALS->{device};
    } else {
        print $PPC_GLOBALS->{device} . "\n";
    }
}

sub devices {
    my ($arg) = @_;

    if ( defined($arg) and ( $arg eq $PPC_GLOBALS->{help_cmd} ) ) {
        _help( __PACKAGE__, "COMMANDS/devices - list devices" );
    }

    my %devinfo;
    my $err;

    my @rets;
    my $retType = wantarray;

    my @devs = Net::Pcap::pcap_findalldevs( \%devinfo, \$err );
    for my $dev (@devs) {
        if ( !defined($retType) ) {
            print "$dev : $devinfo{$dev}\n";
        } else {
            push @rets, $dev;
        }
    }
    if ( !defined($retType) ) {
        return;
    } elsif ($retType) {
        return @rets;
    } else {
        return \@rets;
    }
}

sub dumper {
    my (@dump) = @_;

    if ( !defined( $dump[0] )
        or ( $dump[0] eq $PPC_GLOBALS->{help_cmd} ) ) {
        _help( __PACKAGE__,
            "COMMANDS/dumper - use Data::Dumper to dump variable" );
    }
    $Data::Dumper::Sortkeys = 1;
    print Dumper @dump;
}

sub file {
    my %params = (
        argv    => undef,
        line    => 0,
        verbose => 0
    );

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq $PPC_GLOBALS->{help_cmd} ) {
            _help( __PACKAGE__, "COMMANDS/file - open file" );
        }
        ( $params{file} ) = $arg;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $params{file} = shift;
        }
        my %args = @_;
        for ( keys(%args) ) {
            if (/^-?file$/i) {
                $params{file} = $args{$_};
            } elsif (/^-?argv$/i) {
                $params{argv}
                  = "\@ARGV = qw ( $args{$_} ); # ADDED argv => ...\n";
            } elsif (/^-?line$/i) {
                $params{line} = 1;
            } elsif (/^-?verbose$/i) {
                $params{verbose} = 1;
            } else {
                _error("Unknown parameter: `$_'");
            }
        }
    }

    if ( !defined $params{file} ) {
        _error("No file provided");
    }

    # if called by scripts(), we don't prepend file_prefix
    my $sub = ( caller(1) )[3];
    if ( ( !defined $sub or ( $sub ne 'PPC::scripts' ) )
        and defined( $PPC_GLOBALS->{file_prefix} ) ) {
        $params{file} = $PPC_GLOBALS->{file_prefix} . $params{file};
    }

    if ( -e $params{file} ) {
        open( my $IN, '<', $params{file} );

        no strict;
        use strict 'subs';

        if ( $params{line} ) {
            while (<$IN>) {
                print "$_" if ( $params{verbose} );

                # skip blank lines and #comments
                next if ( ( $_ =~ /^[\n\r]+$/ ) or ( $_ =~ /^\s*#/ ) );
                chomp $_;
                eval $_;
                warn $@ if $@;
            }
        } else {
            my $fullfile;
            if ( defined $params{argv} ) {
                $fullfile = $params{argv};
                print $fullfile if ( $params{verbose} );
            }
            while (<$IN>) {
                print "$_" if ( $params{verbose} );
                $fullfile .= $_;
            }
            eval $fullfile;
            warn $@ if $@;
        }

        close($IN);
    } else {
        _error("Cannot find file - `$params{file}'");
    }
}

sub hexdump {
    my ($p) = @_;

    if ( !defined($p)
        or ( defined($p) and ( $p eq $PPC_GLOBALS->{help_cmd} ) ) ) {
        _help( __PACKAGE__, "COMMANDS/hexdump - print hex dump" );
    }

    if ( ( ref $p ) ne "" ) {
        if ( ( ref $p ) =~ /^Net::Frame::Layer::/ ) {
            $p->pack;
        }
        $p = $p->raw;
    }

    # From Net::Telnet
    my ( $hexvals, $line );
    my $addr   = 0;
    my $offset = 0;
    my $len    = length($p) || 0;
    return if ( $len <= 0 );

    my @rets;
    my $retType = wantarray;

    # Print data in dump format.
    while ( $len > 0 ) {

        # Convert up to the next 16 chars to hex, padding w/ spaces.
        if ( $len >= 16 ) {
            $line = substr $p, $offset, 16;
        } else {
            $line = substr $p, $offset, $len;
        }
        $hexvals = unpack "H*", $line;
        $hexvals .= ' ' x ( 32 - length($hexvals) );

        # Place in 16 columns, each containing two hex digits.
        if ( defined wantarray ) {
            push @rets, unpack( "a2" x length($line), $hexvals );
        } else {
            $hexvals = sprintf(
                "%s %s %s %s %s %s %s %s  " x 2,
                unpack( "a2" x 16, $hexvals )
            );

            # For the ASCII column, change unprintable chars to a period.
            $line =~ s/[\000-\037,\177-\377]/./g;

            # Print the line in dump format.
            printf "0x%5.5lx: %s%s\n", $addr, $hexvals, $line;
        }
        $addr   += 16;
        $offset += 16;
        $len -= 16;
    }

    if ( !defined($retType) ) {
        return;
    } elsif ($retType) {
        return @rets;
    } else {
        return \@rets;
    }
}

sub interface {
    my ($intf) = @_;

    if ( defined($intf) and ( $intf eq $PPC_GLOBALS->{help_cmd} ) ) {
        _help( __PACKAGE__, "COMMANDS/interface - get or set interface" );
    }

    if ( !defined($intf) ) {
        if ( !defined( $PPC_GLOBALS->{interface} ) ) {
            if ( !defined wantarray ) {
                _error("No interface currently set");
            }
            return;
        }
    } else {

        # Dump if requested and exists
        if ( ( $intf eq ":dump" ) and defined( $PPC_GLOBALS->{interface} ) ) {
            $PPC_GLOBALS->{interface}->dump;
            return;
        }

        # Get interface
        my $interface = PPC::Interface->new($intf);
        if ( !defined $interface ) {
            _error( PPC::Interface->error );
        } else {
            $PPC_GLOBALS->{interface} = $interface;
            if ( defined $PPC_GLOBALS->{interface}->devicename ) {
                my $d = device( $PPC_GLOBALS->{interface}->devicename );
            }
        }
    }

    if ( defined wantarray ) {
        return $PPC_GLOBALS->{interface};
    } else {
        print $PPC_GLOBALS->{interface}->name . "\n";
    }
}

sub interfaces {
    my ($intf) = @_;

    if ( defined($intf) and ( $intf eq $PPC_GLOBALS->{help_cmd} ) ) {
        _help( __PACKAGE__,
            "COMMANDS/interfaces - list available interfaces" );
    }

    my $retType = wantarray;
    my @rets = PPC::Interface->interfaces;

    if ( !defined $retType ) {
        for (@rets) {
            print "$_\n";
        }
    } elsif ($retType) {
        return @rets;
    } else {
        return \@rets;
    }
}

sub nfl {
    my ($mod) = @_;

    if ( !defined($mod) or ( $mod eq $PPC_GLOBALS->{help_cmd} ) ) {
        _help( __PACKAGE__,
            "COMMANDS/nfl - Net::Frame::Layer:: alias" );
    }

    my $prefix = 'Net::Frame::Layer::';
    my $origMod = $mod;
    $mod =~ s/^$prefix//;
    my @mods;
    my $FOUND = 0;
    for my $m ( sort( keys(%INC) ) ) {
        my $t = $m;
        $t =~ s/\//::/g;
        $t =~ s/\.pm$//;

        if ( $t =~ /^$prefix$mod/ ) {
            push @mods, $t;
            $FOUND = 1;
        }
    }
    if ( !$FOUND ) {
        printf "Module(s) not found%s",
          ( defined $mod ) ? " - `$prefix$origMod'\n" : "\n";
    }

    for my $modName ( @mods ) {
        $modName =~ s/^$prefix//;
        no strict 'refs';
        if ( !__PACKAGE__->can($modName) ) {
            *{$modName} = sub {
                my $p = PPC::Layer::_layer( $modName, @_ );
                if ( !defined wantarray ) {
                    print $p->print . "\n";
                }
                return $p;
            }
        }
    }
}

sub nftxt {
    my ($arg) = @_;

    if ( !defined($arg) or ( $arg eq $PPC_GLOBALS->{help_cmd} ) ) {
        _help( __PACKAGE__, "COMMANDS/nftxt - render Net::Frame syntax" );
    }

    # Net::Frame since can do individual layers or PPC::Packet
    if ( ( ( ref $arg ) =~ /^Net::Frame::/ ) 
        or ( ( ref $arg ) =~ /^PPC::Packet$/ ) ) {
        my @layers;

        # Net::Frame::Simple or PPC::Packet to get all layers
        if ( ( ( ref $arg ) =~ /^Net::Frame::Simple$/ ) 
            or ( ( ref $arg ) =~ /^PPC::Packet$/ ) ) {
            for ( $arg->layers ) { push @layers, $_ }
        } else {
            push @layers, $arg;
        }

        for my $layer ( 0 .. $#layers ) {
            _layers( $layers[$layer], 1 );
        }

        sub _layers {
            my ( $layer, $depth ) = @_;
            my $ref  = ref $layer;
            my $vars = "@" . $ref . "::AS";
            my $vara = "@" . $ref . "::AA";
            printf "$ref->new(\n";
            for ( eval { eval $vars } ) {
                if ( defined( $layer->$_ ) ) {
                    printf "    " x $depth . "$_ => ";
                    my $l = sprintf "%s", $layer->$_;
                    if ( $l =~ /^Net::Frame::Layer::/ ) {
                        _layers( $layer->$_, $depth + 1 );
                    } else {
                        if ( $layer->$_ =~ /[\000-\037,\177-\377]/ ) {
                            my $out;
                            for ( split //, $layer->$_ ) {
                                $out .= sprintf "%0.2x", ord $_;
                            }
                            printf "(pack \"H*\", '" . $out . "'),\n";
                        } else {
                            printf "'%s',\n", $layer->$_;
                        }
                    }
                }
            }
            for ( eval { eval $vara } ) {
                if ( defined( $layer->$_ ) ) {
                    printf "    $_ => ";
                    my $l = sprintf "%s", $layer->$_;
                    if ( $l =~ /^Net::Frame::Layer::/ ) {
                        print "[";
                        _layers( $layer->$_, $depth + 1 );
                        print "    " x $depth . "],\n";
                    } else {
                        printf "'%s',\n", $layer->$_;
                    }
                }
            }
            printf "    " x ( $depth - 1 ) . ")"
              . ( ( $depth > 1 ) ? "," : ";" ) . "\n";
        }
    } else {
        _error("Not a valid Net::Frame object - `$arg'");
    }
}

sub rdpcap {
    my ($file) = @_;

    if ( !defined($file) or ( $file eq $PPC_GLOBALS->{help_cmd} ) ) {
        _help( __PACKAGE__, "COMMANDS/rdpcap - read pcap file" );
    }

    my $retType = wantarray;
    my $err;
    my $pcap = Net::Pcap::pcap_open_offline( $file, \$err );
    if ( !defined $pcap ) {
        _error("Cannot open file - `$file': $err");
    }

    my @packets;
    Net::Pcap::pcap_loop( $pcap, -1, \&_sniff_read, \@packets );

    sub _sniff_read {
        my ( $user_data, $header, $packet ) = @_;
        $packet
          = PPC::Packet->new( raw => $packet, firstLayer => 'ETH' );
        $packet->timestamp( $header->{tv_sec} . "." . $header->{tv_usec} );
        push @{$user_data}, $packet;
    }

    Net::Pcap::pcap_close($pcap);

    if ( !defined($retType) ) {
        printf "Read %i packet%s\n", scalar @packets,
          ( scalar @packets > 1 ) ? "s" : "";
    } elsif ($retType) {
        return @packets;
    } else {
        return \@packets;
    }
}

sub scripts {
    my $script;
    my %params;

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq $PPC_GLOBALS->{help_cmd} ) {
            _help( __PACKAGE__,
                "COMMANDS/scripts - execute scripts from script directory" );
        }
        ($script) = $arg;
    } else {
        if ( ( @_ % 2 ) == 1 ) {
            $script = shift;
        }
        my %args = @_;
        for ( keys(%args) ) {
            if (/^-?script$/i) {
                $script = $args{$_};
            } else {

                #pass-through
                $params{$_} = $args{$_};
            }
        }
    }

    if ( defined($script) ) {
        file( "$PPC_GLOBALS->{scripts_dir}$script", %params );
    } else {
        my $dir;
        if ( !opendir $dir, $PPC_GLOBALS->{scripts_dir} ) {
            _error( "Cannot open directory - `"
                  . $PPC_GLOBALS->{scripts_dir}
                  . "'" );
        }
        my @temp = readdir $dir;
        closedir $dir;
        my @files;
        for my $file (@temp) {

            # ignore the current, parent directory and files starting with "."
            next if ( $file =~ /^\./ );
            push @files, $file;
        }

        my $retType = wantarray;
        if ( !defined $retType ) {
            for (@files) {
                print "$_\n";
            }
        } elsif ($retType) {
            return @files;
        } else {
            return \@files;
        }
    }
}

sub wrpcap {
    my ( $file, @packets ) = @_;

    if ( !defined($file) or ( $file eq $PPC_GLOBALS->{help_cmd} ) ) {
        _help( __PACKAGE__, "COMMANDS/wrpcap - write pcap file" );
    }

    if ( !defined $packets[0] ) {
        _error("No packets to write");
    }
    my @pa;
    if ( ref $packets[0] eq "ARRAY" ) {
        @pa = map { $_ } @{$packets[0]};
    } else {
        @pa = map { $_ } @packets;
    }

    if ( !defined $PPC_GLOBALS->{device} ) {
        _error("No device currently set [required for pcap_open]");
    }

    my $retType = wantarray;
    my $err;
    # Windows only
    # my %devinfo;
    # my $pcap = Net::Pcap::pcap_open( $PPC_GLOBALS->{device},
    #     100, 0, 1000, \%devinfo, \$err );
    my $pcap = Net::Pcap::pcap_open_dead( DLT_EN10MB, 65535 );

    my $dump;
    if ( !defined( $dump = Net::Pcap::pcap_dump_open( $pcap, $file ) ) ) {
        _error("Cannot write to file - `$file'");
    }

    my %header = (
        tv_sec  => 0,
        tv_usec => 0
    );
    my $i = 0;
    for my $packet (@pa) {
        if ( ref $packet ) {
            ( $header{tv_sec}, $header{tv_usec} ) = split /\./,
              $packet->timestamp;
            $packet = $packet->raw;
        }
        $header{len} = $header{caplen} = length($packet);
        Net::Pcap::pcap_dump( $dump, \%header, $packet );
        $i++;
    }

    Net::Pcap::pcap_dump_close($dump);
    Net::Pcap::pcap_close($pcap);

    if ( !defined($retType) ) {
        printf "Wrote $i packet%s\n", ( $i > 1 ) ? "s" : "";
    } else {
        return $i;
    }
}

sub _error {
    my ($errstr) = @_;

    my $errmode = $PPC_GLOBALS->{errmode};
    if ( $errmode eq 'stop' ) {
        die $errstr . "\n";
    } elsif ( $errmode eq 'continue' ) {
        warn $errstr . "\n";
        return;
    } elsif ( $errmode eq 'debug' ) {

        #print (caller(1))[3] . " says\n"; # sub
        confess $errstr;
    } else {
        warn "Unknown error mode: `$errmode'\n";
        die $errstr . "\n";
    }

}

sub _pcap_prefix {
    my ($arg) = @_;

    if ( !defined $PPC_GLOBALS->{interface} ) {
        _error("No pcap_prefix currently set");
    }

    my $prev_pcap_prefix = $PPC_GLOBALS->{interface}->pcap_prefix;
    if ( defined($arg) ) {
        $PPC_GLOBALS->{interface}->pcap_prefix($arg);
    }

    if ( defined( $PPC_GLOBALS->{interface}->devicename ) ) {
        if (!defined(
                my $d = device( $PPC_GLOBALS->{interface}->devicename )
            )
          ) {
            $PPC_GLOBALS->{interface}->pcap_prefix($prev_pcap_prefix);
        }
    }

    if ( defined wantarray ) {
        return $PPC_GLOBALS->{interface}->pcap_prefix;
    } else {
        print $PPC_GLOBALS->{interface}->pcap_prefix . "\n";
    }
}

sub _testpcap {
    my ($dev) = @_;

    my $err;
    # Windows only
    # my %devinfo;
    # my $pcap = Net::Pcap::pcap_open( $dev, 100, 0, 1000, \%devinfo, \$err );
    my $pcap = Net::Pcap::pcap_open_live( $dev, 100, 0, 1000, \$err );
    if ( !defined($pcap) ) {
        warn "Cannot open device - `$dev': $err\n";
        return 0;
    }
    Net::Pcap::pcap_close($pcap);
    return 1;
}

sub _help {
    my ( $pkg, $section, $external ) = @_;

    pod2usage(
        -verbose  => 99,
        -exitval  => "NOEXIT",
        -sections => $section,
        -input    => pod_where( {-inc => 1}, $pkg )
    );

    if ( defined $external ) {
        system "perldoc $external";
    }

    die "\n";
}

sub _help_full {
    my ($pkg) = @_;

    pod2usage(
        -verbose => 2,
        -exitval => "NOEXIT",
        -input   => pod_where( {-inc => 1}, $pkg )
    );

    die "\n";
}

1;

__END__

########################################################
# Start POD
########################################################

=head1 NAME

PPC - Perl Packet Crafter

=head1 SYNOPSIS

 package PPC;
 use PPC;

=head1 DESCRIPTION

A packet crafting capability in Perl using Net::Frame modules and Net::Pcap.

At a minimum, the required packages in addition to core modules are:

  Module                    Notes
  --------------------------------------------------------------------
  Net::Frame                provides Net::Frame::Layer::ETH/IPv4 and others
  Net::Frame::Simple        for encoding / decoding packets
  Net::Pcap                 for sending / capturing packets
  ------------------------------OPTIONAL------------------------------
  Net::Frame::Layer::IPv6   only required for IPv6 support
  Net::Frame::Layer::ICMPv4 only required for ICMPv4 support
  Net::Frame::Layer::ICMPv6 only required for ICMPv6 support
  Net::Frame::Layer::[xxx]  Additional Net::Frame::Layer sub modules

=head1 COMMANDS

=head2 commands - list commands

 commands ["regex"]

List available commands.  Optional regular expression filters returns.

=head2 config - manipulate configuration

 config ["OPTIONS"]

Print or modify configuration.  See B<PerlApp::Config> for details.

PPC configuration values:

  Option      Description                         Default Value
  ------      -----------                         -------------
  conf_file   Configuration file to run at        ppc.conf
              startup.
  device      Device for Net::Pcap operations.    (none)
  errmode     'continue' - print error and try    stop
                to continue
              'stop' - print error and return 
                prompt
              'debug' - print error, debug trace
                and return prompt
  file_prefix Prefix to prepend to all files for  (none)
                'file' command.
  help_cmd    Text to provide as argument to any  -h
                command to get inline help.
  interface   Interface to use data from.         (none)
  scripts_dir Directory to look for files from    $Bin/scripts
                'scripts' command.
  wireshark   Path to and command for Wireshark.  (none, unless found)

=head2 constants - print available constants

 constants ["moduleName"]

Print constants provided by given module.  No argument prints constants
from all Net::Frame::Layer::[modules].

Note Net::Frame::Layer::[modules] must be used with C<qw(:consts)> to
export the constants to this program.  See their respective documentation
for details.

=head2 decode - decode packet

 [$ret =] decode $packet [OPTIONS]

Print decode of raw B<$packet>.  Returns B<PPC::Packet> object.

  Option     Description                       Default Value
  ------     -----------                       -------------
  firstLayer Layer to start decode from        'ETH'
  packet     Packet to decode                  (none)

Single option indicates B<packet>.

=head2 device - set device

 device 'devicename'

Sets the device for Net::Pcap send.  B<Devicename> is the adapater name found
with C<devices> command, for example:

 \Device\NPF_{1234ABCD-12AB-34CD-56EF-123456ABCDEF}

Called with no argument displays currently set device.

This can be used to set a different outgoing device from the interface.  
Note, the source and destination MAC and source IPv4 addresses may need 
to be set manually when constructing packets.

=head2 devices - list devices

 devices

List available network devices.

=head2 dumper - use Data::Dumper to dump variable

 dumper $var

Displays B<$var> with Data::Dumper.

=head2 file - open file

 file "[[/]path/to/]file" [OPTIONS]

Open and parse provided file of Perl commands.  By default, entire file
is read and then parsed at once.

  Option     Description                       Default Value
  ------     -----------                       -------------
  argv       Argument string to pass to the    (none)
               @ARGV variable in the file
  file       File (with optional path) to      (none)
               execute.
  line       Parse file line-by-line (1 = on)  (off)
  verbose    Show file content       (1 = on)  (off)

Current directory is searched unless relative or absolute path is also 
provided.  If configuration value B<file_prefix> exists, it is prepended to 
B<file> before opening.

To pass parameters to a file the B<argv> option can contain a string such as 
would be present on the command line if the file was called from the command 
line.  For example, a script may take an option switch "-r" and a string 
option for hostname such as "-h name".  The B<argv> option can be used as 
such:

  file "filename.txt", argv => "-h name -r";

In "filename.txt", the arguments can be processed from @ARGV with standard 
modules like B<Getopt::Long>.  See "scripts/IPv4-ICMPv4-EchoRequest.ppcs" for 
an example.

Note the B<line> option should I<never> be used unless debugging or some 
other strange and odd situation.

Single option indicates B<file>.

=head2 hexdump - print hex dump

 [$hex_array =] hexdump $var | "string"

Displays hex dump of B<$var> or B<string>.  Optional return value is array 
of hexdump by offset (decimal index start at 0).

=head2 interface - get or set interface

 [$if =] interface ["Interface Name" | ":dump"]

Sets the interface, source and destination MAC, source IPv4 (and IPv6 if
available).  Also sets the device for Net::Pcap send.  B<Interface Name> is the
friendly name found with C<ipconfig>, for example "Local Area Connection".
Called with B<:dump> keyword, displays all current interface information.
Called with no argument displays currently set interface name.  Optional return 
value is B<PPC::Interface> object.

=head2 interfaces - list available interfaces

 interfaces

List the available interfaces.

=head2 nfl - Net::Frame::Layer:: alias

  use Net::Frame::Layer::NAME
  nfl 'Net::Frame::Layer::NAME'  # or just:  nfl 'NAME'

Alias the trailing text 'NAME' after Net::Frame::Layer:: module to NAME so 
it can be called as a layer without typing the full Net::Frame::Layer:: module 
qualifier.  By default, all sub-modules of Net::Frame::Layer::NAME that are 
imported in the 'use' are also aliased.  For example, if the above 
example has a subtree:

  Net::Frame::Layer::NAME             => NAME
  Net::Frame::Layer::NAME::Sub1       => NAME::Sub1
  Net::Frame::Layer::NAME::Sub2       => NAME::Sub1
  Net::Frame::Layer::NAME::Deep::Sub  => NAME::Deep::Sub

This command should not redefine any existing subs already defined.

=head2 nftxt - render Net::Frame syntax

 nftxt $packet

Renders the B<Net::Frame> syntax for the object passed as $packet.  Object can 
be a B<Net::Frame::Layer> object, a B<Net::Frame::Simple> or B<PPC::Packet> 
packet.

=head2 rdpcap - read pcap file

 $packets = rdpcap "file"
 @packets = rdpcap "file"

Reads saved pcap file B<file> and returns packets as B<PPC::Packet> 
objects in reference to an array in scalar context or array in array context.

=head2 scripts - execute scripts from script directory

 [@scripts =] scripts ["script"]

Shortcut to B<file> command to open a script in the B<scripts_dir> directory 
without having to provide the path.  Called with no argument lists contents 
of scripts directory.  Optional return value is array of files in the 
B<scripts_dir> directory.

See B<file> for additional options, including passing parameters to a script.

=head2 wrpcap - write pcap file

 [$packets =] wrpcap "file", @packets

Writes array B<@packets> to B<file> in pcap format.  Packets may be an array,
a reference to an array or a single scalar.  Packet format may be raw, 
B<PPC::Packet> or B<Net::Frame::Simple> object.  Returns number of packets 
written.

=head1 SEE ALSO

L<PPC::Interface>, L<PPC::Layer>, L<PPC::Macro>, L<PPC::Packet>, 
L<PPC::Packet::SRP>, L<PPC::Plugin> L<Net::Frame>, L<Net::Pcap>

=head1 ACKNOWLEDGEMENTS

Special thanks to Patrice E<lt>GomoRE<gt> Auffret without whose 
Net::Frame::[...] modules, this would not be possible.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2012, 2016 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
