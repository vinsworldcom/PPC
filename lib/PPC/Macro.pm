package PPC::Macro;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

use Exporter;

our @EXPORT = qw(
  MAC_SRC
  MAC_GW
  MAC6_GW
  IPv4_SRC
  IPv4_GW
  IPv6_SRC
  IPv6_SRC_LL
  IPv6_GW
  D2B
  D2H
  H2B
  H2D
  H2S
  S2H
);

our @ISA = qw ( PPC Exporter );

########################################################

sub MAC_SRC {
    my ($arg) = @_;

    if ( defined($arg) and ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) ) {
        PPC::_help( __PACKAGE__, "MACROS/MAC_SRC - source MAC address" );
    }

    if ( defined $arg ) {
        if ( $arg eq ":clear" ) {
            my $r = $PPC::PPC_GLOBALS->delete("MAC_SRC");
        } elsif ( $arg =~ /^[0-9a-f]{2}(?:\:[0-9a-f]{2}){5}$/i ) {
            ( $PPC::PPC_GLOBALS->exists("MAC_SRC") )
              ? $PPC::PPC_GLOBALS->config( "MAC_SRC" => lc($arg) )
              : $PPC::PPC_GLOBALS->add( "MAC_SRC" => lc($arg) );
        } else {
            _error( "argument", $arg );
        }
    }

    if ( $PPC::PPC_GLOBALS->exists("MAC_SRC") ) {
        if ( !defined wantarray ) {
            print $PPC::PPC_GLOBALS->config("MAC_SRC") . "\n";
        } else {
            return $PPC::PPC_GLOBALS->config("MAC_SRC");
        }
    } else {
        if (    defined( $PPC::PPC_GLOBALS->config("interface") )
            and defined( $PPC::PPC_GLOBALS->config("interface")->mac ) ) {
            if ( !defined wantarray ) {
                print $PPC::PPC_GLOBALS->config("interface")->mac . "\n";
            }
            return $PPC::PPC_GLOBALS->config("interface")->mac;
        }
        if ( !defined wantarray ) {
            print "Not defined\n";
        }
    }
    return undef;
}

sub MAC_GW {
    my ($arg) = @_;

    if ( defined($arg) and ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) ) {
        PPC::_help( __PACKAGE__,
            "MACROS/MAC_GW - IPv4 default gateway MAC address" );
    }

    if ( defined $arg ) {
        if ( $arg eq ":clear" ) {
            my $r = $PPC::PPC_GLOBALS->delete("MAC_GW");
        } elsif ( $arg =~ /^[0-9a-f]{2}(?:\:[0-9a-f]{2}){5}$/i ) {
            ( $PPC::PPC_GLOBALS->exists("MAC_GW") )
              ? $PPC::PPC_GLOBALS->config( "MAC_GW" => lc($arg) )
              : $PPC::PPC_GLOBALS->add( "MAC_GW" => lc($arg) );
        } else {
            _error( "argument", $arg );
        }
    }

    if ( $PPC::PPC_GLOBALS->exists("MAC_GW") ) {
        if ( !defined wantarray ) {
            print $PPC::PPC_GLOBALS->config("MAC_GW") . "\n";
        } else {
            return $PPC::PPC_GLOBALS->config("MAC_GW");
        }
    } else {
        if (defined( $PPC::PPC_GLOBALS->config("interface") )
            and defined(
                $PPC::PPC_GLOBALS->config("interface")->ipv4_gateway_mac
            )
          ) {
            if ( !defined wantarray ) {
                print $PPC::PPC_GLOBALS->config("interface")
                  ->ipv4_gateway_mac . "\n";
            }
            return $PPC::PPC_GLOBALS->config("interface")->ipv4_gateway_mac;
        }
        if ( !defined wantarray ) {
            print "Not defined\n";
        }
    }
    return undef;
}

