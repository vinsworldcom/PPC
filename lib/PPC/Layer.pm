package PPC::Layer;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

use Net::Frame::Layer::ETH qw( :consts );
use Net::Frame::Layer::ARP qw( :consts );
use Net::Frame::Layer::IPv4 qw( :consts );
use Net::Frame::Layer::TCP qw( :consts );
use Net::Frame::Layer::UDP qw( :consts );
my $minver_IPv6 = 1.07;
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
my $minver_ICMPv6 = 1.10;
my $HAVE_ICMPv6   = 0;
eval "use Net::Frame::Layer::ICMPv6 $minver_ICMPv6 qw( :consts )";
if ( !$@ ) {
    eval "use Net::Frame::Layer::ICMPv6::Echo";
    $HAVE_ICMPv6 = 1;
}

use Exporter;

our @EXPORT = qw(
  ETH
  ETHER
  ETH4
  ETHER4
  ETH6
  ETHER6
  ARP
  IP
  IPv4
  IPv6
  ICMP
  ICMPv4
  ECHO
  ECHOv4
  ICMPv6
  ECHOv6
  TCP
  UDP
);

our @ISA = qw ( PPC Exporter );

########################################################

sub ETH {
      return ETHER(@_);
}

sub ETHER {
    my %params;

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) {
            PPC::_help( __PACKAGE__,
                "COMMANDS/ETHER - create layer 2 Ethernet frame",
                "Net::Frame::Layer::ETH"
            );
        }
        $params{type} = $arg;
    } else {
        my %args = @_;
        for ( keys(%args) ) {
            $params{$_} = $args{$_};
        }
    }

    if ( !defined( $params{src} ) and PPC::Macro::MAC_SRC() ) {
        $params{src} = PPC::Macro::MAC_SRC();
    }
    if ( !defined $params{dst} ) {
        if ( defined $params{type} ) {
            if ( $params{type} =~ /^\d{1,5}$/ ) {
                  if ( $params{type} == NF_ETH_TYPE_ARP ) {
                      $params{dst} = 'ff:ff:ff:ff:ff:ff';
                  } elsif ( ( $params{type} == NF_ETH_TYPE_IPv6 )
                      and PPC::Macro::MAC6_GW() ) {
                      $params{dst} = PPC::Macro::MAC6_GW();
                  } elsif ( PPC::Macro::MAC_GW() ) {
                      $params{dst} = PPC::Macro::MAC_GW();
                  }
            } else {
                  _error( "type", $params{type} );
            }
        } elsif ( PPC::Macro::MAC_GW() ) {
            $params{dst} = PPC::Macro::MAC_GW();
        }
    }

    my $p = _layer( "ETH", %params );
    if ( !defined wantarray ) {
          print $p->print . "\n";
    }
    return $p;
}

sub ETH4 {
      return ETHER4(@_);
}

sub ETHER4 {
      my %params;
      $params{type} = NF_ETH_TYPE_IPv4;

      if ( @_ == 1 ) {
          my ($arg) = @_;
          if ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) {
              PPC::_help( __PACKAGE__,
                  "COMMANDS/ETHER4 - create layer 2 Ethernet frame for IPv4",
                  "Net::Frame::Layer::ETH"
              );
          }
          $params{dst} = $arg;
      } else {
          my %args = @_;
          for ( keys(%args) ) {
              $params{$_} = $args{$_};
          }
      }

      if ( !defined( $params{src} ) and PPC::Macro::MAC_SRC() ) {
          $params{src} = PPC::Macro::MAC_SRC();
      }
      if ( !defined $params{dst} ) {
          if ( PPC::Macro::MAC_GW() ) {
              $params{dst} = PPC::Macro::MAC_GW();
          }
      }

      return ETHER(%params);
}

sub ETH6 {
      return ETHER6(@_);
}

sub ETHER6 {
      my %params;
      $params{type} = NF_ETH_TYPE_IPv6;

      if ( @_ == 1 ) {
          my ($arg) = @_;
          if ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) {
              PPC::_help( __PACKAGE__,
                  "COMMANDS/ETHER6 - create layer 2 Ethernet frame for IPv6",
                  "Net::Frame::Layer::ETH"
              );
          }
          $params{dst} = $arg;
      } else {
          my %args = @_;
          for ( keys(%args) ) {
              $params{$_} = $args{$_};
          }
      }

      if ( !defined( $params{src} ) and PPC::Macro::MAC_SRC() ) {
          $params{src} = PPC::Macro::MAC_SRC();
      }
      if ( !defined $params{dst} ) {
          if ( PPC::Macro::MAC6_GW() ) {
              $params{dst} = PPC::Macro::MAC6_GW();
          } elsif ( PPC::Macro::MAC_GW() ) {
              $params{dst} = PPC::Macro::MAC_GW();
          }
      }

      return ETHER(%params);
}

