# Perl Packet Crafter (PPC)

## Description

A packet crafting capability in Perl using [Net\::Frame](https://metacpan.org/pod/Net::Frame)
modules and [Net\::Pcap](https://metacpan.org/pod/Net::Pcap).  Provides a 
shell and commands for creating, sending an receiving packets.  Can also 
run provided scripts from shell or command line.  Supports expansion 
through using plug-in modules.

## Requires

+ [Net\::Pcap](https://metacpan.org/pod/Net::Pcap)
+ [Net\::Frame](https://metacpan.org/pod/Net::Frame)
+ [Net\::Frame\::Simple](https://metacpan.org/pod/Net::Frame::Simple)

... AND some network interface module:

+ Windows => [Win32\::Net\::Info](https://metacpan.org/pod/Win32::Net::Info)
+ Linux   => [IO\::Interface\::Simple](https://metacpan.org/pod/IO::Interface::Simple)
+ other   => (see PPC\::Interface\::Example)

Recommended:

+ [Net\::Frame\::Layer\::8021Q](https://metacpan.org/pod/Net::Frame::Layer::8021Q)
+ [Net\::Frame\::Layer\::ICMPv4](https://metacpan.org/pod/Net::Frame::Layer::ICMPv4)
+ [Net\::Frame\::Layer\::ICMPv6](https://metacpan.org/pod/Net::Frame::Layer::ICMPv6)
+ [Net\::Frame\::Layer\::ICMPv6\::MLD](https://metacpan.org/pod/Net::Frame::Layer::ICMPv6::MLD)
+ [Net\::Frame\::Layer\::IPv6](https://metacpan.org/pod/Net::Frame::Layer::IPv6)
+ [Net\::Frame\::Layer\::LLC](https://metacpan.org/pod/Net::Frame::Layer::LLC)
+ [Net\::Frame\::Layer\::STP](https://metacpan.org/pod/Net::Frame::Layer::STP)

Additional:

+ [Net\::Frame\::Layer\::DNS](https://metacpan.org/pod/Net::Frame::Layer::DNS)
+ [Net\::Frame\::Layer\::HSRP](https://metacpan.org/pod/Net::Frame::Layer::HSRP)
+ [Net\::Frame\::Layer\::IGMP](https://metacpan.org/pod/Net::Frame::Layer::IGMP)
+ [Net\::Frame\::Layer\::MPLS](https://metacpan.org/pod/Net::Frame::Layer::MPLS)
+ [Net\::Frame\::Layer\::NTP](https://metacpan.org/pod/Net::Frame::Layer::NTP)
+ [Net\::Frame\::Layer\::OSPF](https://metacpan.org/pod/Net::Frame::Layer::OSPF)
+ [Net\::Frame\::Layer\::RIP](https://metacpan.org/pod/Net::Frame::Layer::RIP)
+ [Net\::Frame\::Layer\::RIPng](https://metacpan.org/pod/Net::Frame::Layer::RIPng)
+ [Net\::Frame\::Layer\::SNMP](https://metacpan.org/pod/Net::Frame::Layer::SNMP)
+ [Net\::Frame\::Layer\::Syslog](https://metacpan.org/pod/Net::Frame::Layer::Syslog)

Plugins:

+ [Geo\::IP](https://metacpan.org/pod/Geo::IP)

Dependencies of all above modules should install automatically via CPAN.

## Installation

This program can be run as-is with no installation providing the above 
dependencies are met simply by putting all contents as-is in a directory 
and running the bin/ppc.pl script from anywhere (given the full path to 
the script if it is not in your path).  Alternatively, you can do a 
proper Perl installation:

```
    perl Makefile.PL
    make
    make test
    make install
```

This will copy the appropriate files to your appropriate Perl installation 
locations and automatically install all dependencies.

## Testing

The `make test` command above can be modified by setting environment 
variables:

| | |
|-|-|
| PPC_DEVELOPER = 1    | Additional developer tests |
| PPC_INTERFACE = <if> | Set to the interface to test |
| PPC_IPv6 = 1         | Perform additional IPv6 tests (must have IPv6 address) |

## Caveats

The Makefile.PL specifies 5.14 for Perl since this is where Socket started 
to support IPv6.  This may work on older Perl's so feel free to change the 
Makefile.PL appropriately, but there are no guarantees.

Net\::Pcap installation on Windows is buggy.  A CPAN installation will 
probably fail.  You'll need to download the package, patch and build by 
hand.  See http://www.perlmonks.org/?node_id=1012521 for details.

For terminal history using up/down arrows on *nix, you will need to install 
[Term\::ReadLine\::Gnu](https://metacpan.org/pod/Term::ReadLine\::Gnu).  
This isn't necessary for basic operation, but does make using the shell 
a bit easier with command recall.

## Operation

This should work "out of the box" on Win32 provided the above modules' 
requirements are met.  This is essentially why I developed this in the 
first place - packet crafting on Windows after XP discontinued raw socket 
support.  I developed, tested and currently run this on Windows (from XP to 
10, both 32- and 64-bit flavors with [Strawberry Perl](http://strawberryperl.com/) 
5.16 and up in both 32 and 64-bit flavors).

For *nix installations, this *may* work for IPv4 depending on the [Net\::Pcap](https://metacpan.org/pod/Net::Pcap)
support for sending / receiving packets (i.e., [Net\::Pcap](https://metacpan.org/pod/Net::Pcap) 
abstracts the interface to the Pcap libraries - how different is WinPcap from libpcap?).  
I've tested on Ubuntu 14.04 with [Net\::Pcap](https://metacpan.org/pod/Net::Pcap) 
0.17 and libpcap 1.7.4.  It won't work for IPv6 since the 
PPC\::Interface\::Linux module is based on 
[IO\::Interface\::Simple](https://metacpan.org/pod/IO::Interface::Simple) 
which doesn't seem to have IPv6 support.

For other architectures, you will need to visit the lib/PPC/Interface 
directory and examine the Example.pm file to create a mapping for the 
actual interface module you use.  This may be, for example:

+ [IO\::Interface](https://metacpan.org/pod/IO::Interface)[(\::Simple)](https://metacpan.org/pod/IO::Interface::Simple)
+ [Net\::Interface](https://metacpan.org/pod/Net::Interface)
+ [Net\::Frame\::Device](https://metacpan.org/pod/Net::Frame::Device) (which requires [Net\::Libdnet](https://metacpan.org/pod/Net::Libdnet))

## Net directory

The 'Net' directory contains updates and patches to the 
[Net\::Frame](https://metacpan.org/pod/Net::Frame) 
and submodules suite.  Some of these patches have been submitted to the 
respective module authors but were rejected.  Still, they prove useful in 
the operation of this program.  They will override the installed versions 
of these modules.  To use the installed versions of the modules, simply 
delete the files from this subdirectory.


### Net/IPv4Addr.pm

Adds an object-oriented interface and accessors similar to 
[Net\::IPv6Addr](https://metacpan.org/pod/Net::IPv6Addr) 
to the [Net\::IPv4Addr](https://metacpan.org/pod/Net::IPv4Addr) module while 
maintaining existing functionality.


### Net/Frame/Layer/PIM.pm

An incomplete implementation of the Protocol Independent Multicast (PIM) layer.  
If this modules is completed, it will cease to exist here and instead be found 
on CPAN.


### Net/Frame/Layer/ICMPv6/Option.pm

Bug fix for option length calculation.  Differences can be found in 
Option.diff.
