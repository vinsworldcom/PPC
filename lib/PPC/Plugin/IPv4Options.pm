package PPC::Plugin::IPv4Options;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

use Exporter;

our @EXPORT = qw(
  IPv4Options
  ipv4opts
  ipv4options
  IPv4EOOL
  IPv4NOOP
  IPv4LSRR
  IPv4SSRR
  IPv4RR
  IPv4RTRALERT
  makeIPv4Options
);

our @ISA = qw ( PPC Exporter );

sub IPv4Options {
    PPC::_help_full( __PACKAGE__ );
}

########################################################

sub ipv4opts {
    return ipv4options(@_);
}

sub ipv4options {
    my ($arg) = @_;

    if ( !defined($arg) or ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "COMMANDS/ipv4options - decode IPv4 option string" );
    }

    my %ipv4opts = (
        '00' => 'EOOL',
        '01' => 'NOOP',
        '89' => 'SSRR',
        '83' => 'LSRR',
        '07' => 'RR',
        '94' => 'RTRALERT',
    );

    my @rets;
    my $retType = wantarray;

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
        if ( !defined($retType) ) {
            printf "%-12s", defined ($ipv4opts{$opt}) ? $ipv4opts{$opt} : "Option:$opt" ;
        } else {
            push @rets, defined ($ipv4opts{$opt}) ? $ipv4opts{$opt} : $opt;
        }

        # option 0 or 1 are done
        if ( ( hex $opt == 0 ) or ( hex $opt == 1 ) ) {
            if ( !defined($retType) ) {
                print "\n";
            }
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
            if ( !defined($retType) ) {
                print "\n";
            }
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
        if ( !defined($retType) ) {
            print "= $val\n";
        } else {
            push @rets, "= $val";
        }
    }

    if ( !defined $retType ) {
        return;
    } elsif ($retType) {
        return @rets;
    } else {
        return \@rets;
    }
}

sub IPv4EOOL {
    my $ret = "00";
    my $retType = wantarray;

    if ( !defined $retType ) {
        print "$ret\n";
        return;
    } else {
        return pack "H*", $ret;
    }
}

sub IPv4NOOP {
    my $ret = "01";
    my $retType = wantarray;

    if ( !defined $retType ) {
        print "$ret\n";
        return;
    } else {
        return pack "H*", $ret;
    }
}

sub IPv4LSRR {
    my ($arg, @addrs) = @_;

    if ( defined $arg ) {
        if  ( ( $arg !~ /^\d{1,3}$/ )
           or ( $arg < 0 )
           or ( $arg > 255 ) ) {
            $arg = 4;
        }
    } else {
        $arg = 4;
    }

    my $route = '';
    if ( @addrs ) {
        for my $addr ( @addrs ) {
            my ($w, $x, $y, $z) = split /\./, $addr;
            $route .= ( sprintf "%02x", $w )
                    . ( sprintf "%02x", $x )
                    . ( sprintf "%02x", $y )
                    . ( sprintf "%02x", $z );
        }
    } else {
        $route = '7f000001'; # loopback
    }

    my $ret = "83"
      . ( sprintf "%02x", 3 + (length $route)/2 )
      . ( sprintf "%02x", $arg )
      . $route;
    my $retType = wantarray;

    if ( !defined $retType ) {
        print "$ret\n";
        return;
    } else {
        return pack "H*", $ret;
    }
}

sub IPv4SSRR {
    my ($arg, @addrs) = @_;

    if ( defined $arg ) {
        if  ( ( $arg !~ /^\d{1,3}$/ )
           or ( $arg < 0 )
           or ( $arg > 255 ) ) {
            $arg = 4;
        }
    } else {
        $arg = 4;
    }

    my $route = '';
    if ( @addrs ) {
        for my $addr ( @addrs ) {
            my ($w, $x, $y, $z) = split /\./, $addr;
            $route .= ( sprintf "%02x", $w )
                    . ( sprintf "%02x", $x )
                    . ( sprintf "%02x", $y )
                    . ( sprintf "%02x", $z );
        }
    } else {
        $route = '7f000001'; # loopback
    }

    my $ret = "89"
      . ( sprintf "%02x", 3 + (length $route)/2 )
      . ( sprintf "%02x", $arg )
      . $route;
    my $retType = wantarray;

    if ( !defined $retType ) {
        print "$ret\n";
        return;
    } else {
        return pack "H*", $ret;
    }
}