sub ARP {
      my %params;

      if ( @_ == 1 ) {
          my ($arg) = @_;
          if ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) {
              PPC::_help( __PACKAGE__,
                  "COMMANDS/ARP - create ARP request",
                  "Net::Frame::Layer::ARP"
              );
          }
          $params{dstIp} = $arg;
      } else {
          my %args = @_;
          for ( keys(%args) ) {
              $params{$_} = $args{$_};
          }
      }

      if ( !defined( $params{src} ) and PPC::Macro::MAC_SRC() ) {
          $params{src} = PPC::Macro::MAC_SRC();
      }
      if ( !defined( $params{srcIp} ) and PPC::Macro::IPv4_SRC() ) {
          $params{srcIp} = PPC::Macro::IPv4_SRC();
      }

      my $p = _layer( "ARP", %params );
      if ( !defined wantarray ) {
          print $p->print . "\n";
      }
      return $p;
}

sub IP {
      return IPv4(@_);
}

sub IPv4 {
      my %params;

      if ( @_ == 1 ) {
          my ($arg) = @_;
          if ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) {
              PPC::_help( __PACKAGE__,
                  "COMMANDS/IPv4 - create layer 3 IPv4 header",
                  "Net::Frame::Layer::IPv4"
              );
          }
          $params{dst} = $arg;
      } else {
          my %args = @_;
          for ( keys(%args) ) {
              $params{$_} = $args{$_};
          }
      }

      if ( !defined( $params{src} ) and PPC::Macro::IPv4_SRC() ) {
          $params{src} = PPC::Macro::IPv4_SRC();
      }

      my $p = _layer( "IPv4", %params );
      if ( !defined wantarray ) {
          print $p->print . "\n";
      }
      return $p;
}

sub IPv6 {
      my %params;

      if ( !$HAVE_IPv6 ) {
          _err_not_installed( "IPv6", $minver_IPv6 );
      }

      if ( @_ == 1 ) {
          my ($arg) = @_;
          if ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) {
              PPC::_help( __PACKAGE__,
                  "COMMANDS/IPv6 - create layer 3 IPv6 header",
                  "Net::Frame::Layer::IPv6"
              );
          }
          $params{dst} = $arg;
      } else {
          my %args = @_;
          for ( keys(%args) ) {
              $params{$_} = $args{$_};
          }
      }

      if ( !defined( $params{src} ) and PPC::Macro::IPv6_SRC() ) {
          $params{src} = PPC::Macro::IPv6_SRC();
      }

      my $p = _layer( "IPv6", %params );
      if ( !defined wantarray ) {
          print $p->print . "\n";
      }
      return $p;
}

sub ICMP {
      return ICMPv4(@_);
}

sub ICMPv4 {
      my %params;

      if ( !$HAVE_ICMPv4 ) {
          _err_not_installed( "ICMPv4", $minver_ICMPv4 );
      }

      if ( @_ == 1 ) {
          my ($arg) = @_;
          if ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) {
              PPC::_help( __PACKAGE__,
                  "COMMANDS/ICMPv4 - create ICMPv4 header",
                  "Net::Frame::Layer::ICMPv4"
              );
          }
          $params{type} = $arg;
      } else {
          my %args = @_;
          for ( keys(%args) ) {
              $params{$_} = $args{$_};
          }
      }

      if ( defined( $params{type} ) and ( $params{type} !~ /^\d{1,3}$/ ) ) {
          _error( "type", $params{type} );
      }

      my $p = _layer( "ICMPv4", %params );
      if ( !defined wantarray ) {
          print $p->print . "\n";
      }
      return $p;
}

sub ECHO {
      return ECHOv4(@_);
}

sub ECHOv4 {
      my %params;

      if ( !$HAVE_ICMPv4 ) {
          _err_not_installed( "ICMPv4", $minver_ICMPv4 );
      }

      if ( @_ == 1 ) {
          my ($arg) = @_;
          if ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) {
              PPC::_help( __PACKAGE__,
                  "COMMANDS/ECHOv4 - create ICMPv4 Echo header",
                  "Net::Frame::Layer::ICMPv4::Echo"
              );
          }
          $params{payload} = $arg;
      } else {
          my %args = @_;
          for ( keys(%args) ) {
              $params{$_} = $args{$_};
          }
      }

      my $p = _layer( "ICMPv4::Echo", %params );
      if ( !defined wantarray ) {
          print $p->print . "\n";
      }
      return $p;
}

