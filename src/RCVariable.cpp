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
 
  File:       RCVariable.cpp
 
  Author:     Michael K"ohrmann <curry@suse.de>
 
*/

/*!
  \file RCVariable.cpp
  \author Michael K&ouml;hrmann, <curry@suse.de>
  \date 13.02.2001
  \version 0.2

  Project: YaST2, RC-Config-Editor

  Implementation of the RCVariable class.
*/

#include "RCVariable.h"

RCVariable::RCVariable()
{
  itsName     = new String("");
  itsBranch   = new String("");
  itsDatatype = new String("string");
  itsDescr    = new String("");
  itsEntrynb  = new int(1);
  itsOptions  = new String("");
  itsParent   = new String("");
  itsPath     = new String("");
  itsType     = new String("`options");
  itsTypedef  = new String("strict");
  itsValue    = new String("");
}

RCVariable::RCVariable(const RCVariable & rhs)
{
  itsName     = new String;
  itsBranch   = new String;
  itsDatatype = new String;
  itsDescr    = new String;
  itsEntrynb  = new int;
  itsOptions  = new String;
  itsParent   = new String;
  itsPath     = new String;
  itsType     = new String;
  itsTypedef  = new String;
  itsValue    = new String;

  *itsName     = rhs.getName();
  *itsBranch   = rhs.getBranch();
  *itsDatatype = rhs.getDatatype();
  *itsDescr    = rhs.getDescr();
  *itsEntrynb  = rhs.getEntrynb();
  *itsOptions  = rhs.getOptions();
  *itsParent   = rhs.getParent();
  *itsPath     = rhs.getPath();
  *itsType     = rhs.getType();
  *itsTypedef  = rhs.getTypedef();
  *itsValue    = rhs.getValue();
}

RCVariable::~RCVariable()
{
  delete itsName;
  delete itsBranch;
  delete itsDatatype;
  delete itsDescr;
  delete itsEntrynb;
  delete itsOptions;
  delete itsParent;
  delete itsPath;
  delete itsType;
  delete itsTypedef;
  delete itsValue;

  itsName     = NULL;
  itsBranch   = NULL;
  itsDatatype = NULL;
  itsDescr    = NULL;
  itsEntrynb  = NULL;
  itsOptions  = NULL;
  itsParent   = NULL;
  itsPath     = NULL;
  itsType     = NULL;
  itsTypedef  = NULL;
  itsValue    = NULL;
}

