package PPC::Plugin;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

my $HAVE_NFL_IPv6 = 0;
eval "use Net::Frame::Layer::IPv6 qw( :consts )";
if ( !$@ ) {
    $HAVE_NFL_IPv6 = 1;
}

########################################################

sub group {
    my ( $self, $arg ) = @_;

    if ( defined($arg) and ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "ACCESSORS/group - return SRP object of group number" );
    }

    my @rets;
    my $retType = wantarray;

    if ( defined $arg ) {
        if ( $arg =~ /^\d+$/ ) {
            if ( ( $arg > 0 ) and defined( $self->[$arg - 1] ) ) {
                if ( defined $retType ) {
                    return $self->[$arg - 1];
                } else {
                    print $self->[$arg - 1] . "\n";
                }
            } else {
                if ( !defined $retType ) {
                    _errorNVGN( $arg );
                }
                return;
            }
        } else {
            if ( !defined $retType ) {
                _errorNAN( $arg );
            }
            return;
        }
    } else {
        my $c = 1;
        for my $i ( 0 .. $#{$self} ) {
            if ( defined($retType) ) {
                push @rets, $self->[$i];
            } else {
                printf "%3i: %s\n", $c, $self->[$i];
            }
            $c++;
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

sub list {
    my ( $self, $arg ) = @_;

    if ( defined($arg) and ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "ACCESSORS/list - return list of all sent and recv packets" );
    }

    my @rets;
    my $retType = wantarray;

    for my $i ( 0 .. $#{$self} ) {
        if ( defined $retType ) {
            push @rets, $self->[$i]->list;
        } else {
            for ( @{$self->[$i]->list} ) {
                print "$_\n";
            }
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

sub listr {
    return listrecv(@_);
}

sub listrecv {
    my ( $self, $arg ) = @_;

    if ( defined($arg) and ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "ACCESSORS/listrecv - return list of all received packets" );
    }

    my @rets;
    my $retType = wantarray;

    for my $i ( 0 .. $#{$self} ) {
        for ( @{$self->[$i]->recv} ) {
            if ( defined $retType ) {
                push @rets, $_;
            } else {
                print "$_\n";
            }
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

sub lists {
    return listsent(@_);
}

sub listsent {
    my ( $self, $arg ) = @_;

    if ( defined($arg) and ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "ACCESSORS/listsent - return list of all sent packets" );
    }

    my @rets;
    my $retType = wantarray;

    for my $i ( 0 .. $#{$self} ) {
        for ( @{$self->[$i]->sent} ) {
            if ( defined $retType ) {
                push @rets, $_;
            } else {
                print "$_\n";
            }
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

sub listt {
    return listtime(@_);
}

sub listtime {
    my ( $self, $arg ) = @_;

    if ( defined($arg) and ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__,
            "ACCESSORS/listtime - return list of all time intervals" );
    }

    my @rets;
    my $retType = wantarray;

    for my $i ( 0 .. $#{$self} ) {
        for ( @{$self->[$i]->time} ) {
            if ( defined $retType ) {
                push @rets, $_;
            } else {
                print "$_\n";
            }
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

sub recv {
    my ( $self, $arg, $arg2 ) = @_;

    if ( defined($arg) and ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__, "ACCESSORS/recv - return recv packets" );
    }

    my @rets;
    my $retType = wantarray;

    if ( defined $arg ) {
        if ( $arg =~ /^\d+$/ ) {
            if ( ( $arg > 0 ) and ( $arg <= $#{$self} + 1 ) ) {
                my $ret;
                if ( defined $arg2 ) {
                    $ret = $self->[$arg - 1]->recv->[$arg2 - 1];
                } else {
                    $ret = $self->[$arg - 1]->recv->[0];
                }
                if ( defined $retType ) {
                    return $ret;
                } else {
                    if ( defined $ret ) {
                        printf "$ret\n";
                    } else {
                        my $msg = "$arg";
                        $msg .= ( defined $arg2 ) ? ",$arg2" : '';
                        PPC::_error( "No recv packet for - `$msg'" );
                    }
                }
            } else {
                if ( !defined $retType ) {
                    _errorNVGN( $arg );
                }
                return;
            }
        } else {
            if ( !defined $retType ) {
                _errorNAN( $arg );
            }
            return;
        }
    } else {
        my $c = 0;
        for my $i ( 0 .. $#{$self} ) {

            # needed to preserve array order if sent and no recv
            for my $j ( 0 .. $#{$self->[$i]} ) {
                if ( defined $retType ) {
                    push @rets, $self->[$i]->recv->[$j];
                } else {
                    printf "%-4s %3i,%-3i: ", "[" . $c++ . "]", $i + 1,
                      $j + 1;
                    if ( defined $self->[$i]->recv->[$j] ) {
                        print $self->[$i]->recv->[$j] . "\n",;
                    } else {
                        print "No recv packet\n";
                    }
                }
            }
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

sub sent {
    my ( $self, $arg, $arg2 ) = @_;

    if ( defined($arg) and ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__, "ACCESSORS/sent - return sent packets" );
    }

    my @rets;
    my $retType = wantarray;

    if ( defined $arg ) {
        if ( $arg =~ /^\d+$/ ) {
            if ( ( $arg > 0 ) and ( $arg <= $#{$self} + 1 ) ) {
                my $ret;
                if ( defined $arg2 ) {
                    $ret = $self->[$arg - 1]->sent->[$arg2 - 1];
                } else {
                    $ret = $self->[$arg - 1]->sent->[0];
                }
                if ( defined($retType) ) {
                    return $ret;
                } else {
                    if ( defined $ret ) {
                        printf "$ret\n";
                    } else {
                        my $msg = "$arg";
                        $msg .= ( defined $arg2 ) ? ",$arg2" : '';
                        PPC::_error( "No sent packet for - `$msg'" );
                    }
                }
            } else {
                if ( !defined $retType ) {
                    _errorNVGN( $arg );
                }
                return;
            }
        } else {
            if ( !defined $retType ) {
                _errorNAN( $arg );
            }
            return;
        }
    } else {
        my $c = 0;
        for my $i ( 0 .. $#{$self} ) {

            # NOT needed here to preserve array order if sent and no recv but kept for consistency
            for my $j ( 0 .. $#{$self->[$i]} ) {
                if ( defined $retType ) {
                    push @rets, $self->[$i]->sent->[$j];
                } else {
                    printf "%-4s %3i,%-3i: ", "[" . $c++ . "]", $i + 1,
                      $j + 1;
                    print $self->[$i]->sent->[$j] . "\n";
                }
            }
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

sub time {
    my ( $self, $arg, $arg2 ) = @_;

    if ( defined($arg) and ( $arg eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__, "ACCESSORS/time - return time intervals" );
    }

    my @rets;
    my $retType = wantarray;

    if ( defined $arg ) {
        if ( $arg =~ /^\d+$/ ) {
            if ( ( $arg > 0 ) and ( $arg <= $#{$self} + 1 ) ) {
                my $ret;
                if ( defined $arg2 ) {
                    $ret = $self->[$arg - 1]->time->[$arg2 - 1];
                } else {
                    $ret = $self->[$arg - 1]->time->[0];
                }
                if ( defined $retType ) {
                    return $ret;
                } else {
                    if ( defined $ret ) {
                        printf "$ret\n";
                    } else {
                        my $msg = "$arg";
                        $msg .= ( defined $arg2 ) ? ",$arg2" : '';
                        PPC::_error( "No time interval for - `$msg'" );
                    }
                }
            } else {
                if ( !defined $retType ) {
                    _errorNVGN( $arg );
                }
                return;
            }
        } else {
            if ( !defined $retType ) {
                _errorNAN( $arg );
            }
            return;
        }
    } else {
        my $c = 0;
        for my $i ( 0 .. $#{$self} ) {

            # needed to preserve array order if sent and no recv
            for my $j ( 0 .. $#{$self->[$i]} ) {
                if ( defined $retType ) {
                    push @rets, $self->[$i]->time->[$j];
                } else {
                    printf "%-4s %3i,%-3i: ", "[" . $c++ . "]", $i + 1,
                      $j + 1;
                    if (    defined( $self->[$i]->sent->[$j] )
                        and defined( $self->[$i]->recv->[$j] ) ) {
                        print $self->[$i]->time->[$j] . "\n",;
                    } else {
                        print "No time interval\n";
                    }
                }
            }
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

sub report {
    my ( $self, @args ) = @_;

    my %params = ( file => '' );

    if ( @args == 1 ) {
        my ($arg) = @args;
        if ( $arg eq PPC::config('help_cmd') ) {
            PPC::_help( __PACKAGE__, "ACCESSORS/report - summary report" );
        }
        ( $params{'file'} ) = $arg;
    } else {
        if ( ( @args % 2 ) == 1 ) {
            $params{'file'} = shift @args;
        }
        my %args = @args;
        for ( keys(%args) ) {
            if (/^-?file$/i) {
                $params{'file'} = $args{$_};
            } else {
                PPC::_error( "Unknown parameter: `$_'" );
            }
        }
    }

    my $OUT;
    if ( $params{'file'} eq '' ) {
        $OUT = \*STDOUT;
    } else {
        if ( ref $params{'file'} eq 'GLOB' ) {
            $OUT = $params{'file'};
        } else {
            if ( !( open( $OUT, '>', "$params{file}" ) ) ) {
                PPC::_error( "Cannot open file - `$params{file}'" );
            }
        }
    }

    for my $i ( 0 .. $#{$self} ) {
        printf $OUT "Group %i\n----------\n", $i + 1;
        $self->[$i]->report($OUT);
    }

    if ( $params{'file'} ne '' ) {
        if ( ref $params{'file'} ne 'GLOB' ) {
            close $OUT;
        }
    }
}

sub _errorNAN {
    my ( $arg ) = @_;
    PPC::_error( "Not a valid number - `$arg'" );
}

sub _errorNVGN {
    my ( $arg ) = @_;
    PPC::_error( "Not a valid group number - `$arg'" );
}

sub _validate_family {
    my ($arg) = @_;
    if ( $arg =~ /^(?:(?:(:?ip)?v?(?:4|6)))$/i ) {
        if ( $arg =~ /^(?:(?:(:?ip)?v?4))$/i ) {
            return 4;
        } else {
            if ($HAVE_NFL_IPv6) {
                return 6;
            } else {
                PPC::_error( "Net::Frame::Layer::IPv6 required for IPv6" );
            }
        }
    }
    return;
}

1;

__END__

=head1 NAME

Plugin - Plugin Routines

=head1 SYNOPSIS

 use PPC::Plugin;

=head1 DESCRIPTION

This module provides the common routines for B<PPC::Plugin> modules that 
use B<PPC::Packet::SRP> to send and receive packets in groups.

The return structure is:

  GROUP(1) -> SENT(1) -> [RECV(1)]
  GROUP(1) -> SENT(2) -> [RECV(1)]
  GROUP(2) -> SENT(1) -> [RECV(1)]
  GROUP(2) -> SENT(2) -> [RECV(1)]
  GROUP(3) -> SENT(1) -> [RECV(1)]
  ...

That is, results are grouped (see B<group>) each of which contains a 
B<PPC::Packet::SRP> object, which itself is a structure containing a 
number of sent packets each with an optional receive packet, if one was 
received for that particular sent.

Any plugins can be written to utilize these accessors or not at all.  Any 
plugins should be stored in the PPC/Plugin directory.  They can be invoked 
from the B<PPC> shell with:

  use PPC::Plugin::PluginName

where 'PluginName' is the name of the plugin (filename is 'PluginName.pm' and 
first line of file is 'package PPC::Plugin::PluginName).  See files in the 
PPC/Plugin directory for examples.

=head1 ACCESSORS

=head2 group - return SRP object of group number

 [$group =] $ppcplugin->group(#)

Return B<PPC::Packet::SRP> object of group number.  No argument lists all 
groups.

=head2 list - return list of all sent and recv packets

 [@list =] $ppcplugin->list

Return array of all packets B<PPC::Packet> objects resultant.  The list 
is ordered in the order sent and received.  If any packets weren't received, 
they are skipped.  There will be no undefined values in the returned array.

=head2 listrecv - return list of all received packets

 [@list =] $ppcplugin->listrecv

Return array of all received packets B<PPC::Packet> objects resultant.  
The list is ordered in the order received.  If any packets weren't received, 
they are skipped.  There will be no undefined values in the returned array.

Alias:

=over 4

=item B<listr>

=back

=head2 listsent - return list of all sent packets

 [@list =] $ppcplugin->listsent

Return array of all sent packets B<PPC::Packet> objects resultant.  
The list is ordered in the order sent.  There will be no undefined values in 
the returned array.

Alias:

=over 4

=item B<lists>

=back

=head2 listtime - return list of all time intervals

 [@list =] $ppcplugin->listtime

Return array of all time intervals between sent and received packets 
B<PPC::Packet> objects resultant.  The list is ordered in the 
order sent and received.  If any packets weren't received, the time 
interval is not provided and skipped.  There will be no undefined values 
in the returned array.

Alias:

=over 4

=item B<listt>

=back

=head2 recv - return recv packets

 [@recv =] $ppcplugin->recv([# [, #]])

Return array of all recv B<PPC::Packet> objects.  Optional 
number returns only that group's object.  Groups are numbered 1 .. {last group}.  
If B<count> option was used when command was called, second optional number 
specifies the count within the group.  If any packets weren't received, 
undefined is pushed to the array position.  This preserves the intended order 
indicating where packets may be missing.  There may be undefined values in 
the return array.

=head2 sent - return sent packets

 [@sent =] $ppcplugin->sent([# [, #]])

Return array of all sent B<PPC::Packet> objects.  Optional 
number returns only that group's object.  Groups are numbered 1 .. {last group}.  
If B<count> option was used when command was called, second optional number 
specifies the count within the group.  This preserves the intended order 
indicating where packets may be missing.  There may be undefined values in 
the return array.

=head2 time - return time intervals

 [$time =] $ppcplugin->time([# [, #]]) # or 
 [@time =] $ppcplugin->time([# [, #]])

Return array of all time intervals resultant.  Optional 
number returns only that group's time interval.  Groups are numbered 1 .. {last group}.  
If B<count> option was used when command was called, second optional number 
specifies the count within the group.  If any packets weren't received, 
undefined is pushed to the array position for that time interval.  This 
preserves the intended order indicating where packets may be missing.  There 
may be undefined values in the return array.

=head2 report - summary report

 $ppcplugin->report([OPTIONS])

Print summary report of all sent/received packets and timestamps.

  Option     Description                       Default Value
  ------     -----------                       -------------
  file       Output file name or handle        (none - STDOUT)

Single option indicates file.

=head1 EXAMPLES

To access any item from any B<Net::Frame> module from a B<PPC::Plugin> return, 
you can use the following:

  $ppcplugin = [COMMAND ...]
  print map { [$_->sent(1)->layers]->[1]->ttl } $ppcplugin->group;

Where B<sent> can be B<recv> for received packets.  Layers are specified as the 
array reference where:

  0 = ETH
  1 = IP(v4/v6)
  2 = TCP/UDP/ICMP(v6)
  etc.

The next reference is the field in question.

=head1 SEE ALSO

L<PPC::Packet::SRP>

=head1 ACKNOWLEDGEMENTS

Special thanks to Patrice E<lt>GomoRE<gt> Auffret without whose
Net::Frame::[...] modules, this would not be possible.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2012, 2016 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
