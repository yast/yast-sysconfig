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

  File:       RCVariable.h

  Author:     Michael K"ohrmann <curry@suse.de>

*/

/*!
  \file RCVariable.h

  Project: YaST2, RC-Config-Editor

  Header file of the RCVariable class.
*/

#ifndef __RCVARIABLE_H
#define __RCVARIABLE_H

#include <iostream.h>
#include <string>

using std::string;


/*!
  \class RCVariable
  \brief Data structure to hold all informations about a rc.config variable.
  \author Michael K&ouml;hrmann, <curry@suse.de>
  \version 0.2
  \date 13.02.2001

  Objects of this class represent all needed informations about variables
  of the configuration files <code>/etc/rc.config</code> and
  <code>/etc/rc.config.d/</code>.
 */
class RCVariable
{
 public:
  ////////////////////////////////////////////////////////////////////////////////
  // constructors, destructors
  ////////////////////////////////////////////////////////////////////////////////

  /*!
    \fn RCVariable()

    Constructor.
   */
  RCVariable();

  /*!
    \fn RCVariable(const RCVariable &)

    Copy constructor.
   */
  RCVariable(const RCVariable &);

  /*!
    \fn ~RCVariable()

    Destructor.
   */
  ~RCVariable();

  ////////////////////////////////////////////////////////////////////////////////
  // get methods
  ////////////////////////////////////////////////////////////////////////////////

  /*!
    Get the name of the current RCVariable.<br>
    e.g.: <code>ENABLE_SUSECONFIG</code>

    \return The name of the curren RCVariable.
  */
  string getName() const { return *itsName; }

  /*!
    Get the branch in which the RCVariable is saved in the
    variable tree.<br>
    e.g.: <code>`branch : "/Base-Administration/SuSEConfig/enable_suseconfig"</code>

    \return The branch.
  */
  string getBranch() const { return *itsBranch; }

  /*!
    Get the datatype of the RCVariable: i.e.
    <code>string</code>, <code>enum</code>,
    <code>boolean</code>, <code>integer</code>.<br>
    e.g.: <code>`datatype : "boolean"</code>

    \return The type of dialog to display in the editor.
  */
  string getDatatype() const { return *itsDatatype; }

  /*!
    Get the description of the RCVariable saved in the
    configuration files in
    <code>/etc/rc.config*</code>.<br>
    e.g.: <code>`descr : "Some people don't want SuSEconfig to
    modify the system..."</code>

    /return The description of the curren variable.
  */
  string getDescr() const { return *itsDescr; }

  /*!
    Get the number of other RCVariables saved in the same branch
    as the current one.<br>
    e.g.: <code>`entrynb : 1</code>

    \return The number of other variables in the directory
    of the current variable.
  */
  int getEntrynb() const { return *itsEntrynb; }

  /*!
    Get the list of possible values of the current RCVariable.<br>
    e.g.: <code>`options : [ "yes", "no" ] </code>

    \return The optional values the current variable can take.
  */
  string getOptions() const { return *itsOptions; }

  /*!
    Get the name of the parent directory.<br>
    e.g.: <code>`parent : "enable_suseconfig"</code>

    \return The parent directory.
   */
  string getParent() const { return *itsParent; }

  /*!
    Get the path of the configuration file the current
    RCVariable is defined in.<br>
    e.g.: <code>`path : .rc.system.ENABLE_SUSECONFIG</code>

    \return The path.
   */
  string getPath() const { return *itsPath; }

  /*!
    Get the type of the RCVariable. Commonly this ist `options.<br>
    e.g.: <code>`type : `options</code>

    \return The type of the variable.
   */
  string getType() const { return *itsType; }

  /*!
    Get the typedef of the RCVariable. Only <code>strict</code>
    or <code>not_strict</code>
    are allowed.<br>
    e.g.: <code>`typedef : "strict"</code>

    \return The type definition of the current variable.
   */
  string getTypedef() const { return *itsTypedef; }

  /*!
    Get the currently saved value of the RCVariable defined in one of the
    configuration files.<br>
    e.g.: <code>`value : "yes"</code>

    \return The actually set value of the variable.
   */
  string getValue() const { return *itsValue; }

