#    IPv4Addr.pm - Perl module to manipulate IPv4 addresses.
#
#    Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
#
#    Copyright (C) 1999, 2000 iNsu Innovations Inc.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms as perl itself.
#

package Net::IPv4Addr;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

BEGIN {
    require Exporter;
    require AutoLoader;

    @ISA = qw(Exporter AutoLoader);

    @EXPORT = qw();

    %EXPORT_TAGS = (
		    all => [qw{ dec2ipv4 ipv42dec
				ipv4_parse      ipv4_chkip
				ipv4_network    ipv4_broadcast
				ipv4_cidr2msk   ipv4_msk2cidr
				ipv4_in_network ipv4_dflt_netmask
				} ],
		   );

    @EXPORT_OK = qw();

    Exporter::export_ok_tags('all');

    $VERSION = '0.10_1';
}

# Preloaded methods go here.
use Carp;

# Functions to manipulate IPV4 address
my $ip_rgx = "\\d+\\.\\d+\\.\\d+\\.\\d+";

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $maybe_ip = shift;
    my $parser = ipv4_chkip($maybe_ip) or 
        croak __PACKAGE__, "::new -- invalid IPv4 address: $maybe_ip\n";
    my @octets = split /\./, $maybe_ip;
    my $self = \@octets;
    bless $self, $class;
    return $self;
}

sub to_dec {
    return to_int(@_);
}

sub to_int {
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
        return Net::IPv4Addr->new($self)->to_int();
    }
    return unpack N => pack CCCC => split /\./ => (join ".", @$self);
}

sub to_array {
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
        return Net::IPv4Addr->new($self)->to_array();
    }
    return map {sprintf "%02x", $_} @$self;
}

sub to_intarray {
    my $self = shift;
    if (ref $self ne __PACKAGE__) {
        return Net::IPv4Addr->new($self)->to_intarray();
    }
    return @$self;
}

sub to_string_ipv6 {
    my $self = shift;
    if (ref $self eq __PACKAGE__) {
        my $x = sprintf "%02x%02x", @$self[0..1];
        my $y = sprintf "%02x%02x", @$self[2..3];
        return $x . ":" . $y;
    } 
    return Net::IPv4Addr->new($self)->to_string_ipv6();
}

sub to_string_mapped_ipv6 {
    my $self = shift;
    if (ref $self eq __PACKAGE__) {
        return '0:0:0:0:0:ffff:' . join(".", map { sprintf("%i", $_) } @$self);
    } 
    return Net::IPv4Addr->new($self)->to_string_mapped_ipv6();
}

sub to_string_mapped_ipv6_compressed {
    my $self = shift;
    if (ref $self eq __PACKAGE__) {
        return '::ffff:' . join(".", map { sprintf("%i", $_) } @$self);
    } 
    return Net::IPv4Addr->new($self)->to_string_mapped_ipv6_compressed();
}

sub to_string_mapped_ipv6_hex {
    my $self = shift;
    if (ref $self eq __PACKAGE__) {
        my $x = sprintf "%02x%02x", @$self[0..1];
        my $y = sprintf "%02x%02x", @$self[2..3];
        return '0:0:0:0:0:ffff:' . $x . ":" . $y;
    } 
    return Net::IPv4Addr->new($self)->to_string_mapped_ipv6_hex();
}

sub to_string_mapped_ipv6_hex_compressed {
    my $self = shift;
    if (ref $self eq __PACKAGE__) {
        my $x = sprintf "%02x%02x", @$self[0..1];
        my $y = sprintf "%02x%02x", @$self[2..3];
        return '::ffff:' . $x . ":" . $y;
    } 
    return Net::IPv4Addr->new($self)->to_string_mapped_ipv6_hex_compressed();
}

sub dec2ip {
    return int2ipv4(@_);
}

sub dec2ipv4 {
    return int2ipv4(@_);
}

sub int2ip {
    return int2ipv4(@_);
}

sub int2ipv4($) {
    my ($ip) = $_[0];
    return join '.', unpack 'C4', pack 'N', $ip;
}

sub ip2dec {
    return ipv42int(@_);
}

sub ipv42dec {
    return ipv42int(@_);
}

sub ip2int {
    return ipv42int(@_);
}

sub ipv42int($) {
    my ($ip) = $_[0];
    my $int = __PACKAGE__->new($ip);
    return $int->to_dec;
}