sub MAC6_GW {
    my ($arg) = @_;

    if ( defined($arg) and ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) ) {
        PPC::_help( __PACKAGE__,
            "MACROS/MAC6_GW - IPv6 default gateway MAC address" );
    }

    if ( defined $arg ) {
        if ( $arg eq ":clear" ) {
            my $r = $PPC::PPC_GLOBALS->delete("MAC6_GW");
        } elsif ( $arg =~ /^[0-9a-f]{2}(?:\:[0-9a-f]{2}){5}$/i ) {
            ( $PPC::PPC_GLOBALS->exists("MAC6_GW") )
              ? $PPC::PPC_GLOBALS->config( "MAC6_GW" => lc($arg) )
              : $PPC::PPC_GLOBALS->add( "MAC6_GW" => lc($arg) );
        } else {
            _error( "argument", $arg );
        }
    }

    if ( $PPC::PPC_GLOBALS->exists("MAC6_GW") ) {
        if ( !defined wantarray ) {
            print $PPC::PPC_GLOBALS->config("MAC6_GW") . "\n";
        } else {
            return $PPC::PPC_GLOBALS->config("MAC6_GW");
        }
    } else {
        if (defined( $PPC::PPC_GLOBALS->config("interface") )
            and defined(
                $PPC::PPC_GLOBALS->config("interface")->ipv6_gateway_mac
            )
          ) {
            if ( !defined wantarray ) {
                print $PPC::PPC_GLOBALS->config("interface")
                  ->ipv6_gateway_mac . "\n";
            }
            return $PPC::PPC_GLOBALS->config("interface")->ipv6_gateway_mac;
        }
        if ( !defined wantarray ) {
            print "Not defined\n";
        }
    }
    return undef;
}

sub IPv4_SRC {
    my ($arg) = @_;

    if ( defined($arg) and ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) ) {
        PPC::_help( __PACKAGE__, "MACROS/IPv4_SRC - source IPv4 address" );
    }

    if ( defined $arg ) {
        if ( $arg eq ":clear" ) {
            my $r = $PPC::PPC_GLOBALS->delete("IPv4_SRC");
        } else {

            # WARN - Net::IPv4Addr bug sends undefined to Carp
            # DIE  - Net::IPv4Addr croaks on error, I prefer to handle nicely
            local $SIG{__WARN__} = sub { return; };
            local $SIG{__DIE__}  = sub { return; };
            my $addr;
            eval { $addr = Net::IPv4Addr::ipv4_parse($arg); };
            if ( defined $addr ) {
                ( $PPC::PPC_GLOBALS->exists("IPv4_SRC") )
                  ? $PPC::PPC_GLOBALS->config( "IPv4_SRC" => $arg )
                  : $PPC::PPC_GLOBALS->add( "IPv4_SRC" => $arg );
            } else {
                _error( "argument", $arg );
            }
        }
    }

    if ( $PPC::PPC_GLOBALS->exists("IPv4_SRC") ) {
        if ( !defined wantarray ) {
            print $PPC::PPC_GLOBALS->config("IPv4_SRC") . "\n";
        } else {
            return $PPC::PPC_GLOBALS->config("IPv4_SRC");
        }
    } else {
        if (    defined( $PPC::PPC_GLOBALS->config("interface") )
            and defined( $PPC::PPC_GLOBALS->config("interface")->ipv4 ) ) {
            if ( !defined wantarray ) {
                print $PPC::PPC_GLOBALS->config("interface")->ipv4 . "\n";
            }
            return $PPC::PPC_GLOBALS->config("interface")->ipv4;
        }
        if ( !defined wantarray ) {
            print "Not defined\n";
        }
    }
    return undef;
}

