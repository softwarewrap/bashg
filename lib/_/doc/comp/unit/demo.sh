#!/bin/bash

- func()
{
   cat <<'EOF'

NAMESPACE PROTECTION: idioms in demofunc() in file _/doc/macros/unit/demo.sh

- References

   p: package s: sub-package  dirs:  _/_  _/s  p/_  p/s
   c: component
   u: unit

   PACKAGE

   \\(@)_Var         \(@)_Var          (@)_Var
   \\(@:.s)_Var      \(@:.s)_Var       (@:.s)_Var
   \\(@:p)_Var       \(@:p)_Var        (@:p)_Var
   \\(@@)_Var        \(@@)_Var         (@@)_Var
   \\(@@:.s)_Var     \(@@:.s)_Var      (@@:.s)_Var

   \\(@):Func        \(@):Func         (@):Func
   \\(@:.s):Func     \(@:.s):Func      (@:.s):Func
   \\(@:p):Func      \(@:p):Func       (@:p):Func
   \\(@@):Func       \(@@):Func        (@@):Func
   \\(@@:.s):Func    \(@@:.s):Func     (@@:.s):Func

   \\(@)/Path        \(@)/Path         (@)/Path
   \\(@:.s)/Path     \(@:.s)/Path      (@:.s)/Path
   \\(@:p/s)/Path    \(@:p/s)/Path     (@:p/s)/Path
   \\(@@)/Path       \(@@)/Path        (@@)/Path
   \\(@@:.s)/Path    \(@@:.s)/Path     (@@:.s)/Path

   COMPONENT

   \\(+)_Var         \(+)_Var          (+)_Var
   \\(+:c)_Var       \(+:c)_Var        (+:c)_Var
   \\(+:.s:c)_Var    \(+:.s:c)_Var     (+:.s:c)_Var
   \\(+:p:c)_Var     \(+:p:c)_Var      (+:p:c)_Var
   \\(++:c)_Var      \(++:c)_Var       (++:c)_Var
   \\(++:.s:c)_Var   \(++:.s:c)_Var    (++:.s:c)_Var

   \\(+):Func        \(+):Func         (+):Func
   \\(+:c):Func      \(+:c):Func       (+:c):Func
   \\(+:.s:c):Func   \(+:.s:c):Func    (+:.s:c):Func
   \\(+:p:c):Func    \(+:p:c):Func     (+:p:c):Func
   \\(++:c):Func     \(++:c):Func      (++:c):Func
   \\(++:.s:c):Func  \(++:.s:c):Func   (++:.s:c):Func

   \\(+)/Path        \(+)/Path         (+)/Path
   \\(+:c)/Path      \(+:c)/Path       (+:c)/Path
   \\(+:.s:c)/Path   \(+:.s:c)/Path    (+:.s:c)/Path
   \\(+:p/s:c)/Path  \(+:p/s:c)/Path   (+:p/s:c)/Path
   \\(++:c)/Path     \(++:c)/Path      (++:c)/Path
   \\(++:.s:c)/Path  \(++:.s:c)/Path   (++:.s:c)/Path

   UNIT

   \\(-)_Var         \(-)_Var          (-)_Var
   \\(-:u)_Var       \(-:u)_Var        (-:u)_Var
   \\(-:c:u)_Var     \(-:c:u)_Var      (-:c:u)_Var
   \\(--:c:u)_Var    \(--:c:u)_Var     (--:c:u)_Var

   \\(-):Func        \(-):Func         (-):Func
   \\(-:u):Func      \(-:u):Func       (-:u):Func
   \\(-:c:u):Func    \(-:c:u):Func     (-:c:u):Func
   \\(--:c:u):Func   \(--:c:u):Func    (--:c:u):Func

   \\(-)/Path        \(-)/Path         (-)/Path
   \\(-:u)/Path      \(-:u)/Path       (-:u)/Path
   \\(-:c:u)/Path    \(-:c:u)/Path     (-:c:u)/Path
   \\(--:c:u)/Path   \(--:c:u)/Path    (--:c:u)/Path

   FUNCTION VARIABLES

   \\(.)_Var         \(.)_Var          (.)_Var

- Function Declarations

   PACKAGE DECL      @ func()          # @ must be in column 1
   COMPONENT DECL    + func()          # + must be in column 1
   UNIT DECL         - func()          # - must be in column 1

@ pfunc() { true; }
+ cfunc() { true; }
- ufunc() { true; }
EOF
}
