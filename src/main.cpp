/*---------------------------------------------------------------------\
|                                                                      |
|                      __   __    ____ _____ ____                      |
|                      \ \ / /_ _/ ___|_   _|___ \                     |
|                       \ V / _` \___ \ | |   __) |                    |
|                        | | (_| |___) || |  / __/                     |
|                        |_|\__,_|____/ |_| |_____|                    |
|                                                                      |
|                            rc_config_editor                          |
|                                                                      |
|                             rc_create_data                           |
|                                                        (C) SuSE GmbH |
\----------------------------------------------------------------------/

  File:       main.cpp

  Author:     Michael K"ohrmann <curry@suse.de>

*/

/*!
  \file main.cpp
  \author Michael K&ouml;hrmann, <curry@suse.de>
  \date 13.02.2001
  \version 0.2

  Project: YaST2, RC-Config-Editor

  Implementation of the main routine. This Program
  (<code>/usr/lib/YaST2/bin/rc_create_data</code>)is started by the
  RC-Config-Editor at launch. It gets all variables from the rc.config
  files and adds some data from a meta-data file
  (<code>meta_rc.config</code>) and generates
  ycp-specific output into two files: <code>rc_config_keys</code> and
  <code>tree_data</code>. The first file includes a <code>ycp</code>-map
  of all rc.config variables and all necessary directories for the
  variable tree in the editor, the second file includes the directory
  tree in shape of a <code>ycp</code>-list.
*/

#include <ctype.h>
#include <stdio.h>
#include <glob.h>
#include <unistd.h>
#include <iostream>
#include <fstream>
#include <string>
#include <map>
#include <set>
#include <list>
#include <algorithm>

#include "RCVariable.h"
#include "RCDirectory.h"
#include "TreeNode.h"

using std::string;
using std::map;
using std::set;
using std::list;
using std::endl;
using std::ifstream;
using std::ofstream;


/////////////////////////////////////////////////////////////////////
//
// Typedefs
//
/////////////////////////////////////////////////////////////////////

/*!
  RCVariableMap is a container for all RCVariables.
  The key is the name of the variable.
 */
typedef map<string, RCVariable> RCVariableMap;

/*!
  RCDirectoryMap is a container for all RCDirectories.
  The key is the name of the directory.
 */
typedef map<string, RCDirectory> RCDirectoryMap;

/*!
  StringMap is a container for the Descriptions of the RCDirectories.
  The key is the name of the variable. This container is neccesary
  because the directories are not created when the EDDB is read.
 */
typedef map<string, string> StringMap;

/*!
  StringSet is a container for Strings. It is used as container for
  all directory paths.
 */
typedef set<string> StringSet;

/*!
  StringList is a container for Strings. It is used as container for
  the directory tree in shape of a list.
*/
typedef list<string> StringList;

/*!
  Tree is a container for the directory tree.
*/
typedef map<string, TreeNode> Tree;

/////////////////////////////////////////////////////////////////////
//
// Methods
//
/////////////////////////////////////////////////////////////////////

/*!
  This method prints out all elements of the given map.
 */
template<class T, class A>
void showMap(const map<T, A>& v);

/*!
  This method prints out all elements of the given set.
 */
template<class T>
void showSet(const set<T>& v);

/*!
  This method prints out all elements of the given tree.
*/
void showTree(const Tree& v);

/*!
  This method prints out all elements of the given list.
 */
template<class T>
void showList(const list<T>& v);

/*!
  This method saves the given list to a text file.
 */
template<class T>
void writeListToFile(const list<T>* rootPtr, const char* filename);


//helperfunctions which were present in libg++ but not in libstdc++

// removes leading and trailing whitespace
string trim(const string& str)
{
  string s;
  string::size_type idx;
  if (str.empty()) return str;

  if ((idx=str.find_first_not_of(" \t")) != string::npos)
    s=str.substr(idx);
  else
    s="";

  if(s.empty()) return s;

  if((idx=s.find_last_not_of(" \t"))!=string::npos)
    s=s.substr(0,idx+1);
  else
    s="";

  return s;
}

// wrapper class for tolower
struct mytolower : public std::unary_function <int, int>
{
    int operator () (int x) { return tolower (x); }
};

//return lowercase version of str
string downcase(const string& str)
{
  string s=str;
  transform (s.begin(), s.end(), s.begin(), mytolower());
  return s;
}

