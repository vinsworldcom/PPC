#
# $Id: Option.pm 35 2012-11-10 15:28:09Z gomor $
#
package Net::Frame::Layer::ICMPv6::Option;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   type
   length
   value
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';

sub new {
   shift->SUPER::new(
      type   => 0,
      length => 0,
      value  => '',
      @_,
   );
}

sub getLength {
   my $self = shift;

   return length($self->value) + 2;
}

sub pack {
   my $self = shift;

   $self->raw($self->SUPER::pack('CCa*',
      $self->type, $self->length, $self->value,
   )) or return;

   return $self->raw;
}

sub unpack {
   my $self = shift;

   my ($type, $length, $tail) = $self->SUPER::unpack('CC a*', $self->raw)
      or return;

   my $len = ($length*8)-2;
   my ($value, $payload) = $self->SUPER::unpack("a$len a*", $tail)
      or return;

   $self->type($type);
   $self->length($length);
   $self->value($value);

   $self->payload($payload);

   return $self;
}

sub computeLengths {
   my $self = shift;

   my $length = int($self->getLength/8);
   $self->length($length);

   return 1;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   sprintf "$l: type:%02x  length:%02x  value:%s",
      $self->type, $self->length, CORE::unpack('H*', $self->value);
}

1;

__END__

=head1 NAME

Net::Frame::Layer::ICMPv6::Option - ICMPv6 Option object

=head1 SYNOPSIS

   use Net::Frame::Layer::ICMPv6::Option;

   my $layer = Net::Frame::Layer::ICMPv6::Option->new(
      type   => 0,
      length => 0,
      value  => '',
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::ICMPv6::Option->new(
      raw => $raw,
   );

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This module implements the encoding and decoding of ICMPv6 Options.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<type>

The type of ICMPv6 option.

=item B<length>

The length of ICMPv6 option (a number of bytes), including B<type> and B<length> fields.

=item B<value>

The value.

=back

The following are inherited attributes. See B<Net::Frame::Layer> for more information.

=over 4

=item B<raw>

=item B<payload>

=item B<nextLayer>

=back

=head1 METHODS

=over 4

=item B<new>

=item B<new> (hash)

Object constructor. You can pass attributes that will overwrite default ones. See B<SYNOPSIS> for default values.

=back

The following are inherited methods. Some of them may be overriden in this layer, and some others may not be meaningful in this layer. See B<Net::Frame::Layer> for more information.

=over 4

=item B<layer>

=item B<computeLengths>

=item B<computeChecksums>

=item B<pack>

=item B<unpack>

=item B<encapsulate>

=item B<getLength>

=item B<getPayloadLength>

=item B<print>

=item B<dump>

=back

=head1 CONSTANTS

No constants here.

=head1 SEE ALSO

L<Net::Frame::Layer::ICMPv6>, L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2012, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
