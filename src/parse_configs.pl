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

# global variable - normal or powertweak mode flag
# used at tree widget content generation as opened/closed flag
my $powertweak_mode = "false";

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
	
        $result .= "`item(`id(\"$var\"), \"$varname\", $powertweak_mode)";
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
	    if ($prefix =~ /(.*?[^\\])\/(.*)/)
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

		$result .= "`item(`id(\"$new_node\"), \"$current_prefix\", $powertweak_mode, [ $x ])";

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

	$result .= "`item(`id(\"$new_node\"), \"$current_prefix\", $powertweak_mode, [ $x ])";
    }

    return $result;
}

sub flip_hash(%)
{
    my %input = @_;
    my %ret;

    for my $location (keys(%input))
    {
	my $var = $input{$location};
	my @vars = split(',', $var);

	for my $v (@vars)
	{
	    $ret{$v} = $location;
	}
    }

    return %ret;
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

	if (defined($description))
	{
	    $description =~ s/([^\\])"/$1\\"/g;
	}

	# escape double quote characters
	my $n = 1;
	while($n)
	{
	    $n = $path =~ s/([^\\])"/$1\\"/go;
	}

	# output nil if value is undefined
	$result .= (defined($description)) ? "\"$path\" : \"$description\"" : "\"$path\" : nil";
    }

    $result .= ' ]';

    return $result;
}

# remove variable identification from string
sub remove_variable($$)
{
    my ($string, $var) = @_;
    my $result = "";

    my @list = split(/,/, $string);

    for my $v (@list)
    {
	if ($v ne $var)
	{
	    if (length($result) > 0)
	    {
		$result .= ",";
	    }

	    $result .= $v;
	}
    }

    return $result;
}

