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
 
  File:       TreeNode.cpp
 
  Author:     Michael K"ohrmann <curry@suse.de>
 
*/

/*!
  \file TreeNode.cpp
  \author Michael K&ouml;hrmann, <curry@suse.de>
  \date 13.02.2001
  \version 0.2

  Project: YaST2, RC-Config-Editor

  Implementation of the TreeNode class.
*/

#include "TreeNode.h"

TreeNode::TreeNode()
{
  itsName        = new String("");
  itsStringList  = new list<String>;
}

TreeNode::TreeNode(const TreeNode & rhs)
{
  itsName        = new String;
  itsStringList  = new list<String>;

  *itsName       = rhs.getName();
  *itsStringList = rhs.getStringList();
}

TreeNode::~TreeNode()
{
  delete itsName;
  delete itsStringList;

  itsName        = NULL;
  itsStringList  = NULL;
}