//replace every a by b in str
void substitute(string& str, const string& a, const string& b)
{
  string::size_type idx=0;
  idx = str.find(a);
  while( idx != string::npos)
  {
    str.replace(idx,a.length(),b);
    idx=str.find(a,idx+b.length());
  }
}

//return string after pattern
string after(const string& str, const string& pattern)
{
  string s="";
  string::size_type idx;

  if ((idx=str.find(pattern))!=string::npos)
  {
    s=str.substr(idx+pattern.length());
  }

  return s;
}

//return string after any character in pattern
string after_any(const string& str, const string& pattern)
{
  string s="";
  string::size_type idx=0;

  //search for the fist occurence of pattern
  if ((idx=str.find_first_of(pattern))!=string::npos)
  {
    //search the end of this zone
    if ((idx=str.find_first_not_of(pattern,idx))!=string::npos)
    {
      s=str.substr(idx);
    }
  }

  return s;
}
/*
//split str in tokens delimited by characters  in sep, store up to max_tok in res
//treats multiple delimiters as one
int split (const string& str, string res[], int max_tok, const string& sep)
{
  string::size_type idx,idx2,start=0;
  int tok_nr=0;

  string::size_type len=str.length();

  while(tok_nr<max_tok-1 && start != string::npos && start<len)
  {
    idx = str.find_first_not_of(sep,start);

    //consists only of delimiters
    if(idx==string::npos) return tok_nr;

    //find end of token
    idx2=str.find_first_of(sep,idx);

    //end of string reached?
    if(idx2 != string::npos)
    {
      res[tok_nr]=str.substr(idx,idx2-idx);
      start=idx2+1;
    }
    else
    {
      res[tok_nr]=str.substr(idx);
      start=string::npos;
    }
    tok_nr++;
  }

  //abort because of max_tok reached?
  //if yes assign rest
  if(!(tok_nr<max_tok-1) && start!=string::npos)
  {
    res[tok_nr]=str.substr(start);
    tok_nr++;
  }

  return tok_nr;
}
*/

int split (const string& str, string res[], int max_tok, const string& sep)
{
	string::size_type idx=0,idx2;
	int tok_nr=0;

	string::size_type len=str.length();

	while(tok_nr<max_tok-1 && idx != string::npos && idx<len)
	{
		//find end of token
		idx2=str.find_first_of(sep,idx);

		//end of string reached?
		if(idx2 != string::npos)
		{
			res[tok_nr]=str.substr(idx,idx2-idx);
			idx=idx2+1;
		}
		else
		{
			res[tok_nr]=str.substr(idx);
			idx=string::npos;
		}
		tok_nr++;
	}

	//abort because of max_tok reached?
	//if yes assign rest
	if(!(tok_nr<max_tok-1) && idx!=string::npos)
	{
		res[tok_nr]=str.substr(idx);
		tok_nr++;
	}

	return tok_nr;
}


/*
some replacement rules g++ -> stl:

- descr.gsub("  ", " ");
+ substitute(descr,"  ", " ");
:s/\([a-z]*\)\.gsub(/substitute(\1,/

only for single characters !!!!:
- stringLine.after('#');
+ stringLine.substr(stringLine.find('#')+1);
:s/\([a-z]*\)\.after(\(.*\))/\1.substr(\1.find(\2)+1)/
else use
  after(stringLine,"pattern");

- value.before('#');
+ value.substr(0,value.find('#'));
:s\([a-z]*\)\.before(\(.*\))/\1.substr(0,\1.find(\2))/

index -> find, rfind
contains -> find
.gsub -> new substitute function
*/


/////////////////////////////////////////////////////////////////////
//
// Main method
//
/////////////////////////////////////////////////////////////////////

/*!
  \fn int main()

  Main method.

  First: all <code>rc.config</code> variables needed by the currently
  running system are read from the files <code>/etc/rc.config</code>
  and <code>/etc/rc.config.d/</code> and saved in the map
  RCVariableMap.

  Second: all meta data about the saved <code>rc.config</code>
  variables is loaded from the file
  <code>/usr/lib/YaST2/meta_rc.config</code> and put into the map.

  Third: now the algorithms take the command and generate all data
  neccesary for the RC-Config-Editor.
 */
