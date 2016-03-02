#!/usr/bin/perl
########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

BEGIN {
    use FindBin qw($Bin);
    unshift @INC, $Bin . '/../lib';
}

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::Usage;

########################################################
# Start Additional USE
########################################################
use Cwd;
use PPC;
use PerlApp::Shell;
use PerlApp::Config qw ( config_where );
########################################################
# End Additional USE
########################################################

my %opt;
my ( $opt_help, $opt_man, $opt_versions );

GetOptions(
    'c|command=s'   => \$opt{command},
    'f|config=s'    => \$opt{conf},
    'H|header!'     => \$opt{header},
    'i|interface=s' => \$opt{interface},
    'I|Interfaces!' => \$opt{interfaces},
    's|session=s'   => \$opt{sess_file},
    'h|help!'       => \$opt_help,
    'm|man!'        => \$opt_man,
    'v|versions!'   => \$opt_versions
) or pod2usage( -verbose => 0 );

pod2usage( -verbose => 1 ) if defined $opt_help;
pod2usage( -verbose => 2 ) if defined $opt_man;

if ( defined $opt_versions ) {
    print
      "\nModules, Perl, OS, Program info:\n",
      "  $0\n",
      "  Version\n",
      "    strict                    $strict::VERSION\n",
      "    warnings                  $warnings::VERSION\n",
      "    Getopt::Long              $Getopt::Long::VERSION\n",
      "    Pod::Usage                $Pod::Usage::VERSION\n";
########################################################
    # Start Additional USE
########################################################
    print
      "    Cwd                       $Cwd::VERSION\n",
      "    PPC                       $PPC::VERSION\n",
      "    PerlApp::Shell            $PerlApp::Shell::VERSION\n";
########################################################
    # End Additional USE
########################################################
    print
      "    Perl version              $]\n",
      "    Perl executable           $^X\n",
      "    OS                        $^O\n",
      "\n\n";
    exit;
}

########################################################
# Start Program
########################################################
my $package = "PPC";

# -I
if ( defined $opt{interfaces} ) {
    PPC::interfaces();
    exit 0;
}

if ( !defined $opt{header} ) {
    $opt{header} = 1;
}
if ( $opt{header} ) {
    print "Welcome to Perl Packet Crafter (PPC)\nVersion:  $PPC::VERSION\n\n";
}

my $errmode = PPC::config( 'errmode' => 'continue' );

# conf_file
my $config_file = PPC::config('conf_file');

# 1 command line, don't check -e, file() will fail appropriately
if ( defined $opt{conf} ) {
    if ( defined PPC::file( $opt{conf} ) ) {
        PPC::config( 'conf_file' => $opt{conf} );
    } else {
        PPC::config( 'conf_file' => $opt{conf} . " [not found]" );
    }
} else {
    if ( defined( my $ret = config_where( $config_file, $Bin ) ) ) {
        PPC::file($ret);
        PPC::config( 'conf_file' => $ret );
    } else {
        PPC::config( 'conf_file' => $config_file . " [not found]" );
    }
}

# -i
if ( defined $opt{interface} ) {
    my $i = PPC::interface( $opt{interface} );
}
if ( $opt{header} ) {
    PPC::interface();
}

no strict 'vars';

# files (exit)
if (@ARGV) {
    for my $arg (@ARGV) {
        PPC::file($arg);
        if ( defined $opt{command} ) {
            _command( $opt{command} );
        }
    }
    exit $!;
}

# -c (exit)
if ( defined $opt{command} ) {
    _command( $opt{command} );
    exit $!;
}

sub _command {
    my ($cmd) = @_;
    eval( "package $package;\n" . $cmd );
    if ($@) {
        warn $@;
    }
}

use strict 'vars';

# -s
$opt{sess_handle} = undef;
if ( defined $opt{sess_file} ) {
    session( $opt{sess_file} );
}

PPC::config( 'errmode' => $errmode );

my $ppc = PerlApp::Shell->new(
    homedir  => $Bin,
    prompt   => lc($package) . '> ',
    package  => $package,
#   lexical  => 1,
    skipvars => [
        qw($Bin $PERMUTE $REQUIRE_ORDER $RETURN_IN_ORDER $PPC_GLOBALS
          %Interface:: %Layer:: %Macro:: %Packet:: %Plugin::)
    ]
);
$ppc->run();

