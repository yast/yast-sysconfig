#!/usr/bin/perl -w

#
#  File:
#    parse_configs.pl
#
#  Module:
#    Sysconfig editor
#
#  Authors:
#    Ladislav Slezak <lslezak@suse.cz>
#
#  Description:
#    This script parses configuration files and generates YCP list
#    with values:
#        - list of items for tree widget
#        - map with node descriptions
#
#    This script is used by YaST2 sysconfig editor to speedup
#    module start.
#
# $Id$
#

# used modules:
# module for wild card file name expansion
use File::Glob ':glob';

# convert list of variable identifications to list of items
# required by Yast2 Tree widget
sub ids_to_item($$)
{
    my ($string, $location) = @_;
    my $result = "";

    my @list = split(/,/, $string);

    # sort list of IDs
    #@list = sort(@list); # should be sorted from yast2

    my $first = 1;

    for my $var (@list) {

	my $varname = $var;

	if ($varname =~ /(.*)\$.*/) 
	{
	    $varname = $1;
	}

	if ($first == 0)
	{
	    $result .= ", ";
	}
	else
	{
	    $first = 0;
	}
	
        $result .= "`item(`id(\"$var\$$location\"), \"$varname\", false)";
    }

    return $result;
}


sub convert(@);

# recursively create Tree widget content
# paramter: list which contains pairs (location string, variables id string),
# last item in the list is prefix of all variables
 
sub convert(@)
{
    my (@list) = @_;

    my $node = pop(@list);

    my $size = @list;
    my $index = 0;
    my $current_prefix = "";

    # array used for recursive converting
    my @recurse = ();

    my $result = "";
    my $first = 1;

    while ($index < $size)
    {
	my $location = $list[$index++];
	my $id = $list[$index++];

	# location is empty - stop recursion and return list of leaf-node items	
	if ($location eq "")
	{
	    if ($first != 1)
	    {
		$result .= ", ";
	    }
	    else
	    {
		$first = 0;
	    }

	    $result .= ids_to_item($id, $node);
	}
	else
	{
	    # get prefix of current location
	    my $prefix = $location;
	    my $postfix = "";

	    # split location to prefix and remaining part
	    if ($prefix =~ /(.*?)\/(.*)/)
	    {
		$prefix = $1;
		$postfix = $2;
	    }

	    # at start is current prefix empty
	    if ($current_prefix eq "")
	    {
		$current_prefix = $prefix;
	    }

	    # if prefix is same as previous one just push remaining part of path and variable id to list
	    if ($prefix eq $current_prefix)
	    {
		push(@recurse, $postfix);
		push(@recurse, $id);
	    }
	    else
	    {
		# if prefix is different we collected all variables with same prefix
		# proces it recursively
		my $new_node = ($node eq "") ? $current_prefix : $node.'/'.$current_prefix;

		push(@recurse, $new_node);

		my $x = convert(@recurse);

		if ($first != 1)
		{
		    $result .= ", ";
		}
		else
		{
		    $first = 0;
		}

		$result .= "`item(`id(\"$new_node\"), \"$current_prefix\", false, [ $x ])";

		# store new prefix and new id
		$current_prefix = $prefix;
		@recurse = ();
		
		push(@recurse, $postfix);
		push(@recurse, $id);
	    }
	}
    }

    # recursively process remaining values
    if (@recurse > 0)
    {
	my $new_node = ($node eq "") ? $current_prefix : $node.'/'.$current_prefix;

	push(@recurse, $new_node);

	my $x = convert(@recurse);

	if ($first != 1)
	{
	    $result .= ", ";
	}

	$result .= "`item(`id(\"$new_node\"), \"$current_prefix\", false, [ $x ])";
    }

    return $result;
}


# convert perl hash to YCP map (in string form)
sub hash_to_map(%)
{
    my (%desc) = @_;
    my $first = 1;
    my $result = '$[ ';

    # each hash pair convert to string
    for my $path (keys(%desc))
    {
	if ($first != 1)
	{
	    $result .= ', ';
	}
	else
	{
	    $first = 0;
	}

	my $description = $desc{$path};

	# escape double quote characters
	$description =~ s/[^\\]"/\\"/g;
	$path =~ s/[^\\]"/\\"/g;

	$result .= "\"$path\" : \"$description\"";
    }

    $result .= ' ]';

    return $result;
}

# list of files to process
my @list = ();

# collect all files
for my $arg (@ARGV)
{
    my @files = bsd_glob($arg);

    # merge lists
    @list = (@list, @files);
}


# hash:  key = location, value = string containig variables identifications
my %locations = ();

# hash:  key = location, value = node description (string)
my %descriptions = ();

# collect pairs (location, variables definition) from all configuration files
for my $fname (@list)
{
    open(CONFIGFILE, $fname);

    my $location = "Other".$fname;
    my $description = "";

    while(my $line = <CONFIGFILE>)
    {
	chomp($line);

	# path metadata definition
	if ($line =~ /^##\s*Path\s*:\s*((\s*\s*\S+)*)\s*$/)
	{
	    $location = $1;
	}
	elsif ($line =~ /^##\s*Description\s*:\s*((\s*\s*\S+)*)\s*$/)
	{
	    my $descr = $1;

	    # read multiline descriptions
	    while ($descr =~ /(.*)\\$/)
	    {
		# remove trailing backslash
		$descr = $1;

		# read next line
		$line = <CONFIGFILE>;
		chomp($line);

		if ($line =~ /^##(.*)/)
		{
		    $descr .= $1;
		}
	    }

	    $descriptions{$location} = $descr;
	}
	# variable definition
	elsif ($line =~ /^\s*([-\w\/:]*)\s*=.*/)
	{

	    my $existing_vars = $locations{$location};

	    if (defined($existing_vars))
	    {
		$existing_vars .= ",";
	    }

	    $existing_vars .= $1.'$'.$fname;

	    $locations{$location} = $existing_vars;
	}
    }

    close(CONFIGFILE);
}

# create sorted list of locations
my @sorted_locations = sort(keys(%locations));
my @rec = ();

for my $loc (@sorted_locations)
{
    push(@rec, $loc);
    push(@rec, $locations{$loc});
}

# initialize to empty prefix 
push (@rec, "");

# start conversion
print "[\n";
print '['.convert(@rec)."],\n";
print hash_to_map(%descriptions)."\n";
print "]\n";

