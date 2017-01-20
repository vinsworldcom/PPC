package PPC::Plugin::ICMPv6TypeCode;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

eval "use Net::Frame::Layer::ICMPv6 qw( :consts )";
if ( $@ ) {
    print "Net::Frame::Layer::ICMPv6 required.\n";
    return 1;
}

use Exporter;

our @EXPORT = qw(
  ICMPv6TypeCode
  icmpv6typecode
);

our @ISA = qw ( PPC Exporter );

my %TYPE = (
    1   => 'Destination Unreachable',
    2   => 'Packet Too Big',
    3   => 'Time Exceeded',
    4   => 'Parameter Problem',
    128 => 'Echo Request',
    129 => 'Echo Reply',
    130 => 'Multicast Listener Query',
    131 => 'Multicast Listener Report',
    132 => 'Multicast Listener Done',
    133 => 'Router Solicitation',
    134 => 'Router Advertisement',
    135 => 'Neighbor Solicitation',
    136 => 'Neighbor Advertisement',
    137 => 'Redirect',
    138 => 'Router Renumbering',
    139 => 'Node Information Query',
    140 => 'Node Information Response',
    141 => 'Inverse Neighbor Discovery Solicitation',
    142 => 'Inverse Neighbor Discovery Advertisement',
    143 => 'Multicast Listener v2 Report',
    144 => 'Home Agent Address Discovery Request',
    145 => 'Home Agent Address Discovery Reply',
    146 => 'Mobile Prefix Solicitation',
    147 => 'Mobile Prefix Advertisement',
    148 => 'Certification Path Solicitation',
    149 => 'Certification Path Advertisement',
    151 => 'Multicast Router Advertisement',
    152 => 'Multicast Router Solicitation',
    153 => 'Multicast Router Termination',
    154 => 'FMIPv6',
    155 => 'RPL Control',
    156 => 'ILNPv6 Locator Update',
    157 => 'Duplicate Address Request',
    158 => 'Duplicate Address Confirmation'
);

my %CODE = (

    # TYPE:CODE
    '1:0'     => 'No Route to Destination',
    '1:1'     => 'Destination is Administratively Prohibited',
    '1:2'     => 'Beyond Scope of Source Address',
    '1:3'     => 'Address Unreachable',
    '1:4'     => 'Port Unreachable',
    '1:5'     => 'Source Address Failed Ingress/Egress Policy',
    '1:6'     => 'Reject Route to Destination',
    '1:7'     => 'Error in Source Route Header',
    '3:1'     => 'Fragment Reassembly Time Exceeded',
    '4:1'     => 'Unrecognized Next Header',
    '4:2'     => 'Unrecognized IPv6 Option',
    '138:1'   => 'Router Renumbering Result',
    '138:255' => 'Sequence Number Reset',
    '139:1'   => 'Data contains Name or Empty',
    '139:2'   => 'Data contains IPv4 address',
    '140:1'   => 'Responder Refuses to Supply Answer',
    '140:2'   => 'Qtype is Unknown',
    '154:2'   => 'RtSolPr',
    '154:3'   => 'PrRtAdv',
    '154:4'   => 'HI',
    '154:5'   => 'HAck'
);

sub ICMPv6TypeCode {
    PPC::_help_full( __PACKAGE__ );
}

########################################################

sub icmpv6typecode {
    my ( $type, $code ) = @_;

    if ( !defined($type) or ( $type eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "SUBROUTINES/icmpv6typecode - print ICMPv6 type and code for given number"
        );
    }

    if ( ( caller(1) )[3] !~ __PACKAGE__ ) {
        if ( ( $type !~ /^\d+$/ ) or ( !defined $TYPE{$type} ) ) {
            PPC::_error( "Not a valid ICMP type - `$type'" );
        }
        if ( defined $code ) {
            if (   ( $code !~ /^\d+$/ )
                or ( ( $code != 0 ) and ( !defined $CODE{"$type:$code"} ) ) ) {
                PPC::_error( "Not a valid ICMP code - `$code' for type `$type'" );
            }
        }
    }

    my @rets;
    my $retType = wantarray;

    if ( !defined $retType ) {
        print "$TYPE{$type}\n";
    }
    push @rets, $TYPE{$type};

    if ( defined $code ) {
        if ( !defined $retType ) {
            print "$CODE{\"$type:$code\"}\n";
        }
        push @rets, $CODE{"$type:$code"};
    }

    if ( !defined $retType ) {
        return;
    } elsif ($retType) {
        return @rets;
    } else {
        return \@rets;
    }
}

# Install visual helper for Net::Frame::Layer::ICMPv6::print
no warnings;
no strict;

*Net::Frame::Layer::ICMPv6::print = sub {
    my $self = shift;

    my $l   = $self->layer;
    my $buf = sprintf "$l: type:%d  code:%d  checksum:0x%04x\n"
      . "$l: [%s]",
      $self->type, $self->code, $self->checksum,
      join ' ', icmpv6typecode( $self->type, $self->code );

    return $buf;
};

1;

__END__

=head1 NAME

ICMPv6TypeCode - ICMPv6 Type and Code

=head1 SYNOPSIS

 use PPC::Plugin::ICMPv6TypeCode;

=head1 DESCRIPTION

ICMPv6 Type and Code provides text representations of the numerical ICMPv6 type 
and code bytes.  It also provides an override for the print() accessor of the 
B<Net::Frame::Layer::ICMPv6> object to include the text representation of the 
ICMPv6 type and code bytes.

=head1 COMMANDS

=head2 ICMPv6TypeCode - provide help

Provides help from the B<PPC> shell.

=head1 SUBROUTINES

=head2 icmpv6typecode - print ICMPv6 type and code for given number

 [$icmpv6typecode =] icmpv6typecode type [ code ]

Print ICMPv6 type / code for a given number(s) - usually found in an ICMPv6 
decode from B<Net::Frame::Simple>.

  ICMPv6: type:128  code:0  checksum:0xb2fd  ...
  ...

Returns reference to an array of type and code.

This also overrides the B<Net::Frame::Layer::ICMPv6> C<print> method, adding 
a line with textual type / code.

  ICMPv6: type:128  code:0  checksum:0xb2fd
  ICMPv6: [Echo Request]

=head1 SEE ALSO

L<Net::Frame::Layer::ICMPv6>

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