sub IPv4_GW {
    my ($arg) = @_;

    if ( defined($arg) and ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) ) {
        PPC::_help( __PACKAGE__, "MACROS/IPv4_GW - IPv4 default gateway" );
    }

    if ( defined $arg ) {
        if ( $arg eq ":clear" ) {
            my $r = $PPC::PPC_GLOBALS->delete("IPv4_GW");
        } else {

            # WARN - Net::IPv4Addr bug sends undefined to Carp
            # DIE  - Net::IPv4Addr croaks on error, I prefer to handle nicely
            local $SIG{__WARN__} = sub { return; };
            local $SIG{__DIE__}  = sub { return; };
            my $addr;
            eval { $addr = Net::IPv4Addr::ipv4_parse($arg); };
            if ( defined $addr ) {
                ( $PPC::PPC_GLOBALS->exists("IPv4_GW") )
                  ? $PPC::PPC_GLOBALS->config( "IPv4_GW" => $arg )
                  : $PPC::PPC_GLOBALS->add( "IPv4_GW" => $arg );
            } else {
                _error( "argument", $arg );
            }
        }
    }

    if ( $PPC::PPC_GLOBALS->exists("IPv4_GW") ) {
        if ( !defined wantarray ) {
            print $PPC::PPC_GLOBALS->config("IPv4_GW") . "\n";
        } else {
            return $PPC::PPC_GLOBALS->config("IPv4_GW");
        }
    } else {
        if (defined( $PPC::PPC_GLOBALS->config("interface") )
            and defined(
                $PPC::PPC_GLOBALS->config("interface")->ipv4_default_gateway
            )
          ) {
            if ( !defined wantarray ) {
                print $PPC::PPC_GLOBALS->config("interface")
                  ->ipv4_default_gateway . "\n";
            }
            return $PPC::PPC_GLOBALS->config("interface")
              ->ipv4_default_gateway;
        }
        if ( !defined wantarray ) {
            print "Not defined\n";
        }
    }
    return undef;
}

sub IPv6_SRC {
    my ($arg) = @_;

    if ( defined($arg) and ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) ) {
        PPC::_help( __PACKAGE__, "MACROS/IPv6_SRC - source IPv6 address" );
    }

    if ( defined $arg ) {
        if ( $arg eq ":clear" ) {
            my $r = $PPC::PPC_GLOBALS->delete("IPv6_SRC");
        } else {

            # DIE  - Net::IPv6Addr croaks on error, I prefer to handle nicely
            local $SIG{__DIE__}  = sub { return; };
            my $addr;
            eval { $addr = Net::IPv6Addr->new($arg); };
            if ( defined $addr ) {
                ( $PPC::PPC_GLOBALS->exists("IPv6_SRC") )
                  ? $PPC::PPC_GLOBALS->config( "IPv6_SRC" => lc($arg) )
                  : $PPC::PPC_GLOBALS->add( "IPv6_SRC" => lc($arg) );
            } else {
                _error( "argument", $arg );
            }
        }
    }

    if ( $PPC::PPC_GLOBALS->exists("IPv6_SRC") ) {
        if ( !defined wantarray ) {
            print $PPC::PPC_GLOBALS->config("IPv6_SRC") . "\n";
        } else {
            return $PPC::PPC_GLOBALS->config("IPv6_SRC");
        }
    } else {
        if (    defined( $PPC::PPC_GLOBALS->config("interface") )
            and defined( $PPC::PPC_GLOBALS->config("interface")->ipv6 ) ) {
            if ( !defined wantarray ) {
                print $PPC::PPC_GLOBALS->config("interface")->ipv6 . "\n";
            }
            return $PPC::PPC_GLOBALS->config("interface")->ipv6;
        }
        if ( !defined wantarray ) {
            print "Not defined\n";
        }
    }
    return undef;
}

