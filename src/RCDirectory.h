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
 
  File:       RCDirectory.h
 
  Author:     Michael K"ohrmann <curry@suse.de>
 
*/

/*!
  \file RCDirectory.h

  Project: YaST2, RC-Config-Editor

  Header file of the RCDirectory class.
*/

#ifndef __RCDIRECTORY_H
#define __RCDIRECTORY_H

#include <String.h>
#include <vector.h>
#include <iostream.h>

using namespace std;

//typedef vector<RCVariable*> RCVarVector;
typedef vector<String> StringVector;

/*!
  \class RCDirectory
  \brief Data structure to hold all informations about the directories
         needed by the RC-Config-Editor.
  \author Michael K&ouml;hrmann, <curry@suse.de>
  \version 0.2
  \date 13.02.2001
  
  Objects of this class represent all information about the directories
  needed by the RC-Config-Editor.
 */
class RCDirectory
{
 public:
  ////////////////////////////////////////////////////////////////////////////////
  // constructors, destructors
  ////////////////////////////////////////////////////////////////////////////////

  /*!
    \fn RCDirectory()

    Constructor.
   */
  RCDirectory();

  /*!
    \fn RCDirectory(const RCDirectory &)

    Copy constructor.
   */
  RCDirectory(const RCDirectory &);

  /*!
    \fn ~RCDirectory()

    Destructor.
   */
  ~RCDirectory();

  ////////////////////////////////////////////////////////////////////////////////
  // get methods
  ////////////////////////////////////////////////////////////////////////////////

  /*!
    Get the Name of the current directory.<br>
    e.g.: <code>Usb</code> 

    \return The name of the current RCDirectory as a String.
  */
  String getName() const { return *itsName; }

  /*!
    Get the branch of the directory.<br>
    e.g.: <code>`branch : "/Hardware"</code>

    \return The branch of the current RCDirectory.
  */
  String getBranch() const { return *itsBranch; }

  /*!
    Get the description of the directory saved in the EDDB file
    <code>/usr/lib/YaST2/meta_rc.config</code>.<br>
    e.g.: <code>`descr : "<p></p> <p>Configuration of USB controllers</p>"</code>

    \return The description of the current directory.
  */
  String getDescr() const { return *itsDescr; }

  /*!
    Get the dialogtype of the directory.<br>
    e.g.: <code>`dialogtype : "d2"</code>

    \return The type of dialog to display in the editor.
  */
  String getDialogtype() const { return *itsDialogtype; }
 
  /*!
    Get the variable vector of the current directory.

    \return The Vector of variable names.
  */
  StringVector getVariableVector() const { return *itsVariableVector; }

  /*!
    Get the number of variables located in the current directory.

    \return The number of variables.
  */
  int getNumberOfVariables() const { return *itsNumberOfVariables; }

  ////////////////////////////////////////////////////////////////////////////////
  // set methods
  ////////////////////////////////////////////////////////////////////////////////

  /*!
    Set the name of the RCDirectory.
    
    \param String name.
   */
  void setName( String name ) { *itsName = name; }

  /*!
    Set the branch of the directory.

    \param String branch.
   */
  void setBranch( String branch ) { *itsBranch = branch; }

  /*!
    Set the description of the RCDirectory.

    \param String descr.
   */
  void setDescr( String descr ) { *itsDescr = descr; }

  /*!
    Set the dialogtype of the directory.

    \param String dialogtype.
   */
  void setDialogtype( String dialogtype ) { *itsDialogtype = dialogtype; }

  /*!
    Set the variable vector.

    \param StringVector varvector.
   */
  void setVariableVector( StringVector varvector) { *itsVariableVector = varvector; }

  ////////////////////////////////////////////////////////////////////////////////
  // other methods
  ////////////////////////////////////////////////////////////////////////////////

  /*!
    Add a name of a RCVariable to the VariableVector of the current RCDirectory.

    \param String varname.
   */
  void addVariable( String varname )
    {
      itsVariableVector->push_back(varname);
      increaseNumberOfVariables();
      increaseDialogtype();
    }
  
  /*!
    Prints out all Variables located in the current directory.
  */
  const void printVariableVector()const
    {
      cout << *itsName << ":\n";
      for (unsigned int i = 0; i < itsVariableVector->size(); ++i)
	{
	  cout << "   " << (*itsVariableVector)[i] << "\n"; 
	}
    }
  
  /*!
    Delete all variable names in the variable vector and reset the number of saved
    variable names.
  */
  void clearVariableVector() const 
    { 
      itsVariableVector->resize(0);
      *itsNumberOfVariables = 0;
    }

  /*!
    Overloading function of the output stream operator <code><<</code>.
    e.g.: <pre>
    RCDirectory dir;
    dir.setName("Usb");
    dir.setBranch("/Hardware");
    dir.setDescr("<p></p> <p>Configuration of USB controllers</p>");
    dir.setDialogtype("d2");

    cout << dir;
    </pre>

    \param ostream& s
    \param const RCDirectory& x
    \return ostream&
   */
  friend ostream& operator<<(ostream& s, const RCDirectory& x)
    {
      String descr = "";
      if (x.getDescr() != "")
	{
	  descr = x.getDescr();
	}
      s << "\" : $[\n" << "    `branch : \"" << x.getBranch() << "\",\n";

      if (descr != "")
	s << "    `descr : "<< descr << ",\n";

      s << "    `dialogtype : \"" << x.getDialogtype() << "\"\n  ]";

      return s;
    }

 private:
  ////////////////////////////////////////////////////////////////////////////////
  // private members
  ////////////////////////////////////////////////////////////////////////////////

  //! Name of the RCDirectory.
  String *itsName;

  //! File path the current directory is in.
  String *itsBranch;

  //! Description of the current directory used by the Editor.
  String *itsDescr;

  /*!
    Dialogtype the Editor has to use for displaying the current directory.

    Example: <code>d3</code> means that there are three RCVariables to be
    displayed in the current directory.
  */
  String *itsDialogtype;

  /*!
    This Vector holds the names of all RCVariables that are located in 
    the current directory.
  */
  StringVector *itsVariableVector;

  /*!
    Every directory contains a specific number of variables.
   */
  int *itsNumberOfVariables;

  /////////////////////////////////////////////////////////////////////////
  // private methods
  /////////////////////////////////////////////////////////////////////////

  /*!
    Increases the number of variables placed in the current directory.
   */
  void increaseNumberOfVariables() { ++(*itsNumberOfVariables); }
  
  /*!
    Sets the dialogtype in relation to the number of variables placed in
    the current directory.
  */
  void increaseDialogtype();

  /*!
    Returns the vector in which all variables are saved that are located in
    the current directory.

    \return The vector in which all variables are saved that are located as a
    String.
   */
  String getDirectoryVectors() const
    {
      String ret = "\n        ";

      for (StringVector::const_iterator ci = itsVariableVector->begin();
	   ci != itsVariableVector->end();
	   ++ci)
	{
	  ret = ret + *ci + "\n        ";
	}
      return ret;
    }
};

#endif
