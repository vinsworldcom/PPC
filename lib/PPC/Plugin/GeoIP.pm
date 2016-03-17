package PPC::Plugin::GeoIP;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

eval "use Geo::IP";
if ($@) {
    print "Geo::IP required.\n";
    return 1;
}

use Exporter;

our @EXPORT = qw(
  GeoIP
  geoip
);

our @ISA = qw ( PPC Exporter );

# Set gnuplot global config
my $base = '/usr/local/share/GeoIP/';
$PPC::PPC_GLOBALS->add( 'geoipdat'     => $base . 'GeoIP.dat' );
$PPC::PPC_GLOBALS->add( 'geoipcitydat' => $base . 'GeoIPCity.dat' );

sub GeoIP {
    PPC::_help_full( __PACKAGE__ );
}

########################################################

sub geoip {
    my ($arg) = shift;

    if ( defined $arg ) {
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__,
                "COMMANDS/geoip - geo locate IPv4 address" );
        }

        # WARN - Net::IPv4Addr bug sends undefined to Carp
        # DIE  - Net::IPv4Addr croaks on error, I prefer to handle nicely
        local $SIG{__WARN__} = sub { return; };
        local $SIG{__DIE__}  = sub { return; };

        my $addr;
        eval { $addr = Net::IPv4Addr::ipv4_parse($arg); };

        if ( defined $addr ) {

            my $gi = Geo::IP->open( PPC::config( 'geoipcitydat' ), );
            my $r = $gi->record_by_name( $arg );
            if ( $r ) {
                if ( !defined wantarray ) {
                    print join(
                        "\t",
                        $r->country_code, $r->country_name, $r->city,
                        $r->region,       $r->region_name,  $r->postal_code,
                        $r->latitude,     $r->longitude,    $r->metro_code,
                        $r->area_code
                    );
                } else {
                    return $r;
                }
            } else {
                ( !defined wantarray ) ? print "Not found\n" : return undef;
            }
        } else {
            PPC::_error("Not an IPv4 address: `$arg'");
        }
    } else {
        PPC::_help( __PACKAGE__,
            "COMMANDS/geoip - geo locate IPv4 address" );
    }
}

1;

__END__

=head1 NAME

GeoIP - Geo IP Location

=head1 SYNOPSIS

 use PPC::Plugin::GeoIP;

=head1 DESCRIPTION

This module implements GeoIP integration with L<Geo::IP>.

=head1 COMMANDS

=head2 GeoIP - provide help

Provides help from the B<PPC> shell.

=head2 geoip - geo locate IPv4 address

 [$loc =] geoip $ipv4;

Return a B<Geo::IP::Record> object containing city location for provided IP 
address.

=head1 SEE ALSO

L<Geo::IP>

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
