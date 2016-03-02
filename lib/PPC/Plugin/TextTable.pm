package PPC::Plugin::TextTable;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;

eval "use Text::Table";
if ($@) {
    print "Text::Table required.\n";
    return 1;
}
eval "use Array::Transpose";
if ($@) {
    print "Array::Transpose required.\n";
    return 1;
}

use Exporter;

our @EXPORT = qw(
  TextTable
  texttable
  rows
  cols
);

our @ISA = qw ( Text::Table Exporter );

sub TextTable {
    PPC::_help_full(__PACKAGE__);
}

########################################################

sub texttable {
    my @params;

    if ( @_ == 1 ) {
        my ($arg) = @_;
        if ( $arg eq (PPC::config('help_cmd')) ) {
            PPC::_help( __PACKAGE__, "METHODS/table - create table object",
                "Text::Table" );
        }
        push @params, $arg;
    } else {
        for (@_) {
            push @params, $_;
        }
    }

    my $table = Text::Table->new(@params);

    return bless $table, __PACKAGE__;
}

sub rows {
    my ( $self, @arg ) = @_;

    if ( defined( $arg[0] ) and ( $arg[0] eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__, "METHODS/rows - load table by rows" );
    }

    return $self->load(@arg);
}

sub cols {
    my ( $self, @arg ) = @_;

    if ( defined( $arg[0] ) and ( $arg[0] eq PPC::config('help_cmd') ) ) {
        PPC::_help( __PACKAGE__, "METHODS/cols - load table by columns" );
    }

    return $self->load( transpose( \@arg ) );
}

1;

__END__

=head1 NAME

TextTable - Create Text::Table

=head1 SYNOPSIS

 use PPC::Plugin::TextTable;

=head1 DESCRIPTION

This module implements table creation with B<Text::Table>.

=head1 COMMANDS

=head2 TextTable - provide help

Provides help from the B<PPC> shell.

=head1 METHODS

=head2 texttable - create table object

 [$table =] texttable [OPTIONS];

Create B<Text::Table> object.  See B<Text::Table> for B<OPTIONS>.  

=head2 cols - load table by columns

 $table->cols([array],[...]);

Load table by columns.  Array references provided will make up the columns 
of the B<Text::Table> table.

=head2 rows - load table by rows

 $table->rows([array],[...]);

Load table by rows.  Array references provided will make up the rows 
of the B<Text::Table> table.

=head1 EXAMPLES

  use PPC::Plugin::Trace;
  $t = trace 'www.google.com';

  use PPC::Plugin::TextTable;
  $table = texttable("Sent\nTTL", "IP Addr", "Time", "Recv\nTTL");
  $table->cols(
      [ map { [$_->layers]->[1]->ttl } $t->sent ],
      [ map { [$_->layers]->[1]->src } $t->recv ],
      [ $t->time ],
      [ map { [$_->layers]->[1]->ttl } $t->recv ]
  );
  print $table;

=head1 SEE ALSO

L<Text::Table> L<Array::Transpose>

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
