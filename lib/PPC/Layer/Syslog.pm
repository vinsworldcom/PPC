package PPC::Layer::Syslog;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

my $minver_Syslog = 1.04;
my $HAVE_Syslog   = 0;
eval "use Net::Frame::Layer::Syslog $minver_Syslog qw( :consts )";
if ( !$@ ) {
    $HAVE_Syslog = 1;
}

use Exporter;

our @EXPORT = qw ( SYSLOG );

our @ISA = qw ( PPC::Layer Exporter );

########################################################

sub SYSLOG {
    my %params;

    if ( !$HAVE_Syslog ) {
        PPC::Layer::_err_not_installed( "Syslog", $minver_Syslog );
    }

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__,
                "COMMANDS/SYSLOG - create Syslog layer",
                "Net::Frame::Layer::Syslog"
            );
        }
        $params{content} = $arg;
    } else {
        my %args = @_;
        for ( keys(%args) ) {
            $params{$_} = $args{$_};
        }
    }

    my $p = PPC::Layer::_layer( "Syslog", %params );
    if ( !defined wantarray ) {
        print $p->print . "\n";
    }
    return $p;
}

1;

package PPC;
eval "use Net::Frame::Layer::Syslog $minver_Syslog qw( :consts )";
1;

__END__

=head1 COMMANDS

=head2 SYSLOG - create Syslog layer

 $syslog = SYSLOG [(Net::Frame::Layer::Syslog options)]

Creates B<$syslog> variable as Syslog layer.  Uses options from
B<Net::Frame::Layer::Syslog>.

Single option indicates content.

=cut
