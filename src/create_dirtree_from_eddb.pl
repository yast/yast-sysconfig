#!/usr/bin/perl -w
#
# Usage:
#	create_dirtree_from_eddb.pl
#
# Author: Michael Koehrmann <curry@suse.de>
#----------------------------------------------------------------------------

sub main()
  {
    my $file        = $ARGV[0];
    my $line;
    my @line_array;

    my %rc_array;

    my $rc_name;
    my $rc_path;
    my $rc_file     = '';
    my $rc_command;
    my $rc_string;

    if ( not defined( $file = $ARGV[0] ))
      {
	print "Usage: create_dirtree_from_eddb.pl meta_rc.config\n";
	exit 1;
      }

    # first run: create directories
    print "Reading $file...\n";
    open( FILE, $file ) or die "EXITING cause (1): Can't open $file\n";

    print "Processing directories and array...\n";
    while( defined($line = <FILE>) ) 
      {
	@line_array = split( /\#/, $line, 2);
	$line       = $line_array[0];
	
	# ignore comments
	if ( length($line_array[0]) > 0 )
	  {
	    # delete multiple spaces from the current line
	    $line =~ tr/  / /s;
	    chomp($line);

	    @line_array = split( / /, $line, 3);
	    $rc_name    = $line_array[0];

	    if ( $line_array[1] eq 'path' )
	      {
		$rc_path            = "root".$line_array[2];
		$rc_path =~ s:\$:/:g;
		$rc_array{$rc_name} = $rc_path."/".$rc_name;
		$rc_command         = "mkdir -p ".$rc_path."/".$rc_name;

		system($rc_command);
	      }
	    $rc_name = '';
	    $rc_path = '';
	    $rc_command = '';
	  }
      }

    close(FILE);

    $line = '';

    # second run: create files into directories
    print "Reading $file...\n";
    open( FILE, $file ) or die "EXITING cause (2): Can't open $file\n";

    print "Processing type, mtype, typedef and descr files...\n";
    while( defined($line = <FILE>) ) 
      {
	@line_array = split( /\#/, $line, 2);
	$line       = $line_array[0];
	
	# ignore comments
	if ( length($line_array[0]) > 0 )
	  {
	    # delete multiple spaces from the current line
	    $line =~ tr/  / /s;
	    chomp($line);

	    @line_array  = split( / /, $line, 3);
	    $rc_name     = $line_array[0];

	    if ( not defined($rc_path = $rc_array{$rc_name}) )
	      {
		$rc_path = "root/".$rc_name;
	      }

	    $rc_string   = $line_array[2];
	    my $execute  = 0;

	    if ( $line_array[1] eq 'type' )
	      {
		$rc_file = $rc_path."/type";
		$execute = 1;
	      }
	    elsif ( $line_array[1] eq 'mtype' )
	      {
		$rc_file = $rc_path."/mtype";
		$execute = 1;
	      }
	    elsif ( $line_array[1] eq 'typedef' )
	      {
		$rc_file = $rc_path."/typedef";
		$execute = 1;
	      }
	    elsif ( $line_array[1] eq 'descr' )
	      {
		$rc_file = $rc_path."/descr";
		$execute = 1;

		# delete double quotes from the string.
		$rc_string =~ tr/\"//d;
	      }

	    if ( $execute == 1)
	      {
		open( NEWFILE, "> ".$rc_file ) or die "EXITING cause (3): Can't open $rc_file\n";
		print NEWFILE $rc_string;
		close( NEWFILE );
	      }

	    $rc_name    = '';
	    $rc_path    = '';
	    $rc_command = '';
	    $rc_string  = '';
	    $rc_file    = '';
	  }
      }
    close(FILE);
  }

main();

exit 0;

# EOF