sub IPv6_SRC_LL {
    my ($arg) = @_;

    if ( defined($arg) and ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) ) {
        PPC::_help( __PACKAGE__,
            "MACROS/IPv6_SRC_LL - source IPv6 link local address" );
    }

    if ( defined($arg) ) {
        if ( $arg eq ":clear" ) {
            my $r = $PPC::PPC_GLOBALS->delete("IPv6_SRC_LL");
        } else {

            # DIE  - Net::IPv6Addr croaks on error, I prefer to handle nicely
            local $SIG{__DIE__}  = sub { return; };
            my $addr;
            eval { $addr = Net::IPv6Addr->new($arg); };
            if ( defined $addr ) {
                if ( substr( $addr->to_string_preferred, 0, 4 ) ne 'fe80' ) {
                    _error( "IPv6 link local address", $arg );
                }
                ( $PPC::PPC_GLOBALS->exists("IPv6_SRC_LL") )
                  ? $PPC::PPC_GLOBALS->config( "IPv6_SRC_LL" => lc($arg) )
                  : $PPC::PPC_GLOBALS->add( "IPv6_SRC_LL" => lc($arg) );
            } else {
                _error( "argument", $arg );
            }
        }
    }

    if ( $PPC::PPC_GLOBALS->exists("IPv6_SRC_LL") ) {
        if ( !defined wantarray ) {
            print $PPC::PPC_GLOBALS->config("IPv6_SRC_LL") . "\n";
        } else {
            return $PPC::PPC_GLOBALS->config("IPv6_SRC_LL");
        }
    } else {
        if (defined( $PPC::PPC_GLOBALS->config("interface") )
            and defined(
                $PPC::PPC_GLOBALS->config("interface")->ipv6_link_local
            )
          ) {
            if ( !defined wantarray ) {
                print $PPC::PPC_GLOBALS->config("interface")->ipv6_link_local
                  . "\n";
            }
            return $PPC::PPC_GLOBALS->config("interface")->ipv6_link_local;
        }
        if ( !defined wantarray ) {
            print "Not defined\n";
        }
    }
    return undef;
}

sub IPv6_GW {
    my ($arg) = @_;

    if ( defined($arg) and ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) ) {
        PPC::_help( __PACKAGE__, "MACROS/IPv6_GW - IPv6 default gateway" );
    }

    if ( defined $arg ) {
        if ( $arg eq ":clear" ) {
            my $r = $PPC::PPC_GLOBALS->delete("IPv6_GW");
        } else {

            # DIE  - Net::IPv6Addr croaks on error, I prefer to handle nicely
            local $SIG{__DIE__}  = sub { return; };
            my $addr;
            eval { $addr = Net::IPv6Addr->new($arg); };
            if ( defined $addr ) {
                ( $PPC::PPC_GLOBALS->exists("IPv6_GW") )
                  ? $PPC::PPC_GLOBALS->config( "IPv6_GW" => lc($arg) )
                  : $PPC::PPC_GLOBALS->add( "IPv6_GW" => lc($arg) );
            } else {
                _error( "argument", $arg );
            }
        }
    }

    if ( $PPC::PPC_GLOBALS->exists("IPv6_GW") ) {
        if ( !defined wantarray ) {
            print $PPC::PPC_GLOBALS->config("IPv6_GW") . "\n";
        } else {
            return $PPC::PPC_GLOBALS->config("IPv6_GW");
        }
    } else {
        if (defined( $PPC::PPC_GLOBALS->config("interface") )
            and defined(
                $PPC::PPC_GLOBALS->config("interface")->ipv6_default_gateway
            )
          ) {
            if ( !defined wantarray ) {
                print $PPC::PPC_GLOBALS->config("interface")
                  ->ipv6_default_gateway . "\n";
            }
            return $PPC::PPC_GLOBALS->config("interface")
              ->ipv6_default_gateway;
        }
        if ( !defined wantarray ) {
            print "Not defined\n";
        }
    }
    return undef;
}

sub D2B {
    my ( $dec, $pad ) = @_;

    if ( !defined($dec)
        or ( defined($dec) and ( $dec eq $PPC::PPC_GLOBALS->{help_cmd} ) ) ) {
        PPC::_help( __PACKAGE__,
            "MACROS/D2B - convert decimal number to binary" );
    }

    my $ret;
    if ( $dec =~ /^\d+$/ ) {
        $ret = sprintf "%b", $dec;
        if ( defined $pad ) {
            if ( $pad =~ /^\d+$/ ) {
                $pad = "0" x ( $pad - length($ret) );
                $ret = $pad . $ret;
            } else {
                warn "Ignoring not a number pad `$pad'\n";
            }
        }
        if ( !defined wantarray ) {
            print "$ret\n";
        }
        return $ret;
    } else {
        PPC::_error( "Not a decimal number `$dec'" );
    }
}

