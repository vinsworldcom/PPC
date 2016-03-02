package PPC::Plugin::TCPOptions;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

use Exporter;

our @EXPORT = qw(
  TCPOptions
  tcpopts
  tcpoptions
  TCPEOOL
  TCPNOOP
  TCPMSS
  TCPWSOPT
  TCPSACKPERMIT
  TCPTSOPT
  TCPPOCPERMIT
  TCPPOSP
  TCPCC
  TCPCCNEW
  TCPCCECHO
  TCPACHKSUMRQ
);

our @ISA = qw ( PPC Exporter );

sub TCPOptions {
    PPC::_help_full( __PACKAGE__ );
}

########################################################

sub tcpopts {
    return tcpoptions(@_);
}

sub tcpoptions {
    my ($arg) = @_;

    if ( !defined($arg) or ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "COMMANDS/tcpoptions - decode TCP option string" );
    }

    my %tcpopts = (
        '00' => 'EOOL',
        '01' => 'NOOP',
        '02' => 'MSS',
        '03' => 'WSOPT',
        '04' => 'SACKPERMIT',
        '08' => 'TSOPT',
        '09' => 'POCPERMIT',
        '0a' => 'POSP',
        '0b' => 'CC',
        '0c' => 'CCNEW',
        '0d' => 'CCECHO',
        '0e' => 'ACHKSUMRQ'
    );

    my $c = 0;
    while ( $c < length $arg ) {
        # check for substr too long for string error
        if ( length $arg < $c + 2 ) {
            PPC::_error( "Cannot unpack option" );
            last;
        }

        # unpack option
        my $opt = substr $arg, $c, 2;
        $c += 2;
        printf "%-12s", defined ($tcpopts{$opt}) ? $tcpopts{$opt} : "Option:$opt" ;

        # option 0 or 1 are done
        if ( ( hex $opt == 0 ) or ( hex $opt == 1 ) ) {
            print "\n";
            next;
        }

        # check for substr too long for string error
        if ( length $arg < $c + 2 ) {
            PPC::_error( "Cannot unpack length" );
            last;
        }
        
        # unpack length
        my $len = substr $arg, $c, 2;
        $c += 2;
        #print " ($len) ";

        # options with length 2 are done
        if ( hex $len == 2 ) {
            print "\n";
            next;
        }

        # check for substr too long for string error
        if ( length $arg < ($c + (((hex $len)-2)*2)) ) {
            PPC::_error( "Cannot unpack value" );
            last;
        }

        # unpack value
        my $val = substr $arg, $c, (((hex $len)-2)*2);
        $c += ((hex $len)-2)*2;
        print "= $val\n";
    }
}

sub TCPEOOL {
    my $ret = "00";
    my $retType = wantarray;

    if ( !defined $retType ) {
        print "$ret\n";
        return;
    } else {
        return pack "H*", $ret;
    }
}

sub TCPNOOP {
    my $ret = "01";
    my $retType = wantarray;

    if ( !defined $retType ) {
        print "$ret\n";
        return;
    } else {
        return pack "H*", $ret;
    }
}

sub TCPMSS {
    my ($arg) = @_;

    if ( defined $arg ) {
        if  ( ( $arg !~ /^\d{1,5}$/ ) 
           or ( $arg < 0 ) 
           or ( $arg > 65535 ) ) {
            $arg = 32768;
        }
    } else {
        $arg = 32768;
    }

    my $ret = "0204" . sprintf "%04x", $arg;
    my $retType = wantarray;

    if ( !defined $retType ) {
        print "$ret\n";
        return;
    } else {
        return pack "H*", $ret;
    }
}

sub TCPWSOPT {
    my ($arg) = @_;

    if ( defined $arg ) {
        if  ( ( $arg !~ /^\d{1,3}$/ ) 
           or ( $arg < 0 ) 
           or ( $arg > 255 ) ) {
            $arg = 128;
        }
    } else {
        $arg = 128;
    }

    my $ret = "0303" . sprintf "%02x", $arg;
    my $retType = wantarray;

    if ( !defined $retType ) {
        print "$ret\n";
        return;
    } else {
        return pack "H*", $ret;
    }
}

sub TCPSACKPERMIT {
    my $ret = "0402";
    my $retType = wantarray;

    if ( !defined $retType ) {
        print "$ret\n";
        return;
    } else {
        return pack "H*", $ret;
    }
}

sub TCPTSOPT {
    my ( $arg1, $arg2 ) = @_;

    if ( defined $arg1 ) {
        if  ( $arg1 !~ /^\d+$/ ) {
            $arg1 = time;
        }
    } else {
        $arg1 = time;
    }
    if ( defined $arg2 ) {
        if  ( $arg2 !~ /^\d+$/ ) {
            $arg2 = time;
        }
    } else {
        $arg2 = time;
    }

    $arg1 = sprintf "%08x", $arg1;
    $arg1 = substr $arg1, 0, 8;
    $arg2 = sprintf "%08x", $arg2;
    $arg2 = substr $arg2, 0, 8;

    my $ret = "080a" . $arg1 . $arg2;
    my $retType = wantarray;

    if ( !defined $retType ) {
        print "$ret\n";
        return;
    } else {
        return pack "H*", $ret;
    }
}