# Given an IPv4 address in host, ip/netmask or cidr format
# returns a ip / cidr pair.
sub ipv4_parse($;$) {
  my ($ip,$msk);
  # Called with 2 args, assume first is IP address
  if ( defined $_[1] ) {
    $ip = $_[0];
    $msk= $_[1];
  } else {
    ($ip)  = $_[0] =~ /($ip_rgx)/o;
    ($msk) = $_[0] =~ m!/(.+)!o;
  }

  my $ip4err = $ip; # assignment below overwrites $ip to undef if chkip fails
  # Remove white spaces
  $ip = ipv4_chkip( $ip ) or
    croak __PACKAGE__, ": invalid IPv4 address: ", $ip4err, "\n";
  $msk =~ s/\s//g if defined $msk;

  # Check Netmask to see if it is a CIDR or Network
  if (defined $msk ) {
    if ($msk =~ /^\d{1,2}$/) {
      # Check cidr
      croak __PACKAGE__, ": invalid cidr: ", $msk, "\n"
	if $msk < 0 or $msk > 32;
    } elsif ($msk =~ /^$ip_rgx$/o ) {
      $msk = ipv4_msk2cidr($msk);
    } else {
      croak __PACKAGE__, ": invalid netmask specification: ", $msk, "\n";
    }
  } else {
    # Host
    return $ip;
  }
  wantarray ? ($ip,$msk) : "$ip/$msk";
}

sub ipv4_dflt_netmask($) {
  my ($ip) = ipv4_parse($_[0]);

  my ($b1) = split /\./, $ip;

  return "255.0.0.0"	if $b1 <= 127;
  return "255.255.0.0"	if $b1 <= 191;
  return "255.255.255.0";
}

# Check form a valid IPv4 address.
sub ipv4_chkip($) {
  my ($ip) = $_[0] =~ /($ip_rgx)/o;

  return undef unless $ip;

  # Check that bytes are in range
  for (split /\./, $ip ) {
    return undef if $_ < 0 or $_ > 255;
  }
  return $ip;
}

# Transform a netmask in a CIDR mask length
sub ipv4_msk2cidr($) {
  my $msk = ipv4_chkip( $_[0] )
    or croak __PACKAGE__, ": invalid netmask: ", $_[0], "\n";

  my @bytes = split /\./, $msk;

  my $cidr = 0;
  for (@bytes) {
    my $bits = unpack( "B*", pack( "C", $_ ) );
    $cidr +=  $bits =~ tr /1/1/;
  }
  return $cidr;
}

# Transform a CIDR mask length in a netmask
sub ipv4_cidr2msk($) {
  my $cidr = shift;
  croak __PACKAGE__, ": invalid cidr: ", $cidr, "\n"
    if $cidr < 0 or $cidr > 32;

  my $bits = "1" x $cidr . "0" x (32 - $cidr);

  return join ".", (unpack 'CCCC', pack("B*", $bits ));
}

# Return the network address of
# an IPv4 address
sub ipv4_network($;$) {
  my ($ip,$cidr) = ipv4_parse( $_[0], $_[1] );

  # If only an host is given, use the default netmask
  unless (defined $cidr) {
    $cidr = ipv4_msk2cidr( ipv4_dflt_netmask($ip) );
  }
  my $u32 = unpack "N", pack "CCCC", split /\./, $ip;
  my $bits = "1" x $cidr . "0" x (32 - $cidr );

  my $msk = unpack "N", pack "B*", $bits;

  my $net = join ".", unpack "CCCC", pack "N", $u32 & $msk;

  wantarray ? ( $net, $cidr) : "$net/$cidr";
}

sub ipv4_broadcast($;$) {
  my ($ip,$cidr) = ipv4_parse( $_[0], $_[1] );

  # If only an host is given, use the default netmask
  unless (defined $cidr) {
    $cidr = ipv4_msk2cidr( ipv4_dflt_netmask($ip) );
  }

  my $u32 = unpack "N", pack "CCCC", split /\./, $ip;
  my $bits = "1" x $cidr . "0" x (32 - $cidr );

  my $msk = unpack "N", pack "B*", $bits;

  my $broadcast = join ".", unpack "CCCC", pack "N", $u32 | ~$msk;

  $broadcast;
}