# read multiline tag from sysconfig file
sub ReadMulti()
{
    my $ret = "\\";
    
    while ($ret =~ /(.*)\\$/)
    {
	# remove trailing backslash
	$ret = $1;

	my $line = <CONFIGFILE>;

	# break cycle when EOF is reached
	if (!defined($line))
	{
	    last;
	}

	if ($line =~ /^##(.*)/)
	{
	    $line = $1;
	}
	chomp($line);

	$ret .= $line;
    }

    return $ret;
}

# list of files to process
my @list = ();

# collect all files
for my $arg (@ARGV)
{
    if ($arg eq "--powertweak")
    {
	$powertweak_mode = "true";
    }
    else
    {
	my @files = bsd_glob($arg);

	# merge lists
	@list = (@list, @files);
    }
}


# hash:  key = location, value = string containig variables identifications
my %locations = ();

# hash:  key = location, value = node description (string)
my %descriptions = ();

# report redefined variables
my %redefined_vars = ();

# actions started when variable is changed: key = variableID,
# value = hash 'Config','ServiceRestart', 'ServiceReload','Command' => 
my %actions = ();

# collect pairs (location, variables definition) from all configuration files
for my $fname (@list)
{
    my $stat = open(CONFIGFILE, $fname);

    if (!defined $stat)
    {
	print STDERR "Cannot open file $fname\n";
	next;
    }

    my $location = "Other".$fname;
    my $description = "";

    my $Config = undef;
    my $ServiceRestart = undef;
    my $ServiceReload = undef;
    my $Command = undef;
    my $PreSaveCommand = undef;
    my $Meta_found = 0;

    # hack for /etc/sysconfig/network/ifcfg-* files
    if ($fname =~ '^/etc/sysconfig/network/ifcfg-(.*)')
    {
	$location = "Hardware/Network/$1";
	$descriptions{$location} = "Configuration of network device $1";
    }

    # remember all variables from config file
    # used for redefinition check
    my %found_vars = ();

    while(my $line = <CONFIGFILE>)
    {
	chomp($line);

	# path metadata definition
	if ($line =~ /^##\s*Path\s*:\s*((\s*\S+)*)\s*$/)
	{
	    $location = $1;

	    # read multiline metadata
	    if ($location =~ /(.*)\\$/)
	    {
		# Read multiline metadata value
		$location .= ReadMulti();
	    }
	}
	elsif ($line =~ /^##\s*Description\s*:\s*((\s*\S+)*)\s*$/)
	{
	    my $descr = $1;

	    # read multiline metadata
	    if ($descr =~ /(.*)\\$/)
	    {
		# Read multiline metadata value
		$descr .= ReadMulti();
	    }

	    $descriptions{$location} = $descr;
	}
	# variable definition
	elsif ($line =~ /^\s*([-\w\/:]*)\s*=.*/)
	{
	    if (defined($found_vars{$1}))
	    {
		# add to redefined vars
		$redefined_vars{$1.'$'.$fname} = 1;
		
		# variable was already found
		# remove it from previous location
		my $prev_location = $found_vars{$1};
		my $new_val = remove_variable($locations{$prev_location}, $1.'$'.$fname);

		if ($new_val eq "")
		{
		    # remove location if it is empty
		    delete($locations{$prev_location});
		}
		else
		{
		    # update location
		    $locations{$prev_location} = $new_val;
		}
	    }

	    my $existing_vars = $locations{$location};

	    if (defined($existing_vars))
	    {
		$existing_vars .= ",";
	    }

	    $existing_vars .= $1.'$'.$fname;

	    $locations{$location} = $existing_vars;

	    # remember location of variable
	    $found_vars{$1} = $location;

	    # reset metadata flag for the next variable
	    $Meta_found = 0;

	    # add action commands to the variable if they are defined
	    my %tmp = ();
	    if (defined($Config))
	    {
		$tmp{'Cfg'} = $Config;
	    }
	    if (defined($ServiceReload))
	    {
		$tmp{'Reld'} = $ServiceReload;
	    }
	    if (defined($ServiceRestart))
	    {
		$tmp{'Rest'} = $ServiceRestart;
	    }
	    if (defined($Command))
	    {
		$tmp{'Cmd'} = $Command;
	    }
	    if (defined($PreSaveCommand))
	    {
		$tmp{'Pre'} = $PreSaveCommand;
	    }
	    
	    $actions{$1.'$'.$fname} = \%tmp;
	}
	# SuSEconfig script specification
	elsif ($line =~ /^##\s*Config\s*:\s*((\s*\S+)*)\s*$/)
	{
	    if ($Meta_found == 0)
	    {
		# reset all other action tag values
		$ServiceReload = $ServiceRestart = $Command = $PreSaveCommand = undef;
	    }

	    $Config = $1;

	    # read multiline metadata
	    if ($Config =~ /(.*)\\$/)
	    {
		# Read multiline metadata value
		$Config .= ReadMulti();
	    }

	    if ($Config eq '""')
	    {
		$Config = '';
	    }

	    $Meta_found = 1;
	}
	# services to restart
	elsif ($line =~ /^##\s*ServiceRestart\s*:\s*((\s*\S+)*)\s*$/)
	{
	    if ($Meta_found == 0)
	    {
		# reset all other action tag values
		$ServiceReload = $Config = $Command = $PreSaveCommand = undef;
	    }

	    $ServiceRestart = $1;

	    # read multiline metadata
	    if ($ServiceRestart =~ /(.*)\\$/)
	    {
		# Read multiline metadata value
		$ServiceRestart .= ReadMulti();
	    }

	    if ($ServiceRestart eq '""')
	    {
		$ServiceRestart = '';
	    }

	    $Meta_found = 1;
	}
	# services to reload 
	elsif ($line =~ /^##\s*ServiceReload\s*:\s*((\s*\S+)*)\s*$/)
	{
	    if ($Meta_found == 0)
	    {
		# reset all other action tag values
		$ServiceRestart = $Config = $Command = $PreSaveCommand = undef;
	    }

	    $ServiceReload = $1;

	    # read multiline metadata
	    if ($ServiceReload =~ /(.*)\\$/)
	    {
		# Read multiline metadata value
		$ServiceReload .= ReadMulti();
	    }

	    if ($ServiceReload eq '""')
	    {
		$ServiceReload = '';
	    }

	    $Meta_found = 1;
	}
	# generic command
	elsif ($line =~ /^##\s*Command\s*:\s*((\s*\S+)*)\s*$/)
	{
	    if ($Meta_found == 0)
	    {
		# reset all other action tag values
		$ServiceRestart = $Config = $ServiceReload = $PreSaveCommand = undef;
	    }

	    $Command = $1;

	    # read multiline metadata
	    if ($Command =~ /(.*)\\$/)
	    {
		# Read multiline metadata value
		$Command .= ReadMulti();
	    }

	    if ($Command eq '""')
	    {
		$Command = '';
	    }

	    $Meta_found = 1;
	}
	# generic command started before changed variable is saved
	elsif ($line =~ /^##\s*PreSaveCommand\s*:\s*((\s*\S+)*)\s*$/)
	{
	    if ($Meta_found == 0)
	    {
		# reset all other action tag values
		$ServiceRestart = $Config = $Command = $ServiceReload = undef;
	    }

	    $PreSaveCommand = $1;

	    # read multiline metadata
	    if ($PreSaveCommand =~ /(.*)\\$/)
	    {
		# Read multiline metadata value
		$PreSaveCommand .= ReadMulti();
	    }

	    if ($PreSaveCommand eq '""')
	    {
		$PreSaveCommand = '';
	    }

	    $Meta_found = 1;
	}
	# other lines (comments, empty lines) are ignored 
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
print hash_to_map(%descriptions).",\n";
print hash_to_map(flip_hash(%locations)).",\n";
print hash_to_map(%redefined_vars).",\n";

# print action commands for each variable
print "\$[\n";
my @keys = keys(%actions);
for my $var (@keys)
{
    print "\"$var\" : ".hash_to_map(%{$actions{$var}}).",\n";
}
print "]\n";

print "]\n";