  ////////////////////////////////////////////////////////////////////////////////
  // set methods
  ////////////////////////////////////////////////////////////////////////////////

  /*!
    Set the name of the RCVariable.

    \param string name.
   */
  void setName( string name ) { *itsName = name; }

  /*!
    Set the branch of the RCVariable.

    \param string branch.
   */
  void setBranch( string branch ) { *itsBranch = branch; }

  /*!
    Set the datatype of the RCVariable.

    \param string datatype.
   */
  void setDatatype( string datatype ) { *itsDatatype = datatype; }

  /*!
    Set the description of the RCVariable.

    \param string descr.
   */
  void setDescr( string descr ) { *itsDescr = descr; }

  /*!
    Set the entrynb of the RCVariable.

    \param int entrynb.
  */
  void setEntrynb( int entrynb ) { *itsEntrynb = entrynb; }

  /*!
    Set the options of the RCVariable.

    \param string options.
  */
  void setOptions( string options ) { *itsOptions = options; }

  /*!
    Set the parent directory of the RCVariable.

    \param string parent.
  */
  void setParent( string parent ) { *itsParent = parent; }

  /*!
    Set the path of the RCVariable.

    \param string path.
  */
  void setPath( string path ) { *itsPath = path; }

  /*!
    Set the type of the RCVariable.

    \param string typ.
  */
  void setType( string typ ) { *itsType = typ; }

  /*!
    Set the type definition of the RCVariable.

    \param string typed.
   */
  void setTypedef( string typed ) { *itsTypedef = typed; }

  /*!
    Set the value of the RCVariable. (Only in the map, not in the
    configuration file!)

    \param string value.
   */
  void setValue( string value ) { *itsValue = value; }

  ////////////////////////////////////////////////////////////////////////////////
  // other methods
  ////////////////////////////////////////////////////////////////////////////////

  /*!
    Overloading function of the output stream operator <code><<</code>.
    e.g.: <pre>
    RCVariable var;
    var.setName("ENABLE_SUSECONFIG");
    var.setBranch("/Base-Administration/SuSEConfig/enable_suseconfig");
    var.setDatatype("boolean");
    var.setDescr("Some people don't want SuSEconfig to modify the system.");
    var.setEntrynb(1);
    var.setOptions("yes","no");
    var.setParent("enable_suseconfig");
    var.setPath(".rc.system.ENABLE_SUSECONFIG");
    var.setType("'options");
    var.setTypedef("strict");
    var.setValue("yes");

    cout << var;
    </pre>

    \param ostream& s
    \param const RCVariable& x
    \return ostream&
   */
  friend ostream& operator<<(ostream& s, const RCVariable& x)
    {
      s << "\" : $[\n"
	<< "    `branch : \""       << x.getBranch()   << "\",\n"
	<< "    `datatype : \""     << x.getDatatype() << "\",\n"
	<< "    `descr : \""        << x.getDescr()    << "\",\n"
	<< "    `entrynb : "        << x.getEntrynb()  << ",\n"
	<< "    `options : [\n    " << x.getOptions()  << "],\n"
	<< "    `parent : \""       << x.getParent()   << "\",\n"
	<< "    `path : "           << x.getPath()     << ",\n"
	<< "    `type : "           << x.getType()     << ",\n"
	<< "    `typedef : \""      << x.getTypedef()  << "\",\n"
	<< "    `value : "          << x.getValue()    << "\n  ]";
      return s;
    }

 private:
  ////////////////////////////////////////////////////////////////////////////////
  // private members
  ////////////////////////////////////////////////////////////////////////////////

  //! Name of the RCVariable.
  string *itsName;

  //! Branch of the RCVariable.
  string *itsBranch;

  //! Datatype of the RCVariable.
  string *itsDatatype;

  //! Description of the RCVariable.
  string *itsDescr;

  //! Entrynb of the RCVariable.
  int    *itsEntrynb;

  //! Options of the RCVariable.
  string *itsOptions;

  //! Parent directory of the RCVariable.
  string *itsParent;

  //! Path of the RCVariable.
  string *itsPath;

  //! Type of the RCVariable.
  string *itsType;

  //! Typedef of the RCVariable.
  string *itsTypedef;

  //! Value of the RCVariable.
  string *itsValue;
};

#endif