sub ipv4_in_network($$;$$) {
  my ($ip1,$cidr1,$ip2,$cidr2);
  if ( @_ >= 3) {
    ($ip1,$cidr1) = ipv4_parse( $_[0], $_[1] );
    ($ip2,$cidr2) = ipv4_parse( $_[2], $_[3] );
  } else {
    ($ip1,$cidr1) = ipv4_parse( $_[0]);
    ($ip2,$cidr2) = ipv4_parse( $_[1]);
  }

  # Check for magic addresses.
  return 1 if ($ip1 eq "255.255.255.255" or $ip1 eq "0.0.0.0")
         and !defined $cidr1;
  return 1 if ($ip2 eq "255.255.255.255" or $ip2 eq "0.0.0.0")
         and !defined $cidr2;

  # Case where first argument is really an host
  return $ip1 eq $ip2 unless (defined $cidr1);

  # Case where second argument is an host
  if ( not defined $cidr2) {
      return ipv4_network( $ip1, $cidr1) eq ipv4_network( $ip2, $cidr1 );
  } elsif ( $cidr2 >= $cidr1 ) {
      # Network 2 is smaller or equal than network 1
      return ipv4_network( $ip1, $cidr1 ) eq ipv4_network( $ip2, $cidr1 );
  } else {
      # Network 2 is bigger, so can't be wholly contained.
      return 0;
  }
}
# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!
=pod

=head1 NAME

Net::IPv4Addr - Perl extension for manipulating IPv4 addresses.

=head1 SYNOPSIS

  use Net::IPv4Addr qw( :all );

  my ($ip,$cidr) = ipv4_parse( "127.0.0.1/24" );
  my ($ip,$cidr) = ipv4_parse( "192.168.100.10 / 255.255.255.0" );

  my ($net,$msk) = ipv4_network( "192.168.100.30" );

  my $broadcast  = ipv4_broadcast( "192.168.100.30/26" );

  if ( ipv4_in_network( "192.168.100.0", $her_ip ) ) {
    print "Welcome !";
  }

  etc.

=head1 DESCRIPTION

Net::IPv4Addr provides functions for parsing IPv4 addresses both
in traditional address/netmask format and in the new CIDR format.
There are also methods for calculating the network and broadcast 
address and also to see check if a given address is in a specific
network.

=head1 ADDRESSES

All of Net::IPv4Addr functions accepts addresses in many
format. The parsing is very liberal.

All these addresses would be accepted:

    127.0.0.1
    192.168.001.010/24
    192.168.10.10/255.255.255.0
    192.168.30.10 / 21
    10.0.0.0 / 255.0.0.0
    255.255.0.0

Those wouldn't though:

    272.135.234.0
    192.168/16

Most functions accepts the address and netmask or masklength in the
same scalar value or as separate values. That is either

    my($ip,$masklength) = ipv4_parse($cidr_str);
    my($ip,$masklength) = ipv4_parse($ip_str,$msk_str);

=head1 USING

No functions are exported by default. Either use the C<:all> tag 
to import them all or explicitly import those you need.

=head1 METHODS

=over

=item new

    my $addr = Net::IPv4Addr->new($ip_str);

Create Net::IPv4Addr object.  Croak if error.

=item to_int

    print $addr->to_int;

Return an integer representation corresponding to IPv4 address in $addr.

Alias:

=over 4

=item B<to_dec>

=back

=item to_array

    @hexOctets = $addr->to_array;

Return an array [0..3] of 8-bit hexadecimal numbers corresponding to 
IPv4 address in $addr.

=item to_intarray

    @intOctets = $addr->to_intarray;

Return an array [0..3] of decimal numbers corresponding to 
IPv4 address in $addr.

=item to_string_ipv6

    print $addr->to_string_ipv6;

Return a string in format wwxx:yyzz where w, x, y, z are 8-bit hexadecimal 
numbers corresponding to IPv4 address in $addr. 

=item to_string_mapped_ipv6

    print $addr->to_string_mapped_ipv6;

Return a string in format 0:0:0:0:0:ffff.w.x.y.z where w, x, y, z are decimal 
numbers corresponding to IPv4 address in $addr. 

=item to_string_mapped_ipv6_compressed;

    print $addr->to_string_mapped_ipv6_compressed;

Return a string in format ::ffff.w.x.y.z where w, x, y, z are decimal 
numbers corresponding to IPv4 address in $addr. 

