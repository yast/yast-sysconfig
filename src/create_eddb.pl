#!/usr/bin/perl -w
#
# Usage:   
#	make_new_modul
#
#	-v	verbose
#	-d	debug
#
# Author: Michael Hager <mike@suse.de>

use strict;
use English;
use Getopt::Std;
use vars qw( $opt_v $opt_d );
use File::Basename;


# Global variables.

my $verbose		= 0;
my $debug		= 0;
my $tmp			= "$PID.tmp";
my $base_dir            = "..";
my $target_dir          = "../dummy";
my $new_name            = "y2c_noname";
my $raw_name            = "noname";
my $maintainer          = "nobody";   
my $email               = "nobody\@nowhere.org";
my $date                = "1.1.1900";

# Valid names are rc.config-variable names and directory names, valid
# properties are type, path, descr and typedef. You need these two
# variables to create a database file in a tabular format. Set
# $longest_name to a number greater than the number of characters
# of the longest variable or directory name.
my $longest_name        = 35;
my $longest_property    = 10;

# Call the main function and exit.
# DO NOT enter any other code outside a sub!
#
# This is not just to satisfy C programmers - rather, this is intended
# to keep global things like the variables above apart from main
# program (local) variables. It is just too easy to mix things up; one
# simple 'i' variable in the main program might too easily be mixed up
# with a function's forgotten 'i' declaration.

#main();
#exit 0;


#-----------------------------------------------------------------------------


# Main program.

sub main()
{
    my $file;

    # Extract command line options.
    # This will set a variable opt_? for any option,
    # e.g. opt_v if option '-v' is passed on the command line.

    getopts('vd');

    $verbose	= 1 if $opt_v;
    $debug	= 1 if $opt_d;

    deb( "Start processing ...");

    # Delete old database file
    unlink( "../EDDB");

    print("Creating EDDB.tmp...\n");
 
    # Create entries in EDDB for all files.
    foreach $file ( `find . -type f `  )
    {
        deb( "  ");
	change_single ( $file )
    }

    # Create entries in EDDB for all directories.
    foreach $file ( `find . -type d `  )
    {
        deb( "  ");
	change_dir ( $file )
    }

    # After creating a new database file EDDB -> sort it.
    print("Sorting...\n");
    print(`sort -u ../EDDB.tmp > ../EDDB.sort`);

    unlink("../EDDB.tmp");

    writeInfo();

    print(`cat ../EDDB.tmp ../EDDB.sort > ../EDDB`);

    unlink("../EDDB.tmp");
    unlink("../EDDB.sort");

    print("The new database file ../EDDB was successfully created.\n");
}

#-----------------------------------------------------------------------------


# Process one single file
#
# Parameters:
#	file name to process (  )


sub change_single ()
{
    my ( $src ) = @_;

    my $base   = basename( $src );
    my $path   = dirname( $src );
    my $dir    = basename( $path );
    my $target = "../EDDB.tmp";
    my $line;
    my $globalline;
    my $typedef = $path . "/typedef";
    my $typedefline;
    my $tdline;

    deb( "Property", $base);
    deb( "path",     $path);
    deb( "dir",      $dir);
    deb( "typedef",  $typedef);

    chomp($base);
    chomp($path);
    chomp($dir);

    # filename: descr
    if ( $base eq "descr" )
    {
      deb( "DESCR");
      
      open ( SRC,     $src       ) or die "EXITING cause:: Can't open $src";
      open ( TARGET, ">>$target" ) or die "EXITING cause:: Can't open $target";
      
      logf ( $src );
      logf ( $target );
      
      while ( $line = <SRC> )
      {
        chomp( $line );
	$line       =~ s:\":\\\":g;
	$line =~ tr/  / /s;
	$globalline .= $line;
	$globalline .= " ";
      }

      # Create tabular format of database file EDDB.
      while ( length($dir) < $longest_name ) {
	$dir = $dir . " ";
      }

      while ( length($base) < $longest_property ) {
	$base = $base . " ";
      }

      $globalline = "\n".$dir." ".$base." \"".$globalline."\"";
      print TARGET $globalline;

      close ( TARGET );
      close ( SRC );
    }

    # filename: type or mtype
    if ( ($base eq "type") or ($base eq "mtype") )
    {
      deb( "mTYPE");
      
      open ( SRC,     $src       ) or die "EXITING cause:: Can't open $src";
      open ( TARGET, ">>$target" ) or die "EXITING cause:: Can't open $target";
      
      logf ( $src );
      logf ( $target );
      
      while ( $line = <SRC> )
      {
        chomp( $line );
        $globalline = $line;
      }

      # Create tabular format of database file EDDB.
      while ( length($dir) < $longest_name ) {
	$dir = $dir." ";
      }

      while ( length($base) < $longest_property ) {
	$base = $base." ";
      }

      $globalline = "\n".$dir." ".$base." ".$globalline;
      print TARGET $globalline;

      close ( TARGET );
      close ( SRC );
    }

    # filename: typedef
    if ( ($base eq "typedef") )
      {
	deb( "TYPEDEF" );

	open ( TARGET, ">>$target" ) or die "EXITING cause:: Can't open $target";
	open ( TYPEDEF, $typedef   ) or die "EXITING cause:: Can't open $typedef";

	logf ( $target );
	logf ( $typedef );

	$tdline = "";

	while ( $typedefline = <TYPEDEF> )
	  {
	    chomp ( $typedefline );
	    $tdline = $typedefline;
	    deb( $typedefline );
	  }

	# Create tabular format of database file EDDB.
	while ( length($dir) < $longest_name ) {
	  $dir = $dir . " ";
	}
	
	while ( length($base) < $longest_property ) {
	  $base = $base . " ";
	}
	
	$tdline = "\n" . $dir . " " . $base . " " . $tdline;

	print TARGET $tdline;

	close ( TARGET );
	close ( TYPEDEF );
      }
}