sub D2H {
    my ($dec) = @_;

    if ( !defined($dec)
        or ( defined($dec) and ( $dec eq $PPC::PPC_GLOBALS->{help_cmd} ) ) ) {
        PPC::_help( __PACKAGE__,
            "MACROS/D2H - convert decimal number to hex" );
    }

    my $ret;
    if ( $dec =~ /^\d+$/ ) {
        $ret = sprintf "%x", $dec;
        if ( !defined wantarray ) {
            print "$ret\n";
        }
        return $ret;
    } else {
        PPC::_error( "Not a decimal number `$dec'" );
    }
}

sub H2B {
    my ( $hex, $pad ) = @_;

    if ( !defined($hex)
        or ( defined($hex) and ( $hex eq $PPC::PPC_GLOBALS->{help_cmd} ) ) ) {
        PPC::_help( __PACKAGE__,
            "MACROS/H2B - convert hex number to binary" );
    }

    my $ret;
    if ( $hex =~ /^(?:0x)?[0-9a-fA-F]+$/ ) {
        $ret = sprintf "%b", $hex;
        if ( defined $pad ) {
            if ( $pad =~ /^\d+$/ ) {
                $pad = "0" x ( $pad - length($ret) );
                $ret = $pad . $ret;
            } else {
                warn "Ignoring not a number pad `$pad'\n";
            }
        }
        if ( !defined wantarray ) {
            print "$ret\n";
        }
        return $ret;
    } else {
        PPC::_error( "Not a hex number `$hex'" );
    }
}

sub H2D {
    my ($hex) = @_;

    if ( !defined($hex)
        or ( defined($hex) and ( $hex eq $PPC::PPC_GLOBALS->{help_cmd} ) ) ) {
        PPC::_help( __PACKAGE__,
            "MACROS/H2D - convert hex number to decimal" );
    }

    my $ret;

    # passed as number
    if ( $hex =~ /^\d+$/ ) {
        if ( !defined wantarray ) {
            print "$hex\n";
        }
        return $hex;
    }

    # passed as string
    if ( $hex =~ /^(?:0x)?[0-9a-fA-F]+$/ ) {
        $ret = hex($hex);
        if ( !defined wantarray ) {
            print "$ret\n";
        }
        return $ret;
    } else {
        PPC::_error( "Not a hex number `$hex'" );
    }
}

sub H2S {
    my ($pack) = @_;

    if ( !defined($pack)
        or ( defined($pack) and ( $pack eq $PPC::PPC_GLOBALS->{help_cmd} ) ) )
    {
        PPC::_help( __PACKAGE__, "MACROS/H2S - convert hex to string" );
    }

    my $ret;
    $ret = pack "H*", $pack;
    if ( !defined wantarray ) {
        print "$ret\n";
    }
    return $ret;
}

sub S2H {
    my ($str) = @_;

    if ( !defined($str)
        or ( defined($str) and ( $str eq $PPC::PPC_GLOBALS->{help_cmd} ) ) ) {
        PPC::_help( __PACKAGE__, "MACROS/S2H - convert string to hex" );
    }

    if ( ( ref $str ) =~ /^Net::Frame::/ ) {
        if ( ( ref $str ) =~ /^Net::Frame::Layer::/ ) {
            $str->pack;
        } 
        $str = $str->raw;
    }

    my $ret;
    for ( split //, $str ) {
        $ret .= sprintf "%0.2x", ord $_;
    }
    if ( !defined wantarray ) {
        print "$ret\n";
    }
    return $ret;
}

sub _error {
    my ( $arg1, $arg2 ) = @_;
    PPC::_error( "Not a valid $arg1 - `$arg2'" );
}

1;

__END__

########################################################
# Start POD
########################################################

=head1 NAME

PPC::Macro - Perl Packet Crafter Macro

=head1 SYNOPSIS

 use PPC::Macro;

=head1 DESCRIPTION

Macros are shortcuts provided to the B<PPC> shell for quick access to dynamic 
information and transformation functions.  For example, macros provide 
the current Ethernet MAC, IPv4/v6 (if available) addresses of the current 
interface set with the B<interface> command.

Macros also provide quick transformations between binary, decimal and hex 
values as well as string and hex transformations.