__END__

########################################################
# Start POD
########################################################

=head1 NAME

PPC - Perl Packet Crafter

=head1 SYNOPSIS

 ppc [OPTIONS] [file [...]]

=head1 DESCRIPTION

A packet crafting engine in Perl using Net::Frame modules and Net::Pcap.

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

=head1 OPTIONS

 file         Optional file(s) to execute and exit.

 -c command   Command to execute and exit.  If both command and file(s)  
 --command    are provided, execute command after running (each) file.

 -f conf_file Configuration file.
 --config     DEFAULT:  (or not specified) ppc.conf

 -H           Print header information on start (default).
 --header     Use '--noheader' to omit.

 -I           List available interfaces and exit.
 --Interfaces

 -i ifName    Friendly name of the interface to use.
 --interface

 --help       Print Options and Arguments.
 --man        Print complete man page.
 --versions   Print Modules, Perl, OS, Program info.

=head1 COMMANDS

Once in the B<PPC> shell, additional commands are available.  See B<PPC> 
and B<PerlApp::Shell> for details.

At startup, B<PPC> will look for a configuration file called 'ppc.conf'.  
B<PPC> will search the following, first match wins:

=over 4

=item 1

Any file specified with '-f conf_file' on the command line

=item 2

'ppc.conf' in the current working directory where the script is invoked

=item 3

'ppc.conf' in user's home directory (e.g., $HOME, %USERPROFILE%)

=item 4

'ppc.conf' in the installation directory

=back
 
If no configuration file is found, it will start without one.

Configuration files can contain any valid Perl commands as well as commands 
available in the B<PPC> shell.  Comment lines starting with "#" are ignored 
as well as blank lines.

=head1 EXAMPLES

 C:\> ppc.pl -i "Local Area Connection"
 Welcome to Perl Packet Crafter (PPC)
 Version:  1.02
 
 Local Area Connection

 ppc>

The following "Send ..." examples all send an IPv4 ICMPv4 echo request to
www.google.com.

=head2 Send Manual

 ppc> use Net::Frame::Layer::ICMPv4 qw(:consts);
 ppc> use Net::Frame::Layer::ICMPv4::Echo;
 ppc> $ether  = Net::Frame::Layer::ETH->new(src=>MAC_SRC,dst=>MAC_GW);
 ppc> $ipv4   = Net::Frame::Layer::IPv4->new(src=>IPv4_SRC,dst=>'www.google.com',protocol=>NF_IPv4_PROTOCOL_ICMPv4);
 ppc> $icmpv4 = Net::Frame::Layer::ICMPv4->new();
 ppc> $echo   = Net::Frame::Layer::ICMPv4::Echo->new(payload => 'echo');
 ppc> $packet = packet $ether,$ipv4,$icmpv4,$echo;
 ppc> sendp $packet;

=head2 Send with File

 ppc> scripts 'IPv4-ICMPv4-EchoRequest.ppcs';
 What host to ping? www.google.com

 [ ... output omitted ... ]

 ppc> sendp $packet;

=head2 Send with Macros

 ppc> sendp(packet(ETHER,IP(dst=>'www.google.com',protocol=>NF_IPv4_PROTOCOL_ICMPv4),ICMPv4,ECHOv4(payload=>'echo')));

=head2 Send and Receive Multiple From Template

Use the ICMP Echo Request file to create a packet.  Clone it multiple times 
and edit the sequence number in each packet.  Send and receive.

 ppc> scripts 'IPv4-ICMPv4-EchoRequest.ppcs';
 What host to ping? www.google.com

 [ ... output omitted ... ]

 ppc> use Storable 'dclone';
 ppc> for (0..9) { 
 More? push @p, dclone($packet);
 More? [$p[$_]->layers]->[3]->sequenceNumber(100+$_);
 More? }
 ppc> $r = srp \@p;

=head1 SEE ALSO

L<PerlApp::Shell>, L<PPC>, L<PPC::Interface>, L<PPC::Layer>, 
L<PPC::Macro>, L<PPC::Packet>, L<PPC::Packet::SRP>, L<PPC::Plugin>

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
