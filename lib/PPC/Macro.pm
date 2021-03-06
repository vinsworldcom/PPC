package PPC::Macro;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

use App::PerlShell::Plugin::Macros;    # D2B, D2H, H2B, H2D, H2S, S2H

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
  IPv6_PREFIX
  IPv6_HOSTID
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
        if ( not defined wantarray ) {
            print $PPC::PPC_GLOBALS->config("MAC_SRC") . "\n";
        } else {
            return $PPC::PPC_GLOBALS->config("MAC_SRC");
        }
    } else {
        if (    defined( $PPC::PPC_GLOBALS->config("interface") )
            and defined( $PPC::PPC_GLOBALS->config("interface")->mac ) ) {
            if ( not defined wantarray ) {
                print $PPC::PPC_GLOBALS->config("interface")->mac . "\n";
            }
            return $PPC::PPC_GLOBALS->config("interface")->mac;
        }
        if ( not defined wantarray ) {
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
        if ( not defined wantarray ) {
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
            if ( not defined wantarray ) {
                print $PPC::PPC_GLOBALS->config("interface")
                  ->ipv4_gateway_mac . "\n";
            }
            return $PPC::PPC_GLOBALS->config("interface")->ipv4_gateway_mac;
        }
        if ( not defined wantarray ) {
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
        if ( not defined wantarray ) {
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
            if ( not defined wantarray ) {
                print $PPC::PPC_GLOBALS->config("interface")
                  ->ipv6_gateway_mac . "\n";
            }
            return $PPC::PPC_GLOBALS->config("interface")->ipv6_gateway_mac;
        }
        if ( not defined wantarray ) {
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
        if ( not defined wantarray ) {
            print $PPC::PPC_GLOBALS->config("IPv4_SRC") . "\n";
        } else {
            return $PPC::PPC_GLOBALS->config("IPv4_SRC");
        }
    } else {
        if (    defined( $PPC::PPC_GLOBALS->config("interface") )
            and defined( $PPC::PPC_GLOBALS->config("interface")->ipv4 ) ) {
            if ( not defined wantarray ) {
                print $PPC::PPC_GLOBALS->config("interface")->ipv4 . "\n";
            }
            return $PPC::PPC_GLOBALS->config("interface")->ipv4;
        }
        if ( not defined wantarray ) {
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
        if ( not defined wantarray ) {
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
            if ( not defined wantarray ) {
                print $PPC::PPC_GLOBALS->config("interface")
                  ->ipv4_default_gateway . "\n";
            }
            return $PPC::PPC_GLOBALS->config("interface")
              ->ipv4_default_gateway;
        }
        if ( not defined wantarray ) {
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
            local $SIG{__DIE__} = sub { return; };
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
        if ( not defined wantarray ) {
            print $PPC::PPC_GLOBALS->config("IPv6_SRC") . "\n";
        } else {
            return $PPC::PPC_GLOBALS->config("IPv6_SRC");
        }
    } else {
        if (    defined( $PPC::PPC_GLOBALS->config("interface") )
            and defined( $PPC::PPC_GLOBALS->config("interface")->ipv6 ) ) {
            if ( not defined wantarray ) {
                print $PPC::PPC_GLOBALS->config("interface")->ipv6 . "\n";
            }
            return $PPC::PPC_GLOBALS->config("interface")->ipv6;
        }
        if ( not defined wantarray ) {
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
            local $SIG{__DIE__} = sub { return; };
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
        if ( not defined wantarray ) {
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
            if ( not defined wantarray ) {
                print $PPC::PPC_GLOBALS->config("interface")->ipv6_link_local
                  . "\n";
            }
            return $PPC::PPC_GLOBALS->config("interface")->ipv6_link_local;
        }
        if ( not defined wantarray ) {
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
            local $SIG{__DIE__} = sub { return; };
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
        if ( not defined wantarray ) {
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
            if ( not defined wantarray ) {
                print $PPC::PPC_GLOBALS->config("interface")
                  ->ipv6_default_gateway . "\n";
            }
            return $PPC::PPC_GLOBALS->config("interface")
              ->ipv6_default_gateway;
        }
        if ( not defined wantarray ) {
            print "Not defined\n";
        }
    }
    return undef;
}

sub IPv6_PREFIX {
    my ($arg) = @_;

    if ( not defined($arg)
        or ( defined($arg) and ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) ) ) {
        PPC::_help( __PACKAGE__, "MACROS/IPv6_PREFIX - IPv6 prefix" );
    }

    if ( defined $arg ) {
        local $SIG{__DIE__} = sub { return; };
        my $addr;
        eval { $addr = Net::IPv6Addr->new($arg); };
        if ( defined $addr ) {
            my $prefix = join ":", ( $addr->to_array )[0 .. 3];
            if ( not defined wantarray ) {
                print "$prefix\n";
            }
            return $prefix;
        } else {
            _error( "IPv6 address", $arg );
        }
    }
    return undef;
}

sub IPv6_HOSTID {
    my ($arg) = @_;

    if ( not defined($arg)
        or ( defined($arg) and ( $arg eq $PPC::PPC_GLOBALS->{help_cmd} ) ) ) {
        PPC::_help( __PACKAGE__, "MACROS/IPv6_HOSTID - IPv6 host ID" );
    }

    if ( defined $arg ) {
        local $SIG{__DIE__} = sub { return; };
        my $addr;
        eval { $addr = Net::IPv6Addr->new($arg); };
        if ( defined $addr ) {
            my $prefix = join ":", ( $addr->to_array )[4 .. 7];
            if ( not defined wantarray ) {
                print "$prefix\n";
            }
            return $prefix;
        } else {
            _error( "IPv6 address", $arg );
        }
    }
    return undef;
}

sub _error {
    my ( $arg1, $arg2 ) = @_;
    PPC::_error("Not a valid $arg1 - `$arg2'");
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

=head2 IPv6_PREFIX - IPv6 prefix

 [$ipv6_pfx =] IPv6_PREFIX IPv6_Addr

Creates B<$ipv6_pfx> variable from the /64 prefix of the provided IPv6
address.  No variable assignment prints output.

=head2 IPv6_HOSTID - IPv6 host ID

 [$ipv6_hid =] IPv6_HOSTID IPv6_Addr

Creates B<$ipv6_hid> variable from the /64 host ID of the provided IPv6
address.  No variable assignment prints output.

=head1 SEE ALSO

L<PPC>, L<PPC::Macro>, L<PPC::Interface>, L<App::PerlShell::Plugin::Macros>

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