sub IPv4RR {
    my ($arg, @addrs) = @_;

    if ( defined $arg ) {
        if  ( ( $arg !~ /^\d{1,3}$/ )
           or ( $arg < 0 )
           or ( $arg > 255 ) ) {
            $arg = 4;
        }
    } else {
        $arg = 4;
    }

    my $route = '';
    if ( @addrs ) {
        for my $addr ( @addrs ) {
            my ($w, $x, $y, $z) = split /\./, $addr;
            $route .= ( sprintf "%02x", $w )
                    . ( sprintf "%02x", $x )
                    . ( sprintf "%02x", $y )
                    . ( sprintf "%02x", $z );
        }
    } else {
        $route = '00000000';
    }

    my $ret = "07"
      . ( sprintf "%02x", 3 + (length $route)/2 )
      . ( sprintf "%02x", $arg )
      . $route;
    my $retType = wantarray;

    if ( !defined $retType ) {
        print "$ret\n";
        return;
    } else {
        return pack "H*", $ret;
    }
}

sub IPv4RTRALERT {
    my ($arg) = @_;

    if ( defined $arg ) {
        if  ( ( $arg !~ /^\d{1,5}$/ )
           or ( $arg < 0 )
           or ( $arg > 65535 ) ) {
            $arg = 0;
        }
    } else {
        $arg = 0;
    }

    my $ret = "9404" . sprintf "%04x", $arg;
    my $retType = wantarray;

    if ( !defined $retType ) {
        print "$ret\n";
        return;
    } else {
        return pack "H*", $ret;
    }
}

sub makeIPv4Options {
    my (@opts) = @_;

    my $optstring = join '', @opts;
    my $len = length($optstring) % 4;
    if ($len) {
        my $padding = IPv4NOOP() x ( 4 - 1 - $len );
        $optstring = $optstring . $padding . IPv4EOOL;
    }

    my $ret = $optstring;
    my $retType = wantarray;

    if ( !defined $retType ) {
        print "$ret\n";
        return;
    } else {
        return $ret;
    }
}

# Install visual helper for Net::Frame::Layer::IPv4::print
no warnings;
no strict;

*Net::Frame::Layer::IPv4::print = sub {
    my $self = shift;

    my $l = $self->layer;
    my $buf = sprintf
        "$l: version:%d  hlen:%d  tos:0x%02x  length:%d  id:%d\n".
        "$l: flags:0x%02x  offset:%d  ttl:%d  protocol:0x%02x  checksum:0x%04x\n".
        "$l: src:%s  dst:%s",
          $self->version, $self->hlen, $self->tos,
          $self->length, $self->id, $self->flags,
          $self->offset, $self->ttl, $self->protocol,
          $self->checksum, $self->src, $self->dst;

    if ($self->options) {
        $buf .= sprintf "\n$l: optionsLength:%d  options:%s".
                        "\n$l: [options:%s]",
          $self->getOptionsLength,
          CORE::unpack('H*', $self->options),
          join ' ', ipv4options (CORE::unpack('H*', $self->options));
    }

    $buf;
};

1;

__END__

=head1 NAME

IPv4Options - IPv4 Options

=head1 SYNOPSIS

 use PPC::Plugin::IPv4Options;

=head1 DESCRIPTION

IPv4 Options provides standard IPv4 Options to be used in the B<Net::Frame::Layer::IPv4> B<-options> argument.
It also provides an override for the print() accessor of the B<Net::Frame::Layer::IPv4>
object to include the text representation of the IPv4 options.

=head1 COMMANDS

=head2 IPv4Options - provide help

Provides help from the B<PPC> shell.

=head2 ipv4options - decode IPv4 option string

 [$ipv4o =] ipv4options "IPv4_opts_string";

Prints the provided IPv4 options string.  Returns reference to an array of
flag names.

This also overrides the B<Net::Frame::Layer::IPv4> C<print> method, adding
a line with textual options.

  IPv4: version:4  hlen:6  tos:0xc0  length:40  id:0
  IPv4: flags:0x02  offset:0  ttl:1  protocol:0x02  checksum:0xf993
  IPv4: src:10.100.0.2  dst:224.0.0.22
  IPv4: optionsLength:4  options:94040000
  IPv4: [options:RTRALERT = 0000]

Alias:

=over 4

=item B<ipv4opts>

=back

=head1 SUBROUTINES

The following create IPv4 options.

=over 4

=item B<IPv4EOOL>

End of option list.

=item B<IPv4NOOP>

No operation.

=item B<IPv4LSRR> (ptr, ip1,...)

Loose Source Record Route.

=item B<IPv4SSRR> (ptr, ip1,...)

Strict Source Record Route.

=item B<IPv4RR> (ptr, ip1,...)

Record Route.

=item B<IPv4RTRALERT> (#)

IPv4 Router Alert.

=item B<makeIPv4Options> (IPv4xxx, ...)

Make an IPv4 option string of the correct length from the provided subroutines
adding padding and EOOL as requried to fill out the correct length.

=back

=head1 SEE ALSO

L<Net::Frame::Layer::IPv4>

=head1 ACKNOWLEDGEMENTS

Special thanks to Patrice E<lt>GomoRE<gt> Auffret without whose
Net::Frame::[...] modules, this would not be possible.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2013, 2016 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