int main(int argc, char* argv[])
{
  // some constants
  const int FILENAME_LENGTH   =   255;
  const int INPUT_LINE_LENGTH = 32768;
  const int MAX_VARS_IN_DIR   =     5;
  const int MAX_DIR_DEPTH     =    20;

  // variables for the file names
  char  meta_rc_config_arr[FILENAME_LENGTH]  = "/usr/lib/YaST2/data/meta_sys.config";
  char  rc_config_keys_arr[FILENAME_LENGTH]  = "/usr/lib/YaST2/rc_config_keys";
  char  tree_data_arr[FILENAME_LENGTH]       = "/usr/lib/YaST2/tree_data";
  char *meta_rc_config                       = meta_rc_config_arr;
  char *rc_config_keys                       = rc_config_keys_arr;
  char *tree_data                            = tree_data_arr;

  //  const char rc_config_keys[FILENAME_LENGTH] = "rc_config_keys";
  //  const char tree_data[FILENAME_LENGTH]      = "tree_data";
  //  const char y2log[FILENAME_LENGTH]          = "var/log/y2log";

  // array of all file patterns to search for rc.config files
  const char* globpattern[] = {
    "/etc/sysconfig/network/dhcp",
    "/etc/sysconfig/network/config",
    "/etc/sysconfig/network/ifcfg-lo",
    "/etc/sysconfig/network/ifcfg-eth0",
    "/etc/sysconfig/3ddiag",
    "/etc/sysconfig/autofs",
    "/etc/sysconfig/backup",
    "/etc/sysconfig/clock",
    "/etc/sysconfig/console",
    "/etc/sysconfig/cron_daily",
    "/etc/sysconfig/dhcpcd",
    "/etc/sysconfig/displaymanager",
    "/etc/sysconfig/hardware",
    "/etc/sysconfig/hotplug",
    "/etc/sysconfig/ispell",
    "/etc/sysconfig/java",
    "/etc/sysconfig/joystick",
    "/etc/sysconfig/kernel",
    "/etc/sysconfig/language",
    "/etc/sysconfig/locate",
    "/etc/sysconfig/lvm",
    "/etc/sysconfig/mail",
    "/etc/sysconfig/postfix",
    "/etc/sysconfig/mouse",
    "/etc/sysconfig/nfs-server",
    "/etc/sysconfig/proxy",
    "/etc/sysconfig/security",
    "/etc/sysconfig/sendmail",
    "/etc/sysconfig/sound",
    "/etc/sysconfig/ssh",
    "/etc/sysconfig/suseconfig",
    "/etc/sysconfig/sysctl",
    "/etc/sysconfig/windowmanager",
    "/etc/sysconfig/xntp",
    "/etc/sysconfig/ypbind",
    "/etc/rc.config",
    "/etc/rc.dialout",
    "/etc/powertweak/tweaks"
  };

  // struct for glob() (see: man 3 glob)
  glob_t globbuffer;

  // some pointers
  RCVariable* varptr  = NULL;
  RCDirectory* dirptr = new RCDirectory();
  string* dirPath     = new string;

  // some containers
  RCVariableMap  RCVariables;
  RCDirectoryMap RCDirectories;
  RCDirectoryMap NewRCDirectories;
  StringMap      DirectoryDescriptions;
  StringSet      DirectorySet;
  StringList     dirList;
  StringList     rcFileList;
  Tree           dirTree;

  // some string and char variables
  char   line[INPUT_LINE_LENGTH + 1];
  string stringLine;
  string filename;
  string varname;
  string value;
  string descr;
  string rest;
  string property;
  bool   firewall_mode = false;

  string powertweak = "Powertweak";

  if ((argc == 2) && ( strcmp(argv[1], "-f" ) == 0 ))
  {
     firewall_mode  = true;
     meta_rc_config = "/usr/lib/YaST2/data/meta_fw.config";
     rc_config_keys = "/usr/lib/YaST2/fw_config_keys";
     tree_data      = "/usr/lib/YaST2/fw_tree_data";
  }
  else if  (argc == 1)
  {
     // normal mode
  }
  else
  {
     printf( "\n\n\nERROR wrong usage:  rc_create_date [-f]\n\n");
     exit( 1 );
  }

  // initially push directory /etc in the directory map
  if ( !firewall_mode )
  {
     dirptr->setName("etc");
     dirptr->setBranch("/");
     dirptr->setDialogtype("dir");
     RCDirectories["etc"] = *dirptr;
  }
  dirptr = NULL;

  // add the directories "/" and "/etc" to the directory set
  *dirPath = (string)"/";
  DirectorySet.insert(*dirPath);

  if (!firewall_mode )
  {
     *dirPath = (string)"/etc";
     DirectorySet.insert(*dirPath);
  }

  ///////////////////////////////////////////////////////////////////
  //
  // Get input from configuration files in /etc/rc.config and
  // /etc/rc.config.d/
  //
  ///////////////////////////////////////////////////////////////////

  // Get all configuration files from /etc/rc.config.d/ into the array
  // globbuffer.glpath_v and push the filenames at the end of list
  // rcFileList. Be careful with sizeof(array).
  for (unsigned short j = 0;
       j < sizeof(globpattern)/sizeof(globpattern[0]);
       ++j)
  {
     glob(globpattern[j], 0, NULL, &globbuffer);
     for (int i = 0; i < (signed int)globbuffer.gl_pathc ; ++i)
	rcFileList.push_back((string)globbuffer.gl_pathv[i]);
  }

  // Open every existing rc.config file in the array and save the
  // variables in the RCVariables map.
  for (StringList::const_iterator filenameit = rcFileList.begin();
       filenameit != rcFileList.end();
       ++filenameit)
  {
     //filename = globbuffer.gl_pathv[i];
     filename = *filenameit;
     cout << "\n### File: " << filename << endl;

     ifstream fin_filename(filename.c_str());
     if(!fin_filename)
     {
	// must be written to the y2log file
	cout << "Unable to open file \'"
	     << filename
	     << " \' for reading.\n";
	continue;
     }
     // clear description after reading in new configuration file
     descr = "";

     while (fin_filename.getline(line,INPUT_LINE_LENGTH))
     {
	stringLine = (string)line;

	// filters all comments
	if ( stringLine.find('#') != string::npos )
	{
	   descr = descr + stringLine.substr(stringLine.find('#')+1);
	   rest  = stringLine.substr(0,stringLine.find('#'));
	   rest=trim(rest);

	   // if there is nothing left before the comment
	   // sign go on to the next input line
	   if (rest.empty())
	      continue;
	}

	// a valid rc.config variable defintion must contain a "="
	if (stringLine.find('=') == string::npos)
	   continue;

	// get the names of rc.config variables
	varname = stringLine.substr(0,stringLine.find('='));

	// delete some special entries in the rc.config files
	if (varname.find("test") != string::npos)
	   continue;

	// filters empty strings
	varname=trim(varname);
	if (!varname.empty())
	{
	   // test if RCVariable "varname" exists in RCVariableMap
	   RCVariableMap::iterator it = RCVariables.find(varname);

	   if (it != RCVariables.end())
	   {
	      // found: set values of found entry
	      varptr = &it->second;
	   }
	   else
	   {
              cout << "\nVar: " << varname << endl;
	      // not found: create new entry in RCVariableMap and
	      // set branch, parent, path, ...
	      varptr = new RCVariable;

/// powertweak hack: some variables contain '/' char
	      string pathname = varname;
	      replace(varname.begin(), varname.end(), '/', 'I');
	      
	      varptr->setName(pathname/*varname*/);
	      varptr->setBranch("/etc/" + downcase(varname));
	      varptr->setParent(downcase(varname));
	      string base = filename;
	      substitute( base, "/", "." );
	      varptr->setPath( base + "." + pathname /*varname*/);

	      // add descr to RCVariable and afterwards set descr
	      // to "", filter comments
	      substitute(descr,"\"", "\\\"");
	      substitute(descr,"#", "");
	      while (descr.find("  ") != string::npos)
		 substitute(descr,"  ", " ");
	      varptr->setDescr(descr);
	      descr = "";

	      RCVariables[varname] = *varptr;
	   }
	   value = stringLine.substr(stringLine.find("=")+1);

///	   
///	   value = trim(value);
	   
	   if (value.find("#") != string::npos)
	      value = value.substr(0,value.find("#"));
	   if (value.find("\"") == string::npos)
	      value = "\"" + value + "\"";
	   varptr->setValue(value);
	   varptr = NULL;

// Powertweak hack
if (filename == "/etc/powertweak/tweaks")
{
     // test if RCVariable "varname" exists in RCVariableMap
     RCVariableMap::iterator it = RCVariables.find(varname);

     if (it != RCVariables.end())
     {
	// found: set values of found entry
	varptr = &it->second;

	value = "/" + powertweak;

	// set branch of the RCVariable
	{
	   varptr->setBranch(value + "/" + downcase(varname));

	   string rest_dir = value;
	   string dirname = "";
	   string lowleveldir = value.substr(value.rfind('/')+1);

	   while (rest_dir.find('/') != string::npos)
	   {
	      dirname  = rest_dir.substr(rest_dir.find('/')+1);
	      rest_dir = dirname;
	      if (dirname.find('/')!=string::npos)
		 dirname = dirname.substr(0,dirname.find('/'));

	      // find dirname in RCDirectories
	      if (dirname != "")
	      {
		 RCDirectoryMap::iterator dir_it = RCDirectories.find(dirname);

		 if (dir_it == RCDirectories.end())
		 {
		    // not found: create new entry in map
		    // RCDirectories
		    dirptr = new RCDirectory;
		    dirptr->setName(dirname);

		    if (value.substr(0,value.find((string)"/" + dirname)).empty())
		    {
		       dirptr->setBranch("/");
		    }
		    else
		    {
		       dirptr->setBranch(value.substr(0,value.find((string)"/" + dirname)));
		       *dirPath = ((string)(value.substr(0,value.find((string)"/" + dirname))));
		       //if (*dirPath != "")
		       //DirectorySet.insert(*dirPath);
		    }
		    RCDirectories[dirname] = *dirptr;
		    dirptr = NULL;
		 }
		 else
		 {
		    // found: set values of found entry
		    dirptr = &dir_it->second;
		    dirptr = NULL;
		 }
	      }
	   }
	   RCDirectoryMap::iterator dir_it = RCDirectories.find(lowleveldir);

	   if (dir_it != RCDirectories.end())
	   {
	      // found: add variable name to current lowlevel
	      // directory
	      dirptr = &dir_it->second;
	      dirptr->addVariable(varname);
	      dirptr = NULL;
	   }
	}

	// set datatype of the RCVariable
	varptr->setDatatype("integer");

	// set the typedef of the RCVariable
	varptr->setTypedef("not_strict");
     }
}
	   
	}
     }
     fin_filename.close();
  }

  ///////////////////////////////////////////////////////////////////
  //
  // Get input from EDDB in /usr/lib/YaST2/meta_rc.config
  //
  ///////////////////////////////////////////////////////////////////

  ifstream fin(meta_rc_config);
  if(!fin)
  {
     // must be written to y2log file
     cout << "Unable to open file \'"
	  << meta_rc_config
	  << " \' for reading.\n";
  }
  while (fin.getline(line,INPUT_LINE_LENGTH))
  {
     // todo: better filter for comments
     stringLine = (string)line;

     if ( stringLine.find('#') != string::npos )
	stringLine = stringLine.substr(0,stringLine.find('#'));

     if (stringLine.empty())
	continue;

      // get the variable name
     varname = stringLine.substr(0,stringLine.find(' '));

     // test if RCVariable "varname" exists in RCVariableMap
     RCVariableMap::iterator it = RCVariables.find(varname);

     if (it != RCVariables.end())
     {
	// found: set values of found entry
	varptr = &it->second;

	  // get property and value
	rest     = after_any(stringLine," \t");
	property = rest.substr(0,rest.find(' '));
	value    = after_any(rest," \t");

	// set branch of the RCVariable
	if (property == "path")
	{
	   varptr->setBranch(value + "/" + downcase(varname));

	   string rest_dir = value;
	   string dirname = "";
	   string lowleveldir = value.substr(value.rfind('/')+1);

	   while (rest_dir.find('/') != string::npos)
	   {
	      dirname  = rest_dir.substr(rest_dir.find('/')+1);
	      rest_dir = dirname;
	      if (dirname.find('/')!=string::npos)
		 dirname = dirname.substr(0,dirname.find('/'));

	      // find dirname in RCDirectories
	      if (dirname != "")
	      {
		 RCDirectoryMap::iterator dir_it = RCDirectories.find(dirname);

		 if (dir_it == RCDirectories.end())
		 {
		    // not found: create new entry in map
		    // RCDirectories
		    dirptr = new RCDirectory;
		    dirptr->setName(dirname);

		    if (value.substr(0,value.find((string)"/" + dirname)).empty())
		    {
		       dirptr->setBranch("/");
		    }
		    else
		    {
		       dirptr->setBranch(value.substr(0,value.find((string)"/" + dirname)));
		       *dirPath = ((string)(value.substr(0,value.find((string)"/" + dirname))));
		       //if (*dirPath != "")
		       //DirectorySet.insert(*dirPath);
		    }
		    RCDirectories[dirname] = *dirptr;
		    dirptr = NULL;
		 }
		 else
		 {
		    // found: set values of found entry
		    dirptr = &dir_it->second;
		    dirptr = NULL;
		 }
	      }
	   }
	   RCDirectoryMap::iterator dir_it = RCDirectories.find(lowleveldir);

	   if (dir_it != RCDirectories.end())
	   {
	      // found: add variable name to current lowlevel
	      // directory
	      dirptr = &dir_it->second;
	      dirptr->addVariable(varname);
	      dirptr = NULL;
	   }
	}
	// set datatype of the RCVariable
	else if (property == "type")
	{
	   // enum
	   if (value.find("enum") == 0)
	   {
	      varptr->setDatatype("enum");
	      string options = after(value,"enum ");
	      substitute(options,",", "\",\n      \"");
	      varptr->setOptions(options + "\n      ");
	   }
	   // boolean
	   else if (value.find("boolean") == 0)
	   {
	      varptr->setDatatype("boolean");
	      varptr->setOptions("\"yes\",\n      \"no\"\n      ");
	   }
	   // default
	   else
	      varptr->setDatatype(value);
	}
	// set the typedef of the RCVariable
	// ("strict" or "not_strict")
	else if (property == "typedef")
	   varptr->setTypedef(value);
     }
     else
     {
	// variable name not found in map RCVariables: so it
	// could be a directory descr.
	rest     = after_any(stringLine," \t");
	property = rest.substr(0,rest.find(' '));
	value    = after_any(rest," \t");

	// save all(!) descriptions of directories in a StringMap
	if (property == "descr")
	   DirectoryDescriptions[varname] = value;
     }
  }
  // close file input stream
  fin.close();

  // Iterate all variables if their branch is "/etc/...", then
  // this variable has to be put into the variable list of the
  // "etc" RCDirectory.
  if ( !firewall_mode )
  {
     for(RCVariableMap::iterator variable_it = RCVariables.begin();
	 variable_it != RCVariables.end();
	 ++variable_it)
     {
	if (variable_it->second.getBranch().find("/etc/")!=string::npos)
	{
	   RCDirectoryMap::iterator dir_it = RCDirectories.find("etc");
	   if (dir_it == RCDirectories.end())
	      continue;

	   // found: add variable name to current lowlevel directory
	   dirptr = &dir_it->second;
	   dirptr->addVariable(variable_it->first);
	   dirptr = NULL;
	}
     }
  }

  ///////////////////////////////////////////////////////////////////
  //
  // Generate branch, parent and entrynb of the RCVariables if there
  // are less than 5 (=MAX_VARS_IN_DIR) variables in the directory.
  // Create the neccesary subdirectories if there are more than 5
  // variables in this directory.
  //
  ///////////////////////////////////////////////////////////////////

  // iterate all directories
  for (RCDirectoryMap::iterator ci = RCDirectories.begin();
       ci != RCDirectories.end(); ++ci)
    {
      // set the descriptions of the directories
      StringMap::iterator string_it = DirectoryDescriptions.find(ci->first);
      if (string_it != DirectoryDescriptions.end())
	ci->second.setDescr(string_it->second);

      // get the variables located in the current directory
      StringVector sv = ci->second.getVariableVector();

      // switch the number of variables per directory
      int varnum = ci->second.getNumberOfVariables();

      if (varnum <= MAX_VARS_IN_DIR)
	{
	  // iterate all variables in the current directory: set
	  // branch, parent and entrynb
	  int entrynb = 1;
	  for (StringVector::const_iterator cii = sv.begin();
	       cii != sv.end();
	       ++cii)
	    {
	      RCVariable* var_ptr = &RCVariables[*cii];
	      var_ptr->setBranch(var_ptr->getBranch().substr(0,var_ptr->getBranch().find("/" + downcase(*cii))));
	      var_ptr->setParent(ci->first);
	      var_ptr->setEntrynb(entrynb++);

	      *dirPath = var_ptr->getBranch();
	      DirectorySet.insert(*dirPath);

	      var_ptr = NULL;
	    }
	}
      else if (varnum > MAX_VARS_IN_DIR)
	{
	  // more than 5 variables in this directory
	  StringVector sv = ci->second.getVariableVector();

	  // iterate all variables in the current directory: create
	  // new directories with the downcased name of the variable
	  for (StringVector::const_iterator cii = sv.begin();
	       cii != sv.end();
	       ++cii)
	    {
	      RCDirectory* dir_ptr = new RCDirectory;
	      dir_ptr->setName(downcase(*cii));

	      // if branch is "/" no extra slash must be included
	      if (ci->second.getBranch() == "/")
		dir_ptr->setBranch(ci->second.getBranch() + ci->second.getName());
	      else
		dir_ptr->setBranch(ci->second.getBranch() + "/" + ci->second.getName());

	      dir_ptr->addVariable(*cii);
	      NewRCDirectories[downcase(*cii)] = *dir_ptr;

	      *dirPath = ((string)(ci->second.getBranch() + "/"
				   + ci->second.getName()
				   + "/" + downcase(*cii)));
	      DirectorySet.insert(*dirPath);

	      dir_ptr = NULL;
	    }
	  ci->second.clearVariableVector();
	}
    }

  ///////////////////////////////////////////////////////////////////
  //
  // Output of the maps:
  //  - RCVariables
  //  - RCDirectories
  //  - NewRCDirectories
  // into the file /usr/lib/YaST2/rc_config_keys
  //
  ///////////////////////////////////////////////////////////////////

  // open new output file stream
  ofstream fout_rc_config_keys(rc_config_keys);
  if(!fout_rc_config_keys)
    {
      cout << "Unable to open file \'"
	   << rc_config_keys
	   << " \' for writing.\n";
      return(1);
    }

  // special string for the beginning of a ycp-list
  fout_rc_config_keys << "$[" << endl;

  // print all elements of the map RCVariables to fout
  RCVariableMap::const_iterator ci_variables = RCVariables.begin();
  fout_rc_config_keys << "  \""
		      << ci_variables->first
		      << ci_variables->second;
  ++ci_variables;

  for (; ci_variables != RCVariables.end(); ++ci_variables )
    fout_rc_config_keys << ",\n  \""
			<< ci_variables->first
			<< ci_variables->second;

  fout_rc_config_keys << ",\n";

  // print all elements of RCDirectories to fout
  RCDirectoryMap::const_iterator ci_directories = RCDirectories.begin();
  fout_rc_config_keys << "  \""
		      << ci_directories->first
		      << ci_directories->second;
  ++ci_directories;

  for (; ci_directories != RCDirectories.end(); ++ci_directories )
    fout_rc_config_keys << ",\n  \""
			<< ci_directories->first
			<< ci_directories->second;

  fout_rc_config_keys << ",\n";

  // print all elements of NewRCDirectories to fout
  RCDirectoryMap::const_iterator ci_newdirectories = NewRCDirectories.begin();
  if( ci_newdirectories !=  NewRCDirectories.end())
  {
     fout_rc_config_keys << "  \""
			 << ci_newdirectories->first
			 << ci_newdirectories->second;
     ++ci_newdirectories;

     for (; ci_newdirectories != NewRCDirectories.end(); ++ci_newdirectories )
	fout_rc_config_keys << ",\n  \""
			    << ci_newdirectories->first
			    << ci_newdirectories->second;
  }

  fout_rc_config_keys << "\n]" << endl;

  // close fout
  fout_rc_config_keys.close();

  ///////////////////////////////////////////////////////////////////
  //
  // Build tree
  //
  ///////////////////////////////////////////////////////////////////

  StringList* rootPtr = new StringList;

  for (StringSet::const_iterator ci = DirectorySet.begin();
       ci != DirectorySet.end();
       ++ci)
    {
      // ignore empty strings
      if (((string)*ci) != "")
	{
	  // array for the splitted directory paths
	  string words[MAX_DIR_DEPTH+1];

	  // split the path at "/" and count the number of substrings
	  int numOfWords = split(*ci, words, MAX_DIR_DEPTH, (string)"/");

	  // iterate each substring
	  for (int i = 1; i < numOfWords; ++i)
	    {
	      // found directory to insert into "root" list
	      if (words[i-1] == "")
		{
		  // insert only if not already exists in "root" list
		  bool found = false;
		  for (StringList::iterator it = rootPtr->begin();
		       it != rootPtr->end();
		       ++it)
		    {
		      if (*it == words[i])
			{
			  found = true;
			  break;
			}
		    }
		  if (!found && words[i] != "")
		    rootPtr->push_back(words[i]);
		}
	      else
		{
		  // create new node in the tree
		  dirTree[words[i-1]].setName(words[i-1]);

		  // add the substring at [i] to the list of the created node
		  StringList* listPtr = dirTree[words[i-1]].getStringListPtr();
		  listPtr->push_back(words[i]);
		  listPtr->unique();
		}
	    }
	}
    }

  showList(*rootPtr);


  // while the tree is not empty
  while (!dirTree.empty())
    {
      // iterate all elements in "root" list
      for (StringList::iterator strlistit = rootPtr->begin();
	   strlistit != rootPtr->end();
	   ++strlistit)
	{
	  if ((string)*strlistit == "")
	    continue;

	  // treeIt poinst to the tree node with name "*strlistit"
	  Tree::iterator treeIt = dirTree.find(*strlistit);

	  // tree node found
	  if (treeIt != dirTree.end())
	    {
	      // get the string list of this node and insert into the root
	      // list all entries of this list.
	      StringList strList = treeIt->second.getStringList();
	      rootPtr->insert(++strlistit, 1, "[");
	      rootPtr->insert(strlistit, 1, "]");
	      rootPtr->splice(--strlistit, strList);

	      // delete tree node from tree
	      dirTree.erase(treeIt->first);
	    }
	}
    }

  rootPtr->push_front("[");
  rootPtr->push_back("];");

  // Write directory tree to file
  writeListToFile(rootPtr, tree_data);

  return 0;
}
// end: int main()

