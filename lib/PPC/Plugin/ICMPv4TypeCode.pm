package PPC::Plugin::ICMPv4TypeCode;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

use Net::Frame::Layer::ICMPv4 qw(:consts);

use Exporter;

our @EXPORT = qw(
  ICMPv4TypeCode
  icmpv4typecode
);

our @ISA = qw ( PPC Exporter );

my %TYPE = (
    0  => 'Echo Reply',
    3  => 'Destination Unreachable',
    4  => 'Source Quench',
    5  => 'Redirect',
    6  => 'Alternate Host Address',
    8  => 'Echo Request',
    9  => 'Router Advertisement',
    10 => 'Router Solicitation',
    11 => 'Time Exceeded',
    12 => 'Parameter Problem',
    13 => 'Timestamp',
    14 => 'Timestamp Reply',
    15 => 'Information Request',
    16 => 'Information Reply',
    17 => 'Address Mask Request',
    18 => 'Address Mask Reply',
    37 => 'Domain Name Request',
    38 => 'Domain Name Reply',
    40 => 'Photuris'
);

my %CODE = (

    # TYPE:CODE
    '3:0'  => 'Net Unreachable',
    '3:1'  => 'Host Unreachable',
    '3:2'  => 'Protocol Unreachable',
    '3:3'  => 'Port Unreachable',
    '3:4'  => 'Fragmentation Needed (DF Set)',
    '3:5'  => 'Source Route Failed',
    '3:6'  => 'Destination Network Unknown',
    '3:7'  => 'Destination Host Unknown',
    '3:8'  => 'Source Host Isolated',
    '3:9'  => 'Destination Network is Administratively Prohibited',
    '3:10' => 'Destination Host is Administratively Prohibited',
    '3:11' => 'Destination Network Unreachable for ToS',
    '3:12' => 'Destination Host Unreachable for ToS',
    '3:13' => 'Communication Administratively Prohibited',
    '3:14' => 'Host Precedence Violation',
    '3:15' => 'Precedence cutoff in effect',
    '5:0'  => 'Network (or subnet)',
    '5:1'  => 'Host',
    '5:2'  => 'ToS and Network',
    '5:3'  => 'ToS and Host',
    '9:16' => 'Does not route common traffic',
    '11:0' => 'Time to Live exceeded in Transit',
    '11:1' => 'Fragment Reassembly Time Exceeded',
    '12:0' => 'Pointer indicates the error',
    '12:1' => 'Missing a Required Option',
    '12:2' => 'Bad Length',
    '40:0' => 'Bad SPI',
    '40:1' => 'Authentication Failed',
    '40:2' => 'Decompression Failed',
    '40:3' => 'Decryption Failed',
    '40:4' => 'Need Authentication',
    '40:5' => 'Need Authorization'
);

sub ICMPv4TypeCode {
    PPC::_help_full( __PACKAGE__ );
}

########################################################

sub icmpv4typecode {
    my ( $type, $code ) = @_;

    if ( !defined($type) or ( $type eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "SUBROUTINES/icmpv4typecode - print ICMPv4 type and code for given number"
        );
    }

    if ( ( caller(1) )[3] !~ __PACKAGE__ ) {
        if ( ( $type !~ /^\d+$/ ) or ( !defined $TYPE{$type} ) ) {
            PPC::_error( "Not a valid ICMP type - `$type'" );
        }
        if ( defined($code) ) {
            if (   ( $code !~ /^\d+$/ )
                or ( ( $code != 0 ) and ( !defined $CODE{"$type:$code"}  ) ) ) {
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

# Install visual helper for Net::Frame::Layer::ICMPv4::print
no warnings;
no strict;

*Net::Frame::Layer::ICMPv4::print = sub {
    my $self = shift;

    my $l   = $self->layer;
    my $buf = sprintf "$l: type:%d  code:%d  checksum:0x%04x\n"
      . "$l: [%s]",
      $self->type, $self->code, $self->checksum,
      join ' ', icmpv4typecode( $self->type, $self->code );

    return $buf;
};

1;

__END__

=head1 NAME

ICMPv4TypeCode - ICMPv4 Type and Code

=head1 SYNOPSIS

 use PPC::Plugin::ICMPv4TypeCode;

=head1 DESCRIPTION

ICMPv4 Type and Code provides text representations of the numerical ICMPv4 type 
and code bytes.  It also provides an override for the print() accessor of the 
B<Net::Frame::Layer::ICMPv4> object to include the text representation of the 
ICMPv4 type and code bytes.

=head1 COMMANDS

=head2 ICMPv4TypeCode - provide help

Provides help from the B<PPC> shell.

=head1 SUBROUTINES

=head2 icmpv4typecode - print ICMPv4 type and code for given number

 [$icmpv4typecode =] icmpv4typecode type [ code ]

Print ICMPv4 type / code for a given number(s) - usually found in an ICMPv4 
decode from B<Net::Frame::Simple>.

  ICMPv4: type:8  code:0  checksum:0xb2fd  ...
  ...

Returns reference to an array of type and code.

This also overrides the B<Net::Frame::Layer::ICMPv4> C<print> method, adding 
a line with textual type / code.

  ICMPv4: type:8  code:0  checksum:0xb2fd
  ICMPv4: [Echo Request]

=head1 SEE ALSO

L<Net::Frame::Layer::ICMPv4>

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
