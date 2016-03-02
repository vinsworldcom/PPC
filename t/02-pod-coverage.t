eval "use Test::Pod::Coverage tests => 47";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod::Coverage required for testing");
}
else {
   pod_coverage_ok("PPC");
   pod_coverage_ok("PPC::Interface");
   pod_coverage_ok("PPC::Interface::Example");
   if ($^O eq 'linux') {
       pod_coverage_ok("PPC::Interface::Linux");
   } elsif ($^O eq 'MSWin32') {
       pod_coverage_ok("PPC::Interface::Win32");
   } else {
       ok(1);
   }
   pod_coverage_ok("PPC::Layer");
   pod_coverage_ok("PPC::Layer::GRE");
   pod_coverage_ok("PPC::Layer::HSRP");
   pod_coverage_ok("PPC::Layer::IGMP");
   pod_coverage_ok("PPC::Layer::LLC");
   pod_coverage_ok("PPC::Layer::NTP");
   pod_coverage_ok("PPC::Layer::PIM");
   pod_coverage_ok("PPC::Layer::PPP");
   pod_coverage_ok("PPC::Layer::SNMPGet");
   pod_coverage_ok("PPC::Layer::SNMPGetBulk");
   pod_coverage_ok("PPC::Layer::SNMPGetNext");
   pod_coverage_ok("PPC::Layer::SNMPInform");
   pod_coverage_ok("PPC::Layer::SNMPReport");
   pod_coverage_ok("PPC::Layer::SNMPResponse");
   pod_coverage_ok("PPC::Layer::SNMPSet");
   pod_coverage_ok("PPC::Layer::SNMPTrap");
   pod_coverage_ok("PPC::Layer::SNMPv2Trap");
   pod_coverage_ok("PPC::Layer::STP");
   pod_coverage_ok("PPC::Layer::Syslog");
   pod_coverage_ok("PPC::Layer::VLAN");
   pod_coverage_ok("PPC::Layer::VRRP");
   pod_coverage_ok("PPC::Macro");
   pod_coverage_ok("PPC::Packet");
   pod_coverage_ok("PPC::Packet::SRP");
   pod_coverage_ok("PPC::Plugin");
   pod_coverage_ok("PPC::Plugin::DSCP");
   pod_coverage_ok("PPC::Plugin::Gnuplot");
   pod_coverage_ok("PPC::Plugin::ICMPv4TypeCode");
   pod_coverage_ok("PPC::Plugin::ICMPv6TypeCode");
   pod_coverage_ok("PPC::Plugin::IPv4Options");
   pod_coverage_ok("PPC::Plugin::IPv6Options");
   pod_coverage_ok("PPC::Plugin::MulticastMac");
   pod_coverage_ok("PPC::Plugin::MyScripts");
   pod_coverage_ok("PPC::Plugin::P0f");
   pod_coverage_ok("PPC::Plugin::Ping");
   pod_coverage_ok("PPC::Plugin::TCPConnect");
   pod_coverage_ok("PPC::Plugin::TCPFlags");
   pod_coverage_ok("PPC::Plugin::TCPOptions");
   pod_coverage_ok("PPC::Plugin::TCPScan");
   pod_coverage_ok("PPC::Plugin::TextTable");
   pod_coverage_ok("PPC::Plugin::Trace");
   pod_coverage_ok("Net::Frame::Layer::ICMPv6::Option");
   pod_coverage_ok("Net::Frame::Layer::PIM");
}
