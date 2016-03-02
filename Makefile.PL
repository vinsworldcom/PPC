use 5.014001;
use ExtUtils::MakeMaker;

my %addPREREQ_PM;
if ($^O eq 'linux') {

    # could also add Term::ReadLine::Gnu here for the terminal history, 
    # but it *does* work without it and I had to apt-get ncurses and 
    # readline development libraries so it would compile.  There is a 
    # note in the CAVEAT section of PerlApp::Shell PerlDoc.
    $addPREREQ_PM{'IO::Interface::Simple'} = 0
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PPC',
    VERSION_FROM      => 'lib/PPC.pm', # finds $VERSION
    ($ExtUtils::MakeMaker::VERSION >= 6.3002) ? ('LICENSE'  => 'perl', ) : (),
    EXE_FILES         => ['bin/ppc.pl',
                         ],
    PREREQ_PM         => {'Net::Pcap' => 0.17,
                          'Net::Frame' => 1.15,
                          'Net::Frame::Simple' => 1.06,
                          %addPREREQ_PM
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PPC.pm', # retrieve abstract from module
       AUTHOR         => 'Michael Vincent <vin at vinsworld dot com>') : ()),
);

__END__

Thread:  http://www.perlmonks.org/?node_id=321982
Answer:  http://www.perlmonks.org/?node_id=322065

my %my_globals = (
    SUPPORT_FILES_DIR   => '/var/perl/Business-Shipping'
);

WriteMakefile(
    CONFIGURE       => \&extra_WriteMakefile_options,
);

#
# Override the standard "install" target, so that it calls "support_files_install"
#
sub MY::install {
    package MY;
    my $inherited = shift->SUPER::install(@_);
    my $new; 
    for ( split( "\n", $inherited ) ) {
        if ( /^install :: / ) {
            $_ .= " support_files_install";
        }
        $new .= "$_\n";
    }
    return $new;
}
sub MY::postamble {
    return qq{

support_files_install :
    \@echo "Installing support files (database, configuration, etc.) to $my_globals{SUPPORT_FILES_DIR}"
    \@\$(MKPATH) $my_globals{SUPPORT_FILES_DIR}/data
    \@\$(MKPATH) $my_globals{SUPPORT_FILES_DIR}/config
    \@\$(CP) --recursive --force data/*   $my_globals{SUPPORT_FILES_DIR}/data/
    \@\$(CP) --recursive --force config/* $my_globals{SUPPORT_FILES_DIR}/config/
};
}

sub extra_WriteMakefile_options {
    $my_globals{SUPPORT_FILES_DIR} = prompt(
            "\n"
        .   "  ---  Business::Shipping support files directory  ---  \n"
        .   "\n"
        .   "Business::Shipping has various support files for configuration, database, etc.\n"
        .   "(The path to these files can be overridden later on a per-user basis.)\n"
        .   "I need to know the path to the \'system\' level, or \'default\' files.\n"
        .   "On many systems, this directory will only be accessible by root.\n"
        .   "\n"
        .   "Business::Shipping default support files directory:", 
        $my_globals{SUPPORT_FILES_DIR},
    );
    $my_globals{SUPPORT_FILES_DIR} =~ s:[\\/]\s*$::;
    $my_globals{SUPPORT_FILES_DIR} =~ s:^\s*::;
    
    my %X;
    #$X{ EXTRA_CONFIG_OPTION } = "value";
    return \%X;
}
