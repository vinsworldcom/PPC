use 5.014001;
use ExtUtils::MakeMaker;

my %addPREREQ_PM;
if ( $^O eq 'linux' ) {

    # could also add Term::ReadLine::Gnu here for the terminal history,
    # but it *does* work without it and I had to apt-get ncurses and
    # readline development libraries so it would compile.  There is a
    # note in the CAVEAT section of App::PerlShell PerlDoc.
    $addPREREQ_PM{'IO::Interface::Simple'} = 1.08;
} elsif ( $^O eq 'MSWin32' ) {
    $addPREREQ_PM{'Win32::Net::Info'} = 1.00;
} else {
    warn "\n***Check `lib/PPC/Interface' directory for OS support.\n\n"
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME             => 'PPC',
    VERSION_FROM     => 'lib/PPC.pm',    # finds $VERSION
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ) ? ( 'LICENSE' => 'perl', ) : (),
    EXE_FILES        => [
        'bin/ppc.pl', 
        'bin/plsh.pl'
    ],
    PREREQ_PM        => {
        'Net::Pcap'          => 0.17,
        'Net::Frame'         => 1.17,
        'Net::Frame::Simple' => 1.08,
        'App::PerlShell'     => 1.04,
        %addPREREQ_PM
    },                               # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/PPC.pm',    # retrieve abstract from module
       AUTHOR        => 'Michael Vincent <vin at vinsworld dot com>' ) : ()),
);

__END__

Thread:  http://www.perlmonks.org/?node_id=321982
Answer:  http://www.perlmonks.org/?node_id=322065