=head1 MACROS

=head2 MAC_SRC - source MAC address

 [$mac_src =] MAC_SRC [MAC | :clear]

Creates B<$mac_src> variable from source MAC address.  Assumes
C<interface> command has been run.  No variable assignment prints output.  
Optional MAC sets MAC, B<:clear> uses default.

=head2 MAC_GW - IPv4 default gateway MAC address

 [$mac_gw =] MAC_GW [MAC | :clear]

Creates B<$mac_gw> variable from IPv4 default gateway MAC address.  Assumes
C<interface> command has been run.  No variable assignment prints output.  
Optional MAC sets MAC, B<:clear> uses default.

=head2 MAC6_GW - IPv6 default gateway MAC address

 [$mac6_gw =] MAC6_GW [MAC | :clear]

Creates B<$mac_gw> variable from IPv6 default gateway MAC address.  Assumes
C<interface> command has been run.  No variable assignment prints output.  
Optional MAC sets MAC, B<:clear> uses default.

=head2 IPv4_SRC - source IPv4 address

 [$ipv4_src =] IPv4_SRC [IPv4 | :clear]

Creates B<$ipv4_src> variable from source IPv4 address.  Assumes
C<interface> command has been run.  No variable assignment prints output.  
Optional IPv4 sets IPV4, B<:clear> uses default.

=head2 IPv4_GW - IPv4 default gateway

 [$ipv4_gw =] IPv4_GW [IPv4 | :clear]

Creates B<$ipv4_gw> variable from IPv4 default gateway.  Assumes
C<interface> command has been run.  No variable assignment prints output.  
Optional IPv4 sets IPV4, B<:clear> uses default.

=head2 IPv6_SRC - source IPv6 address

 [$ipv6_src =] IPv6_SRC [IPv6 | :clear]

Creates B<$ipv6_src> variable from source IPv6 address.  Assumes
C<interface> command has been run.  No variable assignment prints output.  
Optional IPv6 sets IPV6, B<:clear> uses default.

=head2 IPv6_SRC_LL - source IPv6 link local address

 [$ipv6_src_ll =] IPv6_SRC_LL [IPv6 | :clear]

Creates B<$ipv6_src_ll> variable from source IPv6 link local address.
Assumes C<interface> command has been run.  No variable assignment 
prints output.  Optional IPv6 sets IPv6, B<:clear> uses default.

=head2 IPv6_GW - IPv6 default gateway

 [$ipv6_gw =] IPv6_GW [IPv6 | :clear]

Creates B<$ipv6_gw> variable from IPv6 default gateway.  Assumes
C<interface> command has been run.  No variable assignment prints output.  
Optional IPv6 sets IPv6, B<:clear> uses default.

=head2 D2B - convert decimal number to binary

 [$binary =] D2B "decimalNumber" [, padding]

Creates B<$binary> variable as binary representation of B<decimalNumber>.  
Without optional return variable simply prints output.  Optional padding 
is total number of bits for return number.

=head2 D2H - convert decimal number to hex

 [$hex =] D2H "decimalNumber"

Creates B<$hex> variable as hex representation of B<decimalNumber>.  
Without optional return variable simply prints output.

=head2 H2B - convert hex number to binary

 [$binary =] H2B "hexNumber" [, padding]

Creates B<$binary> variable as binary representation of B<hexNumber>.  
Without optional return variable simply prints output.  Optional padding 
is total number of bits for return number.

=head2 H2D - convert hex number to decimal

 [$dec =] H2D "hexNumber"

Creates B<$dec> variable as decimal representation of B<hexNumber>.  
Without optional return variable simply prints output.

=head2 H2S - convert hex to string

 [$pack_string =] H2S "hex_string"

Creates B<$pack_string> variable from B<hex_string>.  
Without optional return variable simply prints output.

=head2 S2H - convert string to hex

 [$hex =] S2H "pack_string"

Creates B<$hex> variable as hex representation of B<pack_string>.  
Without optional return variable simply prints output.

=head1 SEE ALSO

L<PPC>, L<PPC::Macro>, L<PPC::Interface>, 

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
