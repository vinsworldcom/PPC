package PPC::Plugin::TCPFlags;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

use Net::Frame::Layer::TCP qw( :consts );

use Exporter;

our @EXPORT = qw(
  TCPFlags
  tcpflags
);

our @ISA = qw ( PPC Exporter );

sub TCPFlags {
    PPC::_help_full( __PACKAGE__ );
}

########################################################

sub tcpflags {
    my ($arg) = @_;

    if ( !defined($arg) or ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "SUBROUTINES/tcpflags - print TCP flags for given number" );
    }

    if ( ( $arg !~ /^\d+$/ ) or ( ( $arg > 255 ) or ( $arg < 0 ) ) ) {
        PPC::_error( "Not a valid TCP flag number - `$arg'" );
    }

    my @rets;
    my $retType = wantarray;

    if ( $arg & NF_TCP_FLAGS_CWR ) {
        if ( !defined($retType) ) {
            print "CWR ";
        }
        push @rets, "CWR";
    }
    if ( $arg & NF_TCP_FLAGS_ECE ) {
        if ( !defined($retType) ) {
            print "ECE ";
        }
        push @rets, "ECE";
    }
    if ( $arg & NF_TCP_FLAGS_URG ) {
        if ( !defined($retType) ) {
            print "URG ";
        }
        push @rets, "URG";
    }
    if ( $arg & NF_TCP_FLAGS_ACK ) {
        if ( !defined($retType) ) {
            print "ACK ";
        }
        push @rets, "ACK";
    }
    if ( $arg & NF_TCP_FLAGS_PSH ) {
        if ( !defined($retType) ) {
            print "PSH ";
        }
        push @rets, "PSH";
    }
    if ( $arg & NF_TCP_FLAGS_RST ) {
        if ( !defined($retType) ) {
            print "RST ";
        }
        push @rets, "RST";
    }
    if ( $arg & NF_TCP_FLAGS_SYN ) {
        if ( !defined($retType) ) {
            print "SYN ";
        }
        push @rets, "SYN";
    }
    if ( $arg & NF_TCP_FLAGS_FIN ) {
        if ( !defined($retType) ) {
            print "FIN ";
        }
        push @rets, "FIN";
    }

    if ( !defined $retType ) {
        print "\n";
        return;
    } elsif ($retType) {
        return @rets;
    } else {
        return \@rets;
    }
}

# Install visual helper for Net::Frame::Layer::TCP::print
no warnings;
no strict;

*Net::Frame::Layer::TCP::print = sub {
    my $self = shift;

    my $l = $self->layer;
    my $buf
      = sprintf "$l: src:%d  dst:%d  seq:0x%04x  ack:0x%04x\n"
      . "$l: off:0x%02x  x2:0x%01x  flags:0x%02x  win:%d  checksum:0x%04x  urp:0x%02x\n"
      . "$l: [flags:%s]",
      $self->src, $self->dst, $self->seq, $self->ack,
      $self->off, $self->x2, $self->flags, $self->win, $self->checksum,
      $self->urp,
      join ' ', tcpflags $self->flags;

    if ( $self->options ) {
        $buf .= sprintf( "\n$l: optionsLength:%d  options:%s",
            $self->getOptionsLength, CORE::unpack( 'H*', $self->options ) )
          or return undef;
    }

    $buf;
};

1;

__END__

=head1 NAME

TCPFlags - TCP Flags

=head1 SYNOPSIS

 use PPC::Plugin::TCPFlags;

=head1 DESCRIPTION

TCP Flags provides text representations of the numerical TCP flags byte.  
It also provides an override for the print() accessor of the B<Net::Frame::Layer::TCP> 
object to include the text representation of the TCP flags.

=head1 COMMANDS

=head2 TCPFlags - provide help

Provides help from the B<PPC> shell.

=head1 SUBROUTINES

=head2 tcpflags - print TCP flags for given number

 [$tcpflags =] tcpflags #

Print TCP flags for a given number - usually found in a TCP decode from
B<Net::Frame::Simple>.

  TCP: off:0x08  x2:0x0  flags:0x02  ...
  ...

Returns reference to an array of flag names.

This also overrides the B<Net::Frame::Layer::TCP> C<print> method, adding 
a line with textual flags.

  TCP: src:1024  dst:80  seq:0x0000ffff  ack:0x0000
  TCP: off:0x00  x2:0x0  flags:0xff  win:65535  checksum:0x0000  urp:0x00
  TCP: [flags:CWR ECE URG ACK PSH RST SYN FIN]

=head1 SEE ALSO

L<Net::Frame::Layer::TCP>

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
