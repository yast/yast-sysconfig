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

  File:       TreeNode.h

  Author:     Michael K"ohrmann <curry@suse.de>

*/

/*!
  \file TreeNode.h

  Project: YaST2, RC-Config-Editor

  Header file of the TreeNode class.
*/

#ifndef __TREENODE_H
#define __TREENODE_H

#include <iostream>
#include <string>
#include <list>

using std::string;
using std::list;
using std::ostream;


/*!
  \class TreeNode
  \brief Data structure.
  \author Michael K&ouml;hrmann <curry@suse.de>
  \version 0.2
  \date 13.02.2001
 */
class TreeNode
{
 public:
  ////////////////////////////////////////////////////////////////////////////////
  //
  // constructors, destructors
  //
  ////////////////////////////////////////////////////////////////////////////////

  /*!
    \fn TreeNode()

    Constructor.
   */
  TreeNode();

  /*!
    \fn TreeNode(const TreeNode &)

    Copy constructor.
   */
  TreeNode(const TreeNode &);

  /*!
    \fn ~TreeNode()

    Destructor.
   */
  ~TreeNode();

  ////////////////////////////////////////////////////////////////////////////////
  //
  // get methods
  //
  ////////////////////////////////////////////////////////////////////////////////

  /*!
    Get the name of the current TreeNode.

    \return The name of the curren TreeNode.
  */
  string getName() const { return *itsName; }

  /*!
    Get the StringList of the current TreeNode.

    \return The StringList of the current TreeNode.
  */
  list<string> getStringList() const { return *itsStringList; }

  /*!
    Get a pointer to the StringList of the current TreeNode.

    \return A pointer to the StringList of the current TreeNode.
  */
  list<string>* getStringListPtr() const { return itsStringList; }

  ////////////////////////////////////////////////////////////////////////////////
  //
  // set methods
  //
  ////////////////////////////////////////////////////////////////////////////////

  /*!
    Set the name of the TreeNode.

    \param string name.
   */
  void setName( string name ) { *itsName = name; }

  /*!
    Set the StringList.

    \param list<string> stringlist.
   */
  void setStringList( list<string> stringlist ) { *itsStringList = stringlist; }

  ////////////////////////////////////////////////////////////////////////////////
  //
  // other methods
  //
  ////////////////////////////////////////////////////////////////////////////////

  //  void addString(string s);

  /*!
    Overloading function of the output stream operator <code><<</code>.

    \param ostream& s
    \param const TreeNode& x
    \return ostream&
  */
  friend ostream& operator<<(ostream& s, const TreeNode& x)
  {
      s << x.getName() << '\n';
      return s;
  }

 private:
  ////////////////////////////////////////////////////////////////////////////////
  //
  // private members
  //
  ////////////////////////////////////////////////////////////////////////////////

  //! Name of the TreeNode.
  string *itsName;

  //! The StringList of the current TreeNode.
  list<string> *itsStringList;
};

#endif
