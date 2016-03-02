# TEST THIS FIRST.  If PPC::Interface fails to load (probably because) 
# architecture isn't defined in PPC::Interface), there is no use in 
# continuing.

use strict;
use warnings;

use Test::More tests => 1;

#########################

my $ret;
local $SIG{__WARN__} = sub { $ret = $_[0]; };
eval "use PPC::Interface";
ok( $ret !~ /^!!!!/, "PPC::Interface OK for $^O" ) 
  or BAIL_OUT( "PPC::Interface failed to load.  See lib/PPC/Interface.pm for details" );
