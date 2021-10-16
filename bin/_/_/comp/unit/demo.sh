#!/bin/bash

:comp:unit:func()
{
   cat <<'EOF'

NAMESPACE PROTECTION: idioms in demofunc() in file _/_/macros/unit/demo.sh

:comp:unit:References

   p: package s: sub-package  dirs:  _/_  _/s  p/_  p/s
   c: component
   u: unit

   PACKAGE

   \(@)_Var         (@)_Var          ___Var
   \(@:.s)_Var      (@:.s)_Var       _s___Var
   \(@:p)_Var       (@:p)_Var        p___Var
   \(@@)_Var        (@@)_Var         ___Var
   \(@@:.s)_Var     (@@:.s)_Var      _s___Var

   \(@):Func        (@):Func         :Func
   \(@:.s):Func     (@:.s):Func      .s:Func
   \(@:p):Func      (@:p):Func       p:Func
   \(@@):Func       (@@):Func        :Func
   \(@@:.s):Func    (@@:.s):Func     .s:Func

   \(@)/Path        (@)/Path         "$_lib_dir/_/_"/Path
   \(@:.s)/Path     (@:.s)/Path      "$_lib_dir/_/s"/Path
   \(@:p/s)/Path    (@:p/s)/Path     "$_lib_dir/p/s"/Path
   \(@@)/Path       (@@)/Path        "$_lib_dir/_/_"/Path
   \(@@:.s)/Path    (@@:.s)/Path     "$_lib_dir/_/s"/Path

   COMPONENT

   \(+)_Var         (+)_Var          __comp___Var
   \(+:c)_Var       (+:c)_Var        __c___Var
   \(+:.s:c)_Var    (+:.s:c)_Var     _s__c___Var
   \(+:p:c)_Var     (+:p:c)_Var      p__c___Var
   \(++:c)_Var      (++:c)_Var       __c___Var
   \(++:.s:c)_Var   (++:.s:c)_Var    _s__c___Var

   \(+):Func        (+):Func         :comp:Func
   \(+:c):Func      (+:c):Func       :c:Func
   \(+:.s:c):Func   (+:.s:c):Func    .s:c:Func
   \(+:p:c):Func    (+:p:c):Func     p:c:Func
   \(++:c):Func     (++:c):Func      :c:Func
   \(++:.s:c):Func  (++:.s:c):Func   .s:c:Func

   \(+)/Path        (+)/Path         "$_lib_dir/_/_/comp"/Path
   \(+:c)/Path      (+:c)/Path       "$_lib_dir/_/_/c"/Path
   \(+:.s:c)/Path   (+:.s:c)/Path    "$_lib_dir/_/s/c"/Path
   \(+:p/s:c)/Path  (+:p/s:c)/Path   "$_lib_dir/p/s/c"/Path
   \(++:c)/Path     (++:c)/Path      "$_lib_dir/_/_/c"/Path
   \(++:.s:c)/Path  (++:.s:c)/Path   "$_lib_dir/_/s/c"/Path

   UNIT

   \(-)_Var         (-)_Var          __comp__unit___Var
   \(-:u)_Var       (-:u)_Var        __comp__u___Var
   \(-:c:u)_Var     (-:c:u)_Var      __c__u___Var
   \(--:c:u)_Var    (--:c:u)_Var     __c__u___Var

   \(-):Func        (-):Func         :comp:unit:Func
   \(-:u):Func      (-:u):Func       :comp:u:Func
   \(-:c:u):Func    (-:c:u):Func     :c:u:Func
   \(--:c:u):Func   (--:c:u):Func    :c:u:Func

   \(-)/Path        (-)/Path         "$_lib_dir/_/_/comp/unit"/Path
   \(-:u)/Path      (-:u)/Path       "$_lib_dir/_/_/comp/u"/Path
   \(-:c:u)/Path    (-:c:u)/Path     "$_lib_dir/_/_/c/u"/Path
   \(--:c:u)/Path   (--:c:u)/Path    "$_lib_dir/_/_/c/u"/Path

   FUNCTION VARIABLES

   \(.)_Var         (.)_Var          __comp__unit__demo__func___Var

:comp:unit:Function Declarations

   PACKAGE DECL      @ func()          # @ must be in column 1
   COMPONENT DECL    + func()          # + must be in column 1
   UNIT DECL         - func()          # - must be in column 1

:pfunc() { true; }
:comp:cfunc() { true; }
:comp:unit:ufunc() { true; }
EOF
}