=item to_string_mapped_ipv6_hex;

    print $addr->to_string_mapped_ipv6_hex;

Return a string in format 0:0:0:0:0:ffff.wwxx:yyzz where w, x, y, z are 8-bit 
hexadecimal numbers corresponding to IPv4 address in $addr. 

=item to_string_mapped_ipv6_hex_compressed;

    print $addr->to_string_mapped_ipv6_hex_compressed;

Return a string in format ::ffff.wwxx:yyzz where w, x, y, z are 8-bit 
hexadecimal numbers corresponding to IPv4 address in $addr. 

=back

=head1 FUNCTIONS

=over

=item int2ipv4

    print int2ipv4($num);

Return IPv4 address from provided integer number.

Alias:

=over 4

=item B<int2ip>

=item B<dec2ip>

=item B<dec2ipv4>

=back

=item ipv42int

    print ipv42int('a.b.c.d');

Return integer equivalent of IPv4 address provided.

Alias:

=over 4

=item B<ip2int>

=item B<ip2dec>

=item B<ipv42dec>

=back

=item ipv4_parse

    my ($ip,$msklen) = ipv4_parse($cidr_str);
    my $cidr = ipv4_parse($ip_str,$msk_str);
    my ($ip) = ipv4_parse($ip_str,$msk_str);

Parse an IPv4 address and in scalar context the address in CIDR
format and in an array context the address and the mask length.

If the parameters doesn't contains a netmask or a mask length, 
in scalar context only the IPv4 address is returned and in an 
array context the mask length is undefined.

If the function cannot parse its input, it croaks. Trap it using
C<eval> if don't like that.

=item ipv4_network

    my $cidr = ipv4_network($ip_str);
    my $cidr = ipv4_network($cidr_str);
    my ($net,$msk) = ipv4_network( $net_str, $msk_str);

In scalar context, this function returns the network in CIDR format in
which the address is. In array context, it returns the network address and
its mask length as a two elements array. If the input is an host without
a netmask of mask length, the default netmask is assumed.

Again, the function croak if the input is invalid.

=item ipv4_broadcast

    my ($broadcast) = ipv4_broadcast($ip_str);
    my $broadcast   = ipv4_broadcast($ip_str,$msk_str);

This function returns the broadcast address. If the input doesn't
contains a netmask or mask length, the default netmask is assumed.

This function croaks if the input is invalid.

=item ipv4_in_network

    print "Yes" if ipv4_in_network( $cidr_str1, $cidr_str2);
    print "Yes" if ipv4_in_network( $ip_str1, $mask_str1, $cidr_str2 );
    print "Yes" if ipv4_in_network( $ip1, $mask1, $ip2, $msk2 );

This function checks if the second network is contained in
the first one and it implements the following semantics :

   If net1 or net2 is a magic address (0.0.0.0 or 255.255.255.255)
   than this function returns true.

   If net1 is an host, net2 will be in the same net only if
   it is the same host.

   If net2 is an host, it will be contained in net1 only if
   it is part of net1.

   If net2 is only part of net1 if it is entirely contained in
   net1.

Trap bad input with C<eval> or else.

=item ipv4_chkip

    if ($ip = ipv4_chkip($str) ) {
	# Do something
    }

Return the IPv4 address in the string or undef if the input 
doesn't contains a valid IPv4 address.

=item ipv4_dflt_netmask

    my $netmask = ipv4_dflt_netmask( $str );

Returns the netmask corresponding to IPv4 address in the string based 
on IPv4 classful assignments.  As usual, croaks if it doesn't like your 
input (in this an invalid IPv4 address).

=item ipv4_cidr2msk

    my $netmask = ipv4_cidr2msk( $cidr );

Returns the netmask corresponding to the mask length given in input. 
As usual, croaks if it doesn't like your input (in this case a number
between 0 and 32).

=item ipv4_msk2cidr

    my $masklen = ipv4_msk2cidr( $msk );

Returns the mask length of the netmask in input. As usual, croaks if it
doesn't like your input.

=back

=head1 AUTHOR

Francis J. Lacoste <francis.lacoste@iNsu.COM>

=head1 COPYRIGHT

Copyright (c) 1999, 2000 iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms as perl itself.

=head1 SEE ALSO

perl(1) ipv4calc(1).

=cut

