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
 
  File:       RCDirectory.cpp
 
  Author:     Michael K"ohrmann <curry@suse.de>
 
*/

/*!
  \file RCDirectory.cpp
  \author Michael K&ouml;hrmann, <curry@suse.de>
  \date 13.02.2001
  \version 0.2

  Project: YaST2, RC-Config-Editor

  Implementation of the RCDirectory class.
*/

#include "RCDirectory.h"

RCDirectory::RCDirectory()
{
  itsName              = new String("");
  itsBranch            = new String("/");
  itsDescr             = new String("");
  itsDialogtype        = new String("dir");
  itsVariableVector    = new StringVector();
  itsNumberOfVariables = new int(0);
}

RCDirectory::RCDirectory(const RCDirectory & rhs)
{
  itsName              = new String;
  itsBranch            = new String;
  itsDescr             = new String;
  itsDialogtype        = new String;
  itsVariableVector    = new StringVector;
  itsNumberOfVariables = new int;

  *itsName              = rhs.getName();
  *itsBranch            = rhs.getBranch();
  *itsDescr             = rhs.getDescr();
  *itsDialogtype        = rhs.getDialogtype();
  *itsVariableVector    = rhs.getVariableVector();
  *itsNumberOfVariables = rhs.getNumberOfVariables();
}

RCDirectory::~RCDirectory()
{
  delete itsName;
  delete itsBranch;
  delete itsDescr;
  delete itsDialogtype;
  delete itsVariableVector;
  delete itsNumberOfVariables;

  itsName              = NULL;
  itsBranch            = NULL;
  itsDescr             = NULL;
  itsDialogtype        = NULL;
  itsVariableVector    = NULL;
  itsNumberOfVariables = NULL;
}


void RCDirectory::increaseDialogtype()
{
  switch (getNumberOfVariables())
    {
    case 0 :
      setDialogtype("dir");
      break;
    case 1 :
      setDialogtype("d1");
      break;
    case 2 :
      setDialogtype("d2");
      break;
    case 3 :
      setDialogtype("d3");
      break;
    case 4 :
      setDialogtype("d4");
      break;
    case 5 :
      setDialogtype("d5");
      break;
    default :
      setDialogtype("dir");
      break;
    }
}
