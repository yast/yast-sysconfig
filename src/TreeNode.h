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

using namespace std;

#include <String.h>
#include <list.h>

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
  String getName() const { return *itsName; }

  /*! 
    Get the StringList of the current TreeNode.

    \return The StringList of the current TreeNode.
  */
  list<String> getStringList() const { return *itsStringList; }

  /*! 
    Get a pointer to the StringList of the current TreeNode.

    \return A pointer to the StringList of the current TreeNode.
  */
  list<String>* getStringListPtr() const { return itsStringList; }

  ////////////////////////////////////////////////////////////////////////////////
  //
  // set methods
  //
  ////////////////////////////////////////////////////////////////////////////////

  /*!
    Set the name of the TreeNode.

    \param String name.
   */
  void setName( String name ) { *itsName = name; }

  /*!
    Set the StringList.

    \param list<String> stringlist.
   */
  void setStringList( list<String> stringlist ) { *itsStringList = stringlist; }

  ////////////////////////////////////////////////////////////////////////////////
  //
  // other methods
  //
  ////////////////////////////////////////////////////////////////////////////////

  //  void addString(String s);

  /*!
    Overloading function of the output stream operator <code><<</code>.
    
    \param ostream& s
    \param const TreeNode& x
    \return ostream&
  */
  friend ostream& operator<<(ostream& s, const TreeNode& x)
    {
      s << x.getName() << "\n";
      
      return s;
    }

 private:
  ////////////////////////////////////////////////////////////////////////////////
  //
  // private members
  //
  ////////////////////////////////////////////////////////////////////////////////

  //! Name of the TreeNode.
  String *itsName;

  //! The StringList of the current TreeNode.
  list<String> *itsStringList;
};

#endif