sub ICMPv6 {
      my %params;

      if ( !$HAVE_ICMPv6 ) {
          _err_not_installed( "ICMPv6", $minver_ICMPv6 );
      }

      if ( @_ == 1 ) {
          my ($arg) = @_;
          if ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) {
              PPC::_help( __PACKAGE__,
                  "COMMANDS/ICMPv6 - create ICMPv6 header",
                  "Net::Frame::Layer::ICMPv6"
              );
          }
          $params{type} = $arg;
      } else {
          my %args = @_;
          for ( keys(%args) ) {
              $params{$_} = $args{$_};
          }
      }

      if ( defined( $params{type} ) and ( $params{type} !~ /^\d{1,3}$/ ) ) {
          _error( "type", $params{type} );
      }

      my $p = _layer( "ICMPv6", %params );
      if ( !defined wantarray ) {
          print $p->print . "\n";
      }
      return $p;
}

sub ECHOv6 {
      my %params;

      if ( !$HAVE_ICMPv6 ) {
          _err_not_installed( "ICMPv6", $minver_ICMPv6 );
      }

      if ( @_ == 1 ) {
          my ($arg) = @_;
          if ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) {
              PPC::_help( __PACKAGE__,
                  "COMMANDS/ECHOv6 - create ICMPv6 Echo header",
                  "Net::Frame::Layer::ICMPv6::Echo"
              );
          }
          $params{payload} = $arg;
      } else {
          my %args = @_;
          for ( keys(%args) ) {
              $params{$_} = $args{$_};
          }
      }

      my $p = _layer( "ICMPv6::Echo", %params );
      if ( !defined wantarray ) {
          print $p->print . "\n";
      }
      return $p;
}

sub TCP {
      my %params;

      if ( @_ == 1 ) {
          my ($arg) = @_;
          if ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) {
              PPC::_help( __PACKAGE__,
                  "COMMANDS/TCP - create layer 4 TCP header",
                  "Net::Frame::Layer::TCP"
              );
          }
          $params{dst} = $arg;
      } else {
          my %args = @_;
          for ( keys(%args) ) {
              $params{$_} = $args{$_};
          }
      }

      if ( defined( $params{dst} ) and ( $params{dst} !~ /^\d{1,5}$/ ) ) {
          _error( "port", $params{dst} );
      }

      my $p = _layer( "TCP", %params );
      if ( !defined wantarray ) {
          print $p->print . "\n";
      }
      return $p;
}

sub UDP {
      my %params;

      if ( @_ == 1 ) {
          my ($arg) = @_;
          if ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) {
              PPC::_help( __PACKAGE__,
                  "COMMANDS/UDP - create layer 4 UDP header",
                  "Net::Frame::Layer::UDP"
              );
          }
          $params{dst} = $arg;
      } else {
          my %args = @_;
          for ( keys(%args) ) {
              $params{$_} = $args{$_};
          }
      }

      if ( defined( $params{dst} ) and ( $params{dst} !~ /^\d{1,5}$/ ) ) {
          _error( 'port', $params{dst} );
      }

      my $p = _layer( "UDP", %params );
      if ( !defined wantarray ) {
          print $p->print . "\n";
      }
      return $p;
}

sub _error {
    my ( $arg1, $arg2 ) = @_;
    PPC::_error( "Not a valid $arg1 - `$arg2'" );
}

sub _err_not_installed {
      my ( $mod, $ver ) = @_;
      PPC::_error(
          "$mod requires Net::Frame::Layer::$mod  ($ver)");
}

sub _layer {
      my $l = shift;
      my $s = 'new';
      if ( $l =~ /\->/ ) {
          ( $l, $s ) = split /\->/, $l;
      }
      no strict 'refs';
      return ( 'Net::Frame::Layer::' . $l )->$s(@_);
}

1;

__END__

########################################################
# Start POD
########################################################

=head1 NAME

PPC::Layer - Perl Packet Crafter Layer

=head1 SYNOPSIS

 use PPC::Layer;

=head1 DESCRIPTION

Layers provides shortcuts for creating B<Net::Frame::Layer> objects in the 
B<PPC> shell.

Additional custom layers can be created and stored in the PPC/Layer 
directory.  They will be C<use> by default if C<use PPC;> is called.  See 
files in the PPC/Layer directory for examples.

=head1 COMMANDS

=head2 ETHER - create layer 2 Ethernet frame

 [$ether =] ETHER [(Net::Frame::Layer::ETH options)]

Creates B<$ether> variable as Ethernet frame.  Uses options from
Net::Frame::Layer::ETH.  Provides autoconfiguration if C<interfaces>
command has been run:

  Option       Default Value
  ------       -------------
  dst          MAC_GW if defined
               'ff:ff:ff:ff:ff:ff' if type=>NF_ETH_TYPE_ARP
  src          MAC_SRC if defined

Single option indicates B<type>.

Alias:

=over 4

=item B<ETH>

=back

=head2 ETHER4 - create layer 2 Ethernet frame for IPv4

 [$ether4 =] ETHER4 [(Net::Frame::Layer::ETH options)]