/////////////////////////////////////////////////////////////////////
//
// Some other method implementations
//
/////////////////////////////////////////////////////////////////////

template<class T, class A>
void showMap(const map<T, A>& v)
{
    typename map<T, A>::const_iterator ci = v.begin();
    cout << "  \"" << ci->first << ci->second;
    ++ci;

    for (; ci != v.end(); ++ci )
	cout << ",\n  \"" << ci->first << ci->second;
}

template<class T>
void showSet(const set<T>& v)
{
    for (typename set<T>::const_iterator ci = v.begin(); ci != v.end(); ++ci)
	cout << (string)*ci << endl;
}

template<class T>
void showList(const list<T>& v)
{
    for (typename list<T>::const_iterator ci = v.begin(); ci != v.end(); ++ci)
	cout << (string)*ci << " ";
    cout << endl;
}

template<class T>
void writeListToFile(const list<T>* rootPtr, const char* filename)
{
  ofstream fout(filename);
  if(!fout)
    cout << "Unable to open file \'"
	 << filename
	 << " \' for writing.\n";

  for (StringList::const_iterator ci = rootPtr->begin();
       ci != rootPtr->end();
       ++ci)
    {
      StringList::const_iterator ci_next = ++ci;
      --ci;

      if ((string)*ci == "]")
	{
	  if ((string)*ci_next == "]" || (string)*ci_next == "];")
	    fout << " ]) ";
	  else
	    fout << " ]), ";
	}
      else if ((string)*ci == "];")
	fout << " ] ";
      else if ((string)*ci == "[")
	fout << " [ ";
      else if ((string)*ci_next == "[")
	fout << "\n  `item(`id(\""
	     << (string)*ci
	     << "\"), \""
	     << (string)*ci
	     << "\", false, ";
      else if ((string)*ci_next == "]" || (string)*ci_next == "];" )
	fout << " `item(`id(\""
	     << (string)*ci
	     << "\"), \""
	     << (string)*ci
	     << "\", false) ";
      else
	fout << " `item(`id(\""
	     << (string)*ci
	     << "\"), \""
	     << (string)*ci
	     << "\", false), ";
    }
  fout.close();
}

void showTree(const Tree& v)
{
  for (Tree::const_iterator ci = v.begin(); ci != v.end(); ++ci )
    {
      cout << ci->second << " : ";

      StringList strlist = ((ci->second).getStringList());

      for (StringList::const_iterator cii = strlist.begin();
	   cii != strlist.end();
	   ++cii)
	cout << (string)*cii << " ";
      cout << "\n";
    }
}
