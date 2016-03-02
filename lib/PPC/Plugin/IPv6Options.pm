package PPC::Plugin::IPv6Options;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

eval "use Net::Frame::Layer::IPv6::Option";
if ( $@ ) {
    print "Net::Frame::Layer::IPv6::Option required.\n";
    return 1;
}

use Exporter;

our @EXPORT = qw(
  IPv6Options
  ipv6opts
  ipv6options
  IPv6PAD1
  IPv6PADN
  IPv6JUMBO
  IPv6RTRALERT
  NF_IPv6OPTS_RTRALT_MLD
  NF_IPv6OPTS_RTRALT_RSVP
  NF_IPv6OPTS_RTRALT_ACTIVENET
  NF_IPv6OPTS_RTRALT_NSLP
);

our @ISA = qw ( PPC Exporter );

use constant NF_IPv6OPTS_RTRALT_MLD       => 0;
use constant NF_IPv6OPTS_RTRALT_RSVP      => 1;
use constant NF_IPv6OPTS_RTRALT_ACTIVENET => 2;
use constant NF_IPv6OPTS_RTRALT_NSLP      => 68;

sub IPv6Options {
    PPC::_help_full( __PACKAGE__ );
}

########################################################

sub ipv6opts {
    return ipv6options(@_);
}

sub ipv6options {
    my ($arg) = @_;

    if ( !defined($arg) or ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "COMMANDS/ipv6options - decode IPv6 option string" );
    }

    my %ipv6opts = (
        '00' => 'PAD1',
        '01' => 'PADN',
        'c2' => 'JUMBO',
        '05' => 'RTRALERT',
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
        printf "%-12s", defined ($ipv6opts{$opt}) ? $ipv6opts{$opt} : "Option:$opt" ;

        # option 0 is done
        if ( hex $opt == 0 ) {
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

        # options with length 0 are done
        if ( hex $len == 0 ) {
            print "\n";
            next;
        }

        # check for substr too long for string error
        if ( length $arg < ($c + ((hex $len)*2)) ) {
            PPC::_error( "Cannot unpack value" );
            last;
        }

        # unpack value
        my $val = substr $arg, $c, ((hex $len)*2);
        $c += (hex $len)*2;
        print "= $val\n";
    }
}

sub IPv6PAD1 {
    my $ret =  Net::Frame::Layer::IPv6::Option->new(
        type   => 0,
    );
    my $retType = wantarray;

    if ( !defined $retType ) {
        $ret->pack;
        print unpack "H*", $ret->raw;
        return;
    } else {
        return $ret;
    }
}

sub IPv6PADN {
    my ( $arg1, $arg2 ) = @_;

    # padding, default is 2 PADN is 2 bytes of padding
    if ( defined $arg1 ) {
        if  ( ( $arg1 !~ /^\d{1,3}$/ )
           or ( $arg1 < 3 )
           or ( $arg1 > 255 ) ) {
           $arg1 = 2;
        }
    } else {
        $arg1 = 2;
    }
    # adjust for default 2 bytes
    $arg1 -= 2;

    if ( defined $arg2 ) {
        my $ret;
        
        # create hex string for padding
        for ( split //, $arg2 ) {
            $ret .= sprintf "%02x", ord $_;
        }
        $arg2 = $ret;
        
        # if padN is greater than length of string, add padding
        if ( $arg1 >= ( ( length $arg2 ) / 2 ) ) {
            for ( 1 .. ( $arg1 - ( (length $arg2 ) / 2 ) ) ) {
                $arg2 .= sprintf "%02x", 0;
            }
            
        # else adjust length to match length of string
        } else {
            $arg1 = length $arg2;
        }
    } else {
    
        # no string specified, just add 0 padding for length
        $arg2 = '';
        for ( 1 .. $arg1 ) {
            $arg2 .= sprintf "%02x", 0;
        }
    }

    my $ret =  Net::Frame::Layer::IPv6::Option->new(
        type   => 1,
        length => $arg1,
        value  => pack "H*", $arg2
    );
    my $retType = wantarray;

    if ( !defined $retType ) {
        $ret->pack;
        print unpack "H*", $ret->raw;
        return;
    } else {
        return $ret;
    }
}

sub IPv6JUMBO {
    my ($arg) = @_;

    if ( defined $arg ) {
        if ( $arg !~ /^\d+$/ ) {
           $arg = 65536;
        }
    } else {
        $arg = 65536;
    }

    $arg = sprintf "%08x", $arg;
    $arg = substr $arg, 0, 8;
    my $ret =  Net::Frame::Layer::IPv6::Option->new(
        type   => 194,
        length => 4,
        value  => pack "H*", $arg
    );
    my $retType = wantarray;

    if ( !defined $retType ) {
        $ret->pack;
        print unpack "H*", $ret->raw;
        return;
    } else {
        return $ret;
    }
}

sub IPv6RTRALERT {
    my ($arg) = @_;

    if ( defined $arg ) {
        if  ( ( $arg !~ /^\d{1,5}$/ )
           or ( $arg < 0 )
           or ( $arg > 65535 ) ) {
           $arg = NF_IPv6OPTS_RTRALT_MLD;
        }
    } else {
        $arg = NF_IPv6OPTS_RTRALT_MLD;
    }

    $arg = sprintf "%04x", $arg;
    my $ret =  Net::Frame::Layer::IPv6::Option->new(
        type   => 5,
        length => 2,
        value  => pack "H*", $arg
    );
    my $retType = wantarray;

    if ( !defined $retType ) {
        $ret->pack;
        print unpack "H*", $ret->raw;
        return;
    } else {
        return $ret;
    }
}

1;

__END__

=head1 NAME

IPv6Options - IPv6 Options

=head1 SYNOPSIS

 use PPC::Plugin::IPv6Options;

=head1 DESCRIPTION

IPv6 Options provides standard IPv6 Options to be used in the B<Net::Frame::Layer::IPv6> extension header submodules.

=head1 COMMANDS

=head2 IPv6Options - provide help

Provides help from the B<PPC> shell.

=head2 ipv6options - decode IPv6 option string

 ipv6options "IPv6_opts_string";

Decodes the provided IPv6 options string.

Alias:

=over 4

=item B<ipv6opts>

=back

=head1 SUBROUTINES

The following create IPv6 options.

=over 4

=item B<IPv6PAD1>

Pad1.

=item B<IPv6PADN> (#)

PadN.

=item B<IPv6JUMBO> (#)

Jumbo payload.

=item B<IPv6RTRALERT> (#)

IPv6 Router Alert.  Suitable for B<Net::Frame::Layer::IPv6::HopByHop> B<-options> argument.

=back

=head1 CONSTANTS

=over 4

=item B<NF_IPv6OPTS_RTRALT_MLD>

=item B<NF_IPv6OPTS_RTRALT_RSVP>

=item B<NF_IPv6OPTS_RTRALT_ACTIVENET>

=item B<NF_IPv6OPTS_RTRALT_NSLP>

IPv6 Router Alert Option values.

=back

=head1 SEE ALSO

L<Net::Frame::Layer::IPv6>

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