sub TCPPOCPERMIT {
    my $ret = "0902";
    my $retType = wantarray;

    if ( !defined $retType ) {
        print "$ret\n";
        return;
    } else {
        return pack "H*", $ret;
    }
}

sub TCPPOSP {
    my ($arg) = @_;

    if ( defined $arg ) {
        if  ( ( $arg !~ /^\d{1,3}$/ ) 
           or ( $arg < 0 ) 
           or ( $arg > 255 ) ) {
            $arg = 192;
        }
    } else {
        $arg = 192;
    }

    my $ret = "0a03" . sprintf "%02x", $arg;
    my $retType = wantarray;

    if ( !defined $retType ) {
        print "$ret\n";
        return;
    } else {
        return pack "H*", $ret;
    }
}

sub TCPCC {
    my ($arg) = @_;

    if ( defined $arg ) {
        if  ( $arg !~ /^\d+$/ ) {
            $arg = 1073741824;
        }
    } else {
        $arg = 1073741824;
    }

    $arg = sprintf "%08x", $arg;
    $arg = substr $arg, 0, 8;

    my $ret = "0b06" . $arg;
    my $retType = wantarray;

    if ( !defined $retType ) {
        print "$ret\n";
        return;
    } else {
        return pack "H*", $ret;
    }
}

sub TCPCCNEW {
    my ($arg) = @_;

    if ( defined $arg ) {
        if  ( $arg !~ /^\d+$/ ) {
            $arg = 1073741824;
        }
    } else {
        $arg = 1073741824;
    }

    $arg = sprintf "%08x", $arg;
    $arg = substr $arg, 0, 8;

    my $ret = "0c06" . $arg;
    my $retType = wantarray;

    if ( !defined $retType ) {
        print "$ret\n";
        return;
    } else {
        return pack "H*", $ret;
    }
}

sub TCPCCECHO {
    my ($arg) = @_;

    if ( defined $arg ) {
        if  ( $arg !~ /^\d+$/ ) {
            $arg = 1073741824;
        }
    } else {
        $arg = 1073741824;
    }

    $arg = sprintf "%08x", $arg;
    $arg = substr $arg, 0, 8;

    my $ret = "0d06" . $arg;
    my $retType = wantarray;

    if ( !defined $retType ) {
        print "$ret\n";
        return;
    } else {
        return pack "H*", $ret;
    }
}

sub TCPACHKSUMRQ {
    my ($arg) = @_;

    if ( defined $arg ) {
        if  ( ( $arg !~ /^\d{1,3}$/ ) 
           or ( $arg < 0 ) 
           or ( $arg > 255 ) ) {
            $arg = 0;
        }
    } else {
        $arg = 0;
    }

    my $ret = "0e03" . sprintf "%02x", $arg;
    my $retType = wantarray;

    if ( !defined $retType ) {
        print "$ret\n";
        return;
    } else {
        return pack "H*", $ret;
    }
}

1;

__END__

=head1 NAME

TCPOptions - TCP Options

=head1 SYNOPSIS

 use PPC::Plugin::TCPOptions;

=head1 DESCRIPTION

TCP options provides subroutines for creating TCP options strings.

=head1 COMMANDS

=head2 TCPOptions - provide help

Provides help from the B<PPC> shell.

=head2 tcpoptions - decode TCP option string

 tcpoptions "TCP_opts_string";

Decodes the provided TCP options string.

Alias:

=over 4

=item B<tcpopts>

=back

=head1 SUBROUTINES

The following create TCP options.

=over 4

=item B<TCPEOOL>

End of option list.

=item B<TCPNOOP>

No operation.

=item B<TCPMSS> (#)

Maximum Segment Size.  0 E<lt>= MSS E<lt>= 65535.

=item B<TCPWSOPT> (#)

Window Scaling Factor.  0 E<lt>= WSOPT E<lt>= 255.

=item B<TCPSACKPERMIT>

Selective Acknowledgement permitted.

=item B<TCPTSOPT> (#,#)

Timestamp.

=item B<TCPPOCPERMIT>

Partial Order Connection permitted.

=item B<TCPPOSP>

Partial Order Service Profile.  Generally 0xC0, 0x80, 0x40.

=item B<TCPCC> (#)

Connection Count.

=item B<TCPCCNEW> (#)

Connection Count New.

=item B<TCPCCECHO> (#)

Connection Count Echo.

=item B<TCPACHKSUMRQ> (#)

Alternate Checksum Request.

=back

=head1 SEE ALSO

L<Net::Frame::Layer::TCP>

=head1 ACKNOWLEDGEMENTS

Special thanks to Patrice E<lt>GomoRE<gt> Auffret without whose 
Net::Frame::[...] modules, this would not be possible.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2016 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
