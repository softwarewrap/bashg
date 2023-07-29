#!/bin/bash

- func()
{
   cat <<'EOF'

NAMESPACE PROTECTION: idioms in demofunc() in file _/_/comp/unit/demo.sh

- References

   p: package s: sub-package  dirs:  _/_  _/s  p/_  p/s
   c: component
   u: unit

   PACKAGE

   \\(@):Func        \(@):Func         (@):Func
   \\(@:.s):Func     \(@:.s):Func      (@:.s):Func
   \\(@:p):Func      \(@:p):Func       (@:p):Func
   \\(@@):Func       \(@@):Func        (@@):Func
   \\(@@:.s):Func    \(@@:.s):Func     (@@:.s):Func

   \\(@)_Var         \(@)_Var          (@)_Var
   \\(@:.s)_Var      \(@:.s)_Var       (@:.s)_Var
   \\(@:p)_Var       \(@:p)_Var        (@:p)_Var
   \\(@@)_Var        \(@@)_Var         (@@)_Var
   \\(@@:.s)_Var     \(@@:.s)_Var      (@@:.s)_Var

   \\(@)/Path        \(@)/Path         (@)/Path
   \\(@:.s)/Path     \(@:.s)/Path      (@:.s)/Path
   \\(@:p/s)/Path    \(@:p/s)/Path     (@:p/s)/Path
   \\(@@)/Path       \(@@)/Path        (@@)/Path
   \\(@@:.s)/Path    \(@@:.s)/Path     (@@:.s)/Path

   COMPONENT

   \\(+):Func        \(+):Func         (+):Func
   \\(+:c):Func      \(+:c):Func       (+:c):Func
   \\(+:.s:c):Func   \(+:.s:c):Func    (+:.s:c):Func
   \\(+:p:c):Func    \(+:p:c):Func     (+:p:c):Func
   \\(++:c):Func     \(++:c):Func      (++:c):Func
   \\(++:.s:c):Func  \(++:.s:c):Func   (++:.s:c):Func

   \\(+)_Var         \(+)_Var          (+)_Var
   \\(+:c)_Var       \(+:c)_Var        (+:c)_Var
   \\(+:.s:c)_Var    \(+:.s:c)_Var     (+:.s:c)_Var
   \\(+:p:c)_Var     \(+:p:c)_Var      (+:p:c)_Var
   \\(++:c)_Var      \(++:c)_Var       (++:c)_Var
   \\(++:.s:c)_Var   \(++:.s:c)_Var    (++:.s:c)_Var

   \\(+)/Path        \(+)/Path         (+)/Path
   \\(+:c)/Path      \(+:c)/Path       (+:c)/Path
   \\(+:.s:c)/Path   \(+:.s:c)/Path    (+:.s:c)/Path
   \\(+:p/s:c)/Path  \(+:p/s:c)/Path   (+:p/s:c)/Path
   \\(++:c)/Path     \(++:c)/Path      (++:c)/Path
   \\(++:.s:c)/Path  \(++:.s:c)/Path   (++:.s:c)/Path

   UNIT

   \\(-):Func        \(-):Func         (-):Func
   \\(-:u):Func      \(-:u):Func       (-:u):Func
   \\(-:c:u):Func    \(-:c:u):Func     (-:c:u):Func
   \\(--:c:u):Func   \(--:c:u):Func    (--:c:u):Func

   \\(-)_Var         \(-)_Var          (-)_Var
   \\(-:u)_Var       \(-:u)_Var        (-:u)_Var
   \\(-:c:u)_Var     \(-:c:u)_Var      (-:c:u)_Var
   \\(--:c:u)_Var    \(--:c:u)_Var     (--:c:u)_Var

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
