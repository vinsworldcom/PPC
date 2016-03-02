NAME:

Perl Packet Crafter (PPC)


DESCRIPTION:

A packet crafting capability in Perl using Net::Frame modules and Net::Pcap.  
Provides a shell and commands for creating, sending an receiving packets.  
Can also run provided scripts from shell or command line.  Supports 
expansion through using plug-in modules.


REQUIRES:

Net::Pcap
Net::Frame
Net::Frame::Simple

  Recommended:

  Net::Frame::Layer::8021Q
  Net::Frame::Layer::ICMPv4
  Net::Frame::Layer::ICMPv6
  Net::Frame::Layer::IPv6
  Net::Frame::Layer::LLC
  Net::Frame::Layer::STP

  Additional:

  Net::Frame::Layer::CDP
  Net::Frame::Layer::DNS
  Net::Frame::Layer::HSRP
  Net::Frame::Layer::IGMP
  Net::Frame::Layer::OSPF
  Net::Frame::Layer::RIP
  Net::Frame::Layer::RIPng
  Net::Frame::Layer::SNMP
  Net::Frame::Layer::Syslog

  Plugins:

  Chart::Gnuplot
  Text::Table
  Array::Transpose

Dependencies of all above modules should install automatically via CPAN.


INSTALLATION:

This program can be run as-is with no installation simply by putting all 
contents as-is in a directory and running the bin/ppc.pl script from 
anywhere (given the full path to the script if it is not in your path).  
Alternatively, you can do a proper Perl installation:

  perl Makefile.PL
  make
  make test
  make install

This will copy the appropriate files to your appropriate Perl installation 
locations.


CAVEATS:

The Makefile.PL specifies 5.14 for Perl since this is where Socket started 
to support IPv6.  This may work on older Perl's so feel free to change the 
Makefile.PL appropriately, but there are no guarantees.

Net::Pcap installation on Windows is buggy.  A CPAN installation will 
probably fail.  You'll need to download the package, patch and build by 
hand.  See http://www.perlmonks.org/?node_id=1012521 for details.

For terminal history using up/down arrows on *nix, you will need to install 
Term::ReadLine::Gnu.  This isn't necessary for basic operation, but does 
make using the shell a bit easier with command recall.

OPERATION:

This should work "out of the box" on Win32 provided the above modules' 
requirements are met.  This is essentially why I developed this in the 
first place - packet crafting on Windows after XP discontinued raw socket 
support.  I developed, tested and currently run this on Windows (from XP to 
7, both 32- and 64-bit flavors with Strawberry Perl 5.16 and later in both 
32- and 64-bit flavors).

For *nix installations, this *may* work for IPv4 depending on the Net::Pcap 
support for sending / receiving packets (i.e., Net::Pcap abstracts the 
interface to the Pcap libraries - how different is WinPcap from libpcap?).  
I've tested on Ubuntu 14.04 with Net::Pcap 0.17 and libpcap 1.7.4.  It 
won't work for IPv6 since the PPC::Interface::Linux module is based on 
IO::Interface::Simple which doesn't seem to have IPv6 support.

For other architectures, you will need to visit the lib/PPC/Interface 
directory and examine the Example.pm file to create a mapping for the 
actual interface module you use.  This may be, for example:
    IO::Interface(::Simple)
    Net::Interface
    Net::Frame::Device (Net::Libdnet)


NET DIRECTORY:

The 'Net' directory contains updates and patches to the Net::Frame and 
submodules suite.  Some of these patches have been submitted to the author 
but rejected.  Still, they prove useful in the operation of this program.  
They will override the installed versions of these modules.  To use the 
installed versions of the modules, simply delete the files from this 
subdirectory.


  Net/Frame/Layer/PIM.pm

An incomplete implementation of the Protocol Independent Multicast layer.  If 
this modules is completed, it will cease to exist here and instead be found 
on CPAN.


  Net/Frame/Layer/ICMPv6/Option.pm

Bug fix for option length calculation.  Differences can be found in 
Option.diff.