sub change_dir ()
{
    my ( $src ) = @_;

    my $base    = basename( $src );
    my $path    = dirname( $src );
    my $target  = "../EDDB.tmp";
    my $line;
    my $globalline;

    my $property = "path";

    chomp($base);
    chomp($path);

    #  check if the filname has to be changed

    deb( "variable",       $base);
    deb( "path",       $path);
    deb( "src",        $src);

    deb( "PATH");
      
    open ( SRC,     $src       ) or die "EXITING cause:: Can't open $src";
    open ( TARGET, ">>$target" ) or die "EXITING cause:: Can't open $target";
      
    $path       =~ s:^\.::g;

    if ( $path ne "" )
    {
      while ( length($base) < $longest_name ) {
	$base = $base . " ";
      }

      while ( length($property) < $longest_property ) {
	$property = $property . " ";
      }

       $globalline = "\n" . $base . " " . $property . " "  . $path;

       print TARGET $globalline;
    }
    
    close ( TARGET );
    close ( SRC );
  
}




#-----------------------------------------------------------------------------


# Log a message to stderr.
#
# Parameters:
#	Messages to write (any number).

sub warning()
{
    my $msg;

    foreach $msg ( @_ )
    {
	print STDERR $msg . " ";
    }

    print STDERR "\n";
}


#-----------------------------------------------------------------------------


# Log a message to stdout if verbose mode is set
# (command line option '-v').
#
# Parameters:
#	Messages to write (any number).

sub logf()
{
    my $msg;

    if ( $verbose )
    {
	foreach $msg ( @_ )
	{
	    print $msg . " ";
	}

	print "\n";
    }
}


#-----------------------------------------------------------------------------


# Log a debugging message to stdout if debug mode is set
# (command line option '-d').
#
# Parameters:
#	Messages to write (any number).

sub deb()
{
    my $msg;

    if ( $debug )
    {
	print '   DEB> ';

	foreach $msg ( @_ )
	{
	    print $msg . " ";
	}

	print "\n";
    }
}


#-----------------------------------------------------------------------------


# Print usage message and abort program.
#
# Parameters:
#	---

sub usage()
{
    die "\n\nUsage: $0 [-vd] <new package name> <maintainer> <email>\n\n";
}

#------------------------------------------------------------------------------

# Write additional information to database file

sub writeInfo()
  {
    my $final = "../EDDB.tmp";
    my $infotext = "# File: EDDB or meta_rc.config
#
# This file is automatically created. Do not edit.
#
# This file contains meta data about all known variables of the file
# /etc/rc.config and the files in /etc/rc.config.d/. It is necessary for
# the graphical RC-Config-Editor module in YaST2.
#
# Format of this file:
#
# ----------------------------------------------------------------------------
# Comments:
# # these are comments
# \\n
# \\n<whitespace>
# ----------------------------------------------------------------------------
# <variable>                        <property> <value>
#
# Examples:
#
# ENABLE_SUSECONFIG                 path       /Base-Administration/SuSEConfig
# ENABLE_SUSECONFIG                 type       boolean
# ENABLE_SUSECONFIG                 typedef    strict
# Desktop-Basics                    descr      \"<p></p> <p>General windowmanager settings</p> \"
# Desktop-Basics                    path       /Desktop
# ---------------------------------------------------------------------------- 
# <variable> ::= <all rc.config variable names or directory names>
# ----------------------------------------------------------------------------
# <property> defines the meta information, which is set
# 
# <property> ::=
# <type>                type of the variable (i.e. boolean, string ..)
# <mtype>               like type, but more than one item is allowed
# <typedef>             strict | not_strict
# <path>                hierachical information
# ----------------------------------------------------------------------------
# <type> and <mtype> define the type of the variable.
# A typedefinition can be strict or not_strict, no other values are allowed.
# 
# <type>    ::= type    [ string | integer | boolean | enum  <enumlist> ]
# <mtype>   ::= mtype   [ string | integer | boolean | enum  <enumlist> ]
# <typedef> ::= typedef [ strict | not_strict ]
# 
# The default value for an undefined <type> or <mtype> is \"string\".
# The default value for an undefined <typedef> is \"not_strict\".
# ----------------------------------------------------------------------------
# <path> defines the hierarchical classification of the variable.
#
# <path> ::= path <path-string>
# ----------------------------------------------------------------------------";

    open ( FINAL, ">>$final" ) or die "EXITING cause:: Can't open $final";

    print FINAL $infotext;

    close ( FINAL );
  }

#-------------------------------------------------------------------------------------

main();

exit 0;

# EOF
