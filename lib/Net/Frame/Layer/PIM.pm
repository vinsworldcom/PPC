#
# $Id: PIM.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::PIM;
use strict; use warnings;

our $VERSION = '0.01';

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_PIM_ALLPIMRTRS_v4
      NF_PIM_ALLPIMRTRS_v4_MAC
      NF_PIM_ALLPIMRTRS_v6
      NF_PIM_ALLPIMRTRS_v6_MAC
      NF_PIM_VERSION_1
      NF_PIM_VERSION_2
      NF_PIM_TYPE_HELLO
      NF_PIM_TYPE_REGISTER
      NF_PIM_TYPE_REGISTERSTOP
      NF_PIM_TYPE_JOINPRUNE
      NF_PIM_TYPE_BOOTSTRAP
      NF_PIM_TYPE_ASSERT
      NF_PIM_TYPE_GRAFT
      NF_PIM_TYPE_GRAFTACK
      NF_PIM_TYPE_RPADV
      NF_PIM_TYPE_REFRESH
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_PIM_ALLPIMRTRS_v4     => '224.0.0.13';
use constant NF_PIM_ALLPIMRTRS_v4_MAC => '01:00:5e:00:00:0d';
use constant NF_PIM_ALLPIMRTRS_v6     => 'ff02::d';
use constant NF_PIM_ALLPIMRTRS_v6_MAC => '33:33:00:00:00:0d';
use constant NF_PIM_VERSION_1 => 1;
use constant NF_PIM_VERSION_2 => 2;
use constant NF_PIM_TYPE_HELLO        => 0;
use constant NF_PIM_TYPE_REGISTER     => 1;
use constant NF_PIM_TYPE_REGISTERSTOP => 2;
use constant NF_PIM_TYPE_JOINPRUNE    => 3;
use constant NF_PIM_TYPE_BOOTSTRAP    => 4;
use constant NF_PIM_TYPE_ASSERT       => 5;
use constant NF_PIM_TYPE_GRAFT        => 6;
use constant NF_PIM_TYPE_GRAFTACK     => 7;
use constant NF_PIM_TYPE_RPADV        => 8;
use constant NF_PIM_TYPE_REFRESH      => 9;

