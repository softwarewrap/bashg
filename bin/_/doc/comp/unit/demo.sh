#!/bin/bash

_doc:comp:unit:func()
{
   cat <<'EOF'

NAMESPACE PROTECTION: idioms in demofunc() in file _/doc/macros/unit/demo.sh

_doc:comp:unit:References

   p: package s: sub-package  dirs:  _/_  _/s  p/_  p/s
   c: component
   u: unit

   PACKAGE

   \(@)_Var         (@)_Var          _doc___Var
   \(@:.s)_Var      (@:.s)_Var       _doc_s___Var
   \(@:p)_Var       (@:p)_Var        p___Var
   \(@@)_Var        (@@)_Var         ___Var
   \\(@@:.s)_Var     \(@@:.s)_Var      (@@:.s)_Var

   \(@):Func        (@):Func         _doc:Func
   \(@:.s):Func     (@:.s):Func      _doc.s:Func
   \(@:p):Func      (@:p):Func       p:Func
   \(@@):Func       (@@):Func        :Func
   \\(@@:.s):Func    \(@@:.s):Func     (@@:.s):Func

   \(@)/Path        (@)/Path         "$_lib_dir/_/doc"/Path
   \(@:.s)/Path     (@:.s)/Path      "$_lib_dir"/doc/s/Path
   \(@:p/s)/Path    (@:p/s)/Path     "$_lib_dir"/p/s/Path
   \(@@)/Path       (@@)/Path        "$_lib_dir"/_/_/Path
   \\(@@:.s)/Path    \(@@:.s)/Path     (@@:.s)/Path

   COMPONENT

   \(+)_Var         (+)_Var          _doc__comp___Var
   \(+:c)_Var       (+:c)_Var        _doc__c___Var
   \(+:.s:c)_Var    (+:.s:c)_Var     _doc_s__c___Var
   \(+:p:c)_Var     (+:p:c)_Var      p__c___Var
   \(++:c)_Var      (++:c)_Var       ___c___Var
   \(++:.s:c)_Var   (++:.s:c)_Var    ___.s:c___Var

   \(+):Func        (+):Func         _doc:comp:Func
   \(+:c):Func      (+:c):Func       _doc:c:Func
   \(+:.s:c):Func   (+:.s:c):Func    _doc.s:c:Func
   \(+:p:c):Func    (+:p:c):Func     p:c:Func
   \(++:c):Func     (++:c):Func      :c:Func
   \(++:.s:c):Func  (++:.s:c):Func   :.s:c:Func

   \(+)/Path        (+)/Path         "$_lib_dir/_/doc/comp"/Path
   \(+:c)/Path      (+:c)/Path       "$_lib_dir/_/doc/c"/Path
   \(+:.s:c)/Path   (+:.s:c)/Path    "$_lib_dir/doc/s/c"/Path
   \(+:p/s:c)/Path  (+:p/s:c)/Path   "$_lib_dir/p/s/c"/Path
   \(++:c)/Path     (++:c)/Path      "$_lib_dir/_/_/c"/Path
   \(++:.s:c)/Path  (++:.s:c)/Path   "$_lib_dir/_/_/.s:c"/Path

   UNIT

   \(-)_Var         (-)_Var          _doc__comp__unit___Var
   \(-:u)_Var       (-:u)_Var        _doc__comp__u___Var
   \(-:c:u)_Var     (-:c:u)_Var      _doc__c__u___Var
   \(--:c:u)_Var    (--:c:u)_Var     ___c__u___Var

   \(-):Func        (-):Func         _doc:comp:unit:Func
   \(-:u):Func      (-:u):Func       _doc:comp:u:Func
   \(-:c:u):Func    (-:c:u):Func     _doc:c:u:Func
   \(--:c:u):Func   (--:c:u):Func    :c:u:Func

   \(-)/Path        (-)/Path         "$_lib_dir/_/doc/comp/unit"/Path
   \(-:u)/Path      (-:u)/Path       "$_lib_dir/_/doc/comp/u"/Path
   \(-:c:u)/Path    (-:c:u)/Path     "$_lib_dir/_/doc/c/u"/Path
   \(--:c:u)/Path   (--:c:u)/Path    "$_lib_dir/_/_/c/u"/Path

   FUNCTION VARIABLES

   \(.)_Var         (.)_Var          _doc__comp__unit__demo__func___Var

_doc:comp:unit:Function Declarations

   PACKAGE DECL      @ func()          # @ must be in column 1
   COMPONENT DECL    + func()          # + must be in column 1
   UNIT DECL         - func()          # - must be in column 1

_doc:pfunc() { true; }
_doc:comp:cfunc() { true; }
_doc:comp:unit:ufunc() { true; }
EOF
}
