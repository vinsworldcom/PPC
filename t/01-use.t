# TEST THIS SECOND.  If PPC fails to load, nothing else will work.

use strict;
use warnings;

use Test::More tests => 1;

#########################

eval "use PPC";
if ( !$@ ) {
    ok( 1, "use PPC" );
} else {
    BAIL_OUT( "PPC failed to load: $@ - no point in continuing" );
}