our @AS = qw(
   version
   type
   reserved
   checksum
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';
use Bit::Vector;

sub new {
   shift->SUPER::new(
      version  => NF_PIM_VERSION_2,
      type     => NF_PIM_TYPE_HELLO,
      reserved => 0,
      checksum => 0,
      @_,
   );
}

sub getLength { 4 }

sub pack {
   my $self = shift;

   my $version = Bit::Vector->new_Dec(4, $self->version);
   my $type    = Bit::Vector->new_Dec(4, $self->type);
   my $bvlist  = $version->Concat_List($type);

   my $raw = $self->SUPER::pack('CCn',
      $bvlist->to_Dec,
      $self->reserved,
      $self->checksum
   ) or return;

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($bv, $reserved, $checksum, $payload) =
      $self->SUPER::unpack('CCn a*', $self->raw)
         or return;

   my $bvlist = Bit::Vector->new_Dec(8, $bv);
   $self->version($bvlist->Chunk_Read(4,4));
   $self->type   ($bvlist->Chunk_Read(4,0));

   $self->reserved($reserved);
   $self->checksum($checksum);

   $self->payload($payload);

   return $self;
}

sub computeChecksums {
   my $self = shift;
   my ($layers) = @_;

   my $phpkt;
   for my $l (@$layers) {
      if ($l->layer eq 'IPv6') {

         my $len = $self->getLength;

         my $start = 0;
         my $last  = $self;
         # Checksum doesn't include data in Register packet
         # (continued below)
         if ($self->type != NF_PIM_TYPE_REGISTER) {
            for my $l (@$layers) {
               $last = $l;
               if (! $start) {
                  $start++ if $l->layer eq 'PIM';
                  next;
               }
               $len += $l->getLength;
            }

            if (defined($last->payload) and length($last->payload)) {
               $len += length($last->payload);
            }
         # Register "header" is only 4 more bytes
         # so $len must reflect that for IPv6 checksum calc
         } else {
            $len += 4
         }

         $phpkt = $self->SUPER::pack('a*a*NnCC',
            inet6Aton($l->src), inet6Aton($l->dst), $len,
            0, 0, 103);
         last;
      }
   }

   my $version = Bit::Vector->new_Dec(4, $self->version);
   my $type    = Bit::Vector->new_Dec(4, $self->type);
   my $bvlist  = $version->Concat_List($type);

   $phpkt .= $self->SUPER::pack('CCn',
      $bvlist->to_Dec, $self->reserved, 0)
         or return;

   my $start   = 0;
   my $last    = $self;
   my $payload = '';
   for my $l (@$layers) {
      $last = $l;
      if (! $start) {
	 $start++ if $l->layer eq 'PIM';
         next;
      }
      $payload .= $l->pack;
   }

   if (defined($last->payload) and length($last->payload)) {
      $payload .= $last->payload;
   }

   if (length($payload)) {
      # Checksum doesn't include data in Register packet
      # Register "header" is only 4 more bytes
      if (($self->type == NF_PIM_TYPE_REGISTER) and (length($payload) > 4)) {
         $phpkt .= $self->SUPER::pack('a*', substr ($payload, 0, 4))
            or return;
      } else {
         $phpkt .= $self->SUPER::pack('a*', $payload)
            or return;
      }
   }

   $self->checksum(inetChecksum($phpkt));

   return 1;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   # if ($self->payload) {
      # if ($self->version == 1) {
         # return 'PIM::v1';
      # } elsif ($self->version == 2) {
         # return 'PIM::v2';
      # }
   # }

   NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: version:%d  type:%d  reserved:%d  checksum:0x%04x",
         $self->version, $self->type, $self->reserved, $self->checksum;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::PIM - Protocol Independent Multicast layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::PIM qw(:consts);

   my $layer = Net::Frame::Layer::PIM->new(
      version  => NF_PIM_VERSION_2,
      type     => NF_PIM_TYPE_HELLO,
      reserved => 0,
      checksum => 0,
   );

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::PIM->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This module implements the encoding and decoding of the PIM layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc2362.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<version>

PIM protocol version: 1 or 2 valid.

=item B<type>

PIM message type.  See B<CONSTANTS> for more information.

=item B<reserved>

Default set to 0.

=item B<checksum>

Message checksum.

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

=item B<computeChecksums>

Computes the PIM checksum.

=back

The following are inherited methods. Some of them may be overriden in this layer, and some others may not be meaningful in this layer. See B<Net::Frame::Layer> for more information.

=over 4

=item B<layer>

=item B<computeLengths>

=item B<pack>

=item B<unpack>

=item B<encapsulate>

=item B<getLength>

=item B<getPayloadLength>

=item B<print>

=item B<dump>

=back

=head1 CONSTANTS

Load them: use Net::Frame::Layer::PIM qw(:consts);

=over 4

=item B<NF_PIM_ALLPIMRTRS_v4_MAC>

=item B<NF_PIM_ALLPIMRTRS_v6_MAC>

Default Layer 2 destination addresses.

=item B<NF_PIM_ALLPIMRTRS_v4>

=item B<NF_PIM_ALLPIMRTRS_v6>

Default Layer 3 destination addresses.

=item B<NF_PIM_VERSION_1>

=item B<NF_PIM_VERSION_2>

PIM protocol versions.

=item B<NF_PIM_TYPE_HELLO>

=item B<NF_PIM_TYPE_REGISTER>

=item B<NF_PIM_TYPE_REGISTERSTOP>

=item B<NF_PIM_TYPE_JOINPRUNE>

=item B<NF_PIM_TYPE_BOOTSTRAP>

=item B<NF_PIM_TYPE_ASSERT>

=item B<NF_PIM_TYPE_GRAFT>

=item B<NF_PIM_TYPE_GRAFTACK>

=item B<NF_PIM_TYPE_RPADV>

=item B<NF_PIM_TYPE_REFRESH>

PIM message types.

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
