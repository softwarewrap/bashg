#!/bin/bash

_doc:macros:unit:demofunc()
{
   cat <<'EOF'

NAMESPACE PROTECTION: idioms in demofunc() in file _/doc/macros/unit/demo.sh

_doc:macros:unit:References

   PACKAGE

      \(@)_Var         (@)_Var          _doc___Var
      \(@:p)_Var       (@:p)_Var        p___Var
      \(@:.p)_Var      (@:.p)_Var       _doc_p___Var
      \(@@)_Var        (@@)_Var         ___Var

      \(@):Func        (@):Func         _doc:Func
      \(@:p):Func      (@:p):Func       p:Func
      \(@:.p):Func     (@:.p):Func      _doc.p:Func
      \(@@):Func       (@@):Func        :Func

      \(@)/Path        (@)/Path         "$_lib_dir/_/doc"/Path
      \(@:t/s)/Path    (@:t/s)/Path     "$_lib_dir"/t/s/Path
      \(@:.p)/Path     (@:.p)/Path      "$_lib_dir"/doc/p/Path
      \(@@)/Path       (@@)/Path        "$_lib_dir"/_/_/Path

   COMPONENT

      \(+)_Var         (+)_Var          _doc__macros___Var
      \(+:c)_Var       (+:c)_Var        _doc__c___Var
      \(+:p:c)_Var     (+:p:c)_Var      p__c___Var
      \(+:.p:c)_Var    (+:.p:c)_Var     _doc_p__c___Var
      \(++:c)_Var      (++:c)_Var       ___c___Var

      \(+):Func        (+):Func         _doc:macros:Func
      \(+:c):Func      (+:c):Func       _doc:c:Func
      \(+:p:c):Func    (+:p:c):Func     p:c:Func
      \(+:.p:c):Func   (+:.p:c):Func    _doc.p:c:Func
      \(++:c):Func     (++:c):Func      :c:Func

      \(+)/Path        (+)/Path         "$_lib_dir/_/doc/macros"/Path
      \(+:c)/Path      (+:c)/Path       "$_lib_dir/_/doc/c"/Path
      \(+:t/s:c)/Path  (+:t/s:c)/Path   "$_lib_dir/t/s/c"/Path
      \(+:.p:c)/Path   (+:.p:c)/Path    "$_lib_dir/doc/p/c"/Path
      \(++:c)/Path     (++:c)/Path      "$_lib_dir/_/_/c"/Path

   UNIT

      \(-)_Var         (-)_Var          _doc__macros__unit___Var
      \(-:u)_Var       (-:u)_Var        _doc__macros__u___Var
      \(-:c:u)_Var     (-:c:u)_Var      _doc__c__u___Var
      \(--:c:u)_Var    (--:c:u)_Var     ___c__u___Var

      \(-):Func        (-):Func         _doc:macros:unit:Func
      \(-:u):Func      (-:u):Func       _doc:macros:u:Func
      \(-:c:u):Func    (-:c:u):Func     _doc:c:u:Func
      \(--:c:u):Func   (--:c:u):Func    :c:u:Func

      \(-)/Path        (-)/Path         "$_lib_dir/_/doc/macros/unit"/Path
      \(-:u)/Path      (-:u)/Path       "$_lib_dir/_/doc/macros/u"/Path
      \(-:c:u)/Path    (-:c:u)/Path     "$_lib_dir/_/doc/c/u"/Path
      \(--:c:u)/Path   (--:c:u)/Path    "$_lib_dir/_/_/c/u"/Path

   FUNCTION VARIABLES
      \(.)_var         (.)_var          _doc__macros__unit__demo__demofunc___var

_doc:macros:unit:Function Declarations

   PACKAGE DECL            @ func()                      # @ must be in column 1
   COMPONENT DECL          + func()                      # + must be in column 1
   UNIT DECL               - func()                      # - must be in column 1

_doc:func()
_doc:macros:func()
_doc:macros:unit:func()
EOF
}