Creates B<$ether4> variable as Ethernet frame.  Uses options from
Net::Frame::Layer::ETH.  Provides autoconfiguration if C<interfaces>
command has been run:

  Option       Default Value
  ------       -------------
  dst          MAC_GW if defined
  src          MAC_SRC if defined
  type         NF_ETH_TYPE_IPv4

Single option indicates B<dst>.

Alias:

=over 4

=item B<ETH4>

=back

=head2 ETHER6 - create layer 2 Ethernet frame for IPv6

 [$ether6 =] ETHER6 [(Net::Frame::Layer::ETH options)]

Creates B<$ether6> variable as Ethernet frame.  Uses options from
Net::Frame::Layer::ETH.  Provides autoconfiguration if C<interfaces>
command has been run:

  Option       Default Value
  ------       -------------
  dst          MAC6_GW if defined
  src          MAC_SRC if defined
  type         NF_ETH_TYPE_IPv6

Single option indicates B<dst>.

Alias:

=over 4

=item B<ETH6>

=back

=head2 ARP - create ARP request

 [$arp =] ARP [(Net::Frame::Layer::ARP options)]

Creates B<$arp> variable as ARP.  Uses options from
Net::Frame::Layer::ARP.  Provides autoconfiguration if C<interfaces>
command has been run:

  Option       Default Value
  ------       -------------
  src          MAC_SRC if defined
  srcIp        IPv4_SRC if defined

Single option indicates B<dstIP>.

=head2 IPv4 - create layer 3 IPv4 header

 [$ipv4 =] IPv4 [(Net::Frame::Layer::IPv4 options)]

Creates B<$ipv4> variable as IPv4 layer.  Uses options from
Net::Frame::Layer::IPv4.  Provides autoconfiguration if C<interfaces>
command has been run:

  Option       Default Value
  ------       -------------
  src          $ipv4_src if defined

Single option indicates B<dst> IPv4 address.

Alias:

=over 4

=item B<IP>

=back

=head2 IPv6 - create layer 3 IPv6 header

 [$ipv6 =] IPv6 [(Net::Frame::Layer::IPv6 options)]

Creates B<$ipv6> variable as IPv6 layer.  Uses options from
Net::Frame::Layer::IPv6.  Provides autoconfiguration if C<interfaces>
command has been run:

  Option       Default Value
  ------       -------------
  src          $ipv6_src if defined

Single option indicates B<dst> IPv6 address.

NOTE:  Requires Net::Frame::Layer::IPv6

=head2 ICMPv4 - create ICMPv4 header

 [$icmpv4 =] ICMPv4 [(Net::Frame::Layer::ICMPv4 options)]

Creates B<$icmpv4> variable as ICMPv4 layer.  Uses options from
Net::Frame::Layer::ICMPv4.

Single option indicates B<type>.

NOTE:  Requires Net::Frame::Layer::ICMPv4

Alias:

=over 4

=item B<ICMP>

=back

=head2 ECHOv4 - create ICMPv4 Echo header

 [$echov4 =] ECHOv4 [(Net::Frame::Layer::ICMPv4::Echo options)]

Creates B<$echov4> variable as ICMPv4::Echo layer.  Uses options from
Net::Frame::Layer::ICMPv4::Echo.

Single option indicates B<payload>.

NOTE:  Requires Net::Frame::Layer::ICMPv4

Alias:

=over 4

=item B<ECHO>

=back

=head2 ICMPv6 - create ICMPv6 header

 [$icmpv6 =] ICMPv6 [(Net::Frame::Layer::ICMPv6 options)]

Creates B<$icmpv6> variable as ICMPv6 layer.  Uses options from
Net::Frame::Layer::ICMPv6.

Single option indicates B<type>.

NOTE:  Requires Net::Frame::Layer::ICMPv6

=head2 ECHOv6 - create ICMPv6 Echo header

 [$echov6 =] ECHOv6 [(Net::Frame::Layer::ICMPv6::Echo options)]

Creates B<$echov6> variable as ICMPv6::Echo layer.  Uses options from
Net::Frame::Layer::ICMPv6::Echo.

Single option indicates B<payload>.

NOTE:  Requires Net::Frame::Layer::ICMPv6

=head2 TCP - create layer 4 TCP header

 [$tcp =] TCP [(Net::Frame::Layer::TCP options)]

Creates B<$tcp> variable as TCP layer.  Uses options from
Net::Frame::Layer::TCP.

Single option indicates B<dst> port.

=head2 UDP - create layer 4 UDP header

 [$udp =] UDP [(Net::Frame::Layer::UDP options)]

Creates B<$udp> variable as UDP layer.  Uses options from
Net::Frame::Layer::UDP.

Single option indicates B<dst> port.

=head1 SEE ALSO

L<PPC>, L<PPC::Macro>, L<PPC::Interface>, 
L<Net::Frame::Layer>

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
