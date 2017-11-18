#!/usr/bin/perl
########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case pass_through);
use Pod::Usage;

my %opt;
my ( $opt_help, $opt_man, $opt_versions );

GetOptions(
    'interface=s' => \$opt{interface},
    'help!'       => \$opt_help,
    'man!'        => \$opt_man,
    'versions!'   => \$opt_versions
) or pod2usage( -verbose => 0 );

pod2usage( -verbose => 1 ) if defined $opt_help;
pod2usage( -verbose => 2 ) if defined $opt_man;

my @interface;
if ( defined $opt{interface} ) {
    push @interface, '-e';
    push @interface, "interface \'$opt{interface}\'";
}

if ( defined $opt_versions ) {
    undef @interface; undef @ARGV;
    push @interface, '-e';
    push @interface, 'print $PPC::VERSION';
    push @interface, '-E';
}

use FindBin qw( $Bin );
system (
    "$Bin/plsh.pl",
    '-I', "$Bin/../lib",
    '-P', 'PPC',
    '-p', 'ppc> ',
    @interface,
    @ARGV
);

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

 -i ifName    Friendly name of the interface to use.
 --interface

For additional options, see L<App::PerlShell> and B<plsh>.

=head1 COMMANDS

Once in the B<PPC> shell, additional commands are available.  See B<PPC> 
and B<App::PerlShell> for details.

=head1 EXAMPLES

 C:\> ppc.pl -i "Local Area Connection"
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

=head2 Send Directly from Command Line

 C:\> cd lib\PPC
 C:\> ppc.pl -i "Local Area Connection" -e "file 'scripts/IPv4-ICMPv4-EchoRequest.ppcs', argv => '-i www.google.com -s'" -E

=head1 SEE ALSO

L<App::PerlShell>, L<PPC>, L<PPC::Interface>, L<PPC::Layer>, 
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
