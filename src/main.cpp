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

#include <iostream.h>
#include <String.h>
#include <map.h>
#include <set.h>
#include <list.h>
#include <fstream.h>
#include <glob.h>
#include <unistd.h>
#include "RCVariable.h"
#include "RCDirectory.h"
#include "TreeNode.h"

using namespace std;

/////////////////////////////////////////////////////////////////////
//
// Typedefs
//
/////////////////////////////////////////////////////////////////////

/*!
  RCVariableMap is a container for all RCVariables.
  The key is the name of the variable.
 */
typedef map<String, RCVariable> RCVariableMap;

/*!
  RCDirectoryMap is a container for all RCDirectories.
  The key is the name of the directory.
 */
typedef map<String, RCDirectory> RCDirectoryMap;

/*!
  StringMap is a container for the Descriptions of the RCDirectories.
  The key is the name of the variable. This container is neccesary
  because the directories are not created when the EDDB is read.
 */
typedef map<String, String> StringMap;

/*!
  StringSet is a container for Strings. It is used as container for
  all directory paths.
 */
typedef set<String> StringSet;

/*!
  StringList is a container for Strings. It is used as container for
  the directory tree in shape of a list.
*/
typedef list<String> StringList;

/*!
  Tree is a container for the directory tree.
*/
typedef map<String, TreeNode> Tree;

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
int main()
{
  // some constants
  const int FILENAME_LENGTH   =   255;
  const int INPUT_LINE_LENGTH = 32768;
  const int MAX_VARS_IN_DIR   =     5;
  const int MAX_DIR_DEPTH     =    20;

  // variables for the file names
  const char meta_rc_config[FILENAME_LENGTH] = "/usr/lib/YaST2/meta_rc.config";
  const char rc_config_keys[FILENAME_LENGTH] = "/usr/lib/YaST2/rc_config_keys";
  const char tree_data[FILENAME_LENGTH]      = "/usr/lib/YaST2/tree_data";
  //  const char rc_config_keys[FILENAME_LENGTH] = "rc_config_keys";
  //  const char tree_data[FILENAME_LENGTH]      = "tree_data";
  //  const char y2log[FILENAME_LENGTH]          = "var/log/y2log";

  // array of all file patterns to search for rc.config files
  const char* globpattern[] = {
    "/etc/rc.config.d/*rc.config",
    "/etc/rc.config",
    "/etc/rc.dialout"
  };

  // struct for glob() (see: man 3 glob)
  glob_t globbuffer;

  // some pointers
  RCVariable* varptr  = NULL;
  RCDirectory* dirptr = new RCDirectory();
  String* dirPath     = new String;

  // some containers
  RCVariableMap  RCVariables;
  RCDirectoryMap RCDirectories;
  RCDirectoryMap NewRCDirectories;
  StringMap      DirectoryDescriptions;
  StringSet      DirectorySet;
  StringList     dirList;
  StringList     rcFileList;
  Tree           dirTree;

  // some String and char variables
  char   line[INPUT_LINE_LENGTH + 1];
  String stringLine;
  String filename;
  String varname;
  String value;
  String descr;
  String rest;
  String property;

  // initially push directory /etc in the directory map
  dirptr->setName("etc");
  dirptr->setBranch("/");
  dirptr->setDialogtype("dir");
  RCDirectories["etc"] = *dirptr;
  dirptr = NULL;

  // add the directories "/" and "/etc" to the directory set
  *dirPath = (String)"/";
  DirectorySet.insert(*dirPath);
  *dirPath = (String)"/etc";
  DirectorySet.insert(*dirPath);

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
	rcFileList.push_back((String)globbuffer.gl_pathv[i]);
    }

  // Open every existing rc.config file in the array and save the
  // variables in the RCVariables map.
  for (StringList::const_iterator filenameit = rcFileList.begin();
       filenameit != rcFileList.end();
       ++filenameit) 
    {
      //filename = globbuffer.gl_pathv[i];
      filename = *filenameit;
      ifstream fin_filename(filename);
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
	  stringLine = (String)line;
	  
	  // filters all comments
	  if ( stringLine.contains("#") )
	    {
	      descr = descr + stringLine.after("#");
	      rest  = stringLine.before("#");
	      rest.gsub(RXwhite,"");

	      // if there is nothing necessary before the comment
	      // sign go on to the next input line
	      if (rest == "")
		continue;
	    }

	  // a valid rc.config variable defintion must contain a "="
	  if (!stringLine.contains("="))
	    continue;

	  // get the names of rc.config variables
	  varname = stringLine.before("=");

	  // delete some special entries in the rc.config files
	  if (varname.contains("test"))
	    continue;

	  // filters empty strings
	  varname.gsub(RXwhite, "");
	  if (varname != "")
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
		  // not found: create new entry in RCVariableMap and
		  // set branch, parent, path, ...
		  varptr = new RCVariable;
		  varptr->setName(varname);
		  varptr->setBranch("/etc/" + downcase(varname));
		  varptr->setParent(downcase(varname));
		  if (filename == "/etc/rc.config")
		    {
		      varptr->setPath(".rc.system." + varname);
		    }
		  else if (!filename.contains(".rc.config"))
		    {
		      String base = filename.after("/etc/rc.");
		      varptr->setPath(".rc." + base + "." + varname);
		    }
		  else
		    {
		      String base = filename.after("/etc/rc.config.d/");
		      base        = (String)base.before(".rc.config");
		      varptr->setPath(".rc." + base + "." + varname);
		    }

		  // add descr to RCVariable and afterwards set descr
		  // to "", filter comments
		  descr.gsub("\"", "\\\"");
		  descr.gsub("#", "");
		  while (descr.contains("  "))
		    descr.gsub("  ", " ");
		  varptr->setDescr(descr);
		  descr = "";
		  RCVariables[varname] = *varptr;
		}
	      value = stringLine.after("=");
	      if (value.contains("#"))
		value = value.before("#");
	      if (!value.contains("\""))
		value = "\"" + value + "\"";
	      varptr->setValue(value);
	      varptr = NULL;
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
      stringLine = (String)line;

      if ( stringLine.contains("#") )
	stringLine = stringLine.before("#");

      if (stringLine == "")
	continue;

      // get the variable name
      varname = stringLine.before(" ");
      
      // test if RCVariable "varname" exists in RCVariableMap
      RCVariableMap::iterator it = RCVariables.find(varname);

      if (it != RCVariables.end())
	{
	  // found: set values of found entry
	  varptr = &it->second;
  
	  // get property and value
	  rest     = stringLine.after(RXwhite);
	  property = rest.before(" ");
	  value    = rest.after(RXwhite);
	
	  // set branch of the RCVariable
	  if (property == "path") 
	    {
	      varptr->setBranch(value + "/" + downcase(varname));

	      String rest_dir = value;
	      String dirname = "";
	      String lowleveldir = value.after(value.index("/", -1));

	      while (rest_dir.contains("/"))
		{
		  dirname  = rest_dir.after("/");
		  rest_dir = dirname;
		  if (dirname.contains("/"))
		    dirname = dirname.before("/");

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

			  if (value.before("/" + dirname) == "")
			    {
			      dirptr->setBranch("/");
			    }
			  else
			    {
			      dirptr->setBranch(value.before("/" + dirname));
			      *dirPath = ((String)(value.before("/" + dirname)));
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
	      if (value.index("enum") == 0)
		{
		  varptr->setDatatype("enum");
		  String options = value.after("enum ");
		  options.gsub(",", "\",\n      \"");
		  varptr->setOptions(options + "\n      ");
		}
	      // boolean
	      else if (value.index("boolean") == 0)
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
	  rest     = stringLine.after(RXwhite);
	  property = rest.before(' ');
	  value    = rest.after(RXwhite);
	  
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
  for(RCVariableMap::iterator variable_it = RCVariables.begin();
      variable_it != RCVariables.end();
      ++variable_it)
    {
      if (variable_it->second.getBranch().contains("/etc/"))
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
	      var_ptr->setBranch(var_ptr->getBranch().before("/" + downcase(*cii)));
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

	      *dirPath = ((String)(ci->second.getBranch() + "/" 
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
  fout_rc_config_keys << "  \"" 
		      << ci_newdirectories->first 
		      << ci_newdirectories->second;
  ++ci_newdirectories;

  for (; ci_newdirectories != NewRCDirectories.end(); ++ci_newdirectories )
    fout_rc_config_keys << ",\n  \"" 
			<< ci_newdirectories->first 
			<< ci_newdirectories->second;

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
      if (((String)*ci) != "")
	{
	  // array for the splitted directory paths
	  String words[MAX_DIR_DEPTH+1];

	  // split the path at "/" and count the number of substrings
	  int numOfWords = split(*ci, words, MAX_DIR_DEPTH, (String)"/");

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
	  if ((String)*strlistit == "")
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
  map<T, A>::const_iterator ci = v.begin();
  cout << "  \"" << ci->first << ci->second;
  ++ci;

  for (; ci != v.end(); ++ci )
    cout << ",\n  \"" << ci->first << ci->second;
}

template<class T>
void showSet(const set<T>& v)
{
  for (set<T>::const_iterator ci = v.begin(); ci != v.end(); ++ci)
    cout << (String)*ci << endl;
}

template<class T>
void showList(const list<T>& v)
{
  for (list<T>::const_iterator ci = v.begin(); ci != v.end(); ++ci)
    cout << (String)*ci << " ";
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

      if ((String)*ci == "]")
	{
	  if ((String)*ci_next == "]" || (String)*ci_next == "];")
	    fout << " ]) ";
	  else
	    fout << " ]), ";
	}
      else if ((String)*ci == "];")
	fout << " ] ";
      else if ((String)*ci == "[")
	fout << " [ ";
      else if ((String)*ci_next == "[")
	fout << "\n  `item(`id(\"" 
	     << (String)*ci 
	     << "\"), \"" 
	     << (String)*ci 
	     << "\", false, ";
      else if ((String)*ci_next == "]" || (String)*ci_next == "];" )
	fout << " `item(`id(\"" 
	     << (String)*ci 
	     << "\"), \"" 
	     << (String)*ci 
	     << "\", false) ";
      else
	fout << " `item(`id(\"" 
	     << (String)*ci 
	     << "\"), \"" 
	     << (String)*ci 
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
	cout << (String)*cii << " ";
      cout << "\n";
    }
}
// end: main.cpp
