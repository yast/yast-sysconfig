#!/usr/bin/perl -w

#
#  File:
#    .pl
#
#  Module:
#    Sysconfig editor
#
#  Authors:
#    Ladislav Slezak <lslezak@suse.cz>
#
#  Description:
#
# $Id$
#

# used modules
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

    my @recurse = ();

    my $result = "";
    my $first = 1;

    while ($index < $size)
    {
	my $location = $list[$index++];
	my $id = $list[$index++];
	
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
	    my $prefix = $location;
	    my $postfix = "";

	    # split location to prefix and remaining part
	    if ($prefix =~ /(.*?)\/(.*)/)
	    {
		$prefix = $1;
		$postfix = $2;
	    }

	    if ($current_prefix eq "")
	    {
		$current_prefix = $prefix;
	    }

	    if ($prefix eq $current_prefix)
	    {
		push(@recurse, $postfix);
		push(@recurse, $id);
	    }
	    else
	    {
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

		$current_prefix = $prefix;
		@recurse = ();
		
		push(@recurse, $postfix);
		push(@recurse, $id);
	    }
	}
    }

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



sub hash_to_map(%)
{
    my (%desc) = @_;
    my $first = 1;
    my $result = '$[ ';

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

# hash:  key = location, value = node desacription (string)
my %descriptions = ();

# collect pairs (location, variables definition) from all configuration files
for my $fname (@list)
{
    open(CONFIGFILE, $fname);

#    print "file: $fname\n";
    
    my $location = "Other".$fname;
    my $description = "";

    while(my $line = <CONFIGFILE>)
    {
	# path metadata definition
	if ($line =~ /^##\s*Path\s*:\s*((\s*\s*\S+)*)\s*$/)
	{
	    $location = $1;
#	    print "'$location'\n";
	}
	elsif ($line =~ /^##\s*Description\s*:\s*((\s*\s*\S+)*)\s*$/)
	{
	    $descriptions{$location} = $1;
#	    $description = $1;
#	    print "'$location'\n";
	}
	# variable definition
	elsif ($line =~ /^\s*([-\w\/:]*)\s*=.*/)
	{
#	    print "Line: $line\n";
#	    print "Variable: $1\n\n";

	    my $existing_vars = $locations{$location};

	    if (defined($existing_vars))
	    {
		$existing_vars .= ",";
	    }

	    $existing_vars .= $1.'$'.$fname;

	    $locations{$location} = $existing_vars;
#	    $descriptions{$location} = $description;
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
print hash_to_map(%descriptions);
print "]\n";

