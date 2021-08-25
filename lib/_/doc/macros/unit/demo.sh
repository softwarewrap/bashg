#!/bin/bash

- demofunc()
{
   cat <<'EOF'

NAMESPACE PROTECTION: idioms in demofunc() in file _/doc/macros/unit/demo.sh

- References

   PACKAGE

      \\(@)_Var         \(@)_Var          (@)_Var
      \\(@:p)_Var       \(@:p)_Var        (@:p)_Var
      \\(@:.p)_Var      \(@:.p)_Var       (@:.p)_Var
      \\(@@)_Var        \(@@)_Var         (@@)_Var

      \\(@):Func        \(@):Func         (@):Func
      \\(@:p):Func      \(@:p):Func       (@:p):Func
      \\(@:.p):Func     \(@:.p):Func      (@:.p):Func
      \\(@@):Func       \(@@):Func        (@@):Func

      \\(@)/Path        \(@)/Path         (@)/Path
      \\(@:t/s)/Path    \(@:t/s)/Path     (@:t/s)/Path
      \\(@:.p)/Path     \(@:.p)/Path      (@:.p)/Path
      \\(@@)/Path       \(@@)/Path        (@@)/Path

   COMPONENT

      \\(+)_Var         \(+)_Var          (+)_Var
      \\(+:c)_Var       \(+:c)_Var        (+:c)_Var
      \\(+:p:c)_Var     \(+:p:c)_Var      (+:p:c)_Var
      \\(+:.p:c)_Var    \(+:.p:c)_Var     (+:.p:c)_Var
      \\(++:c)_Var      \(++:c)_Var       (++:c)_Var

      \\(+):Func        \(+):Func         (+):Func
      \\(+:c):Func      \(+:c):Func       (+:c):Func
      \\(+:p:c):Func    \(+:p:c):Func     (+:p:c):Func
      \\(+:.p:c):Func   \(+:.p:c):Func    (+:.p:c):Func
      \\(++:c):Func     \(++:c):Func      (++:c):Func

      \\(+)/Path        \(+)/Path         (+)/Path
      \\(+:c)/Path      \(+:c)/Path       (+:c)/Path
      \\(+:t/s:c)/Path  \(+:t/s:c)/Path   (+:t/s:c)/Path
      \\(+:.p:c)/Path   \(+:.p:c)/Path    (+:.p:c)/Path
      \\(++:c)/Path     \(++:c)/Path      (++:c)/Path

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
      \\(.)_var         \(.)_var          (.)_var

- Function Declarations

   PACKAGE DECL            @ func()                      # @ must be in column 1
   COMPONENT DECL          + func()                      # + must be in column 1
   UNIT DECL               - func()                      # - must be in column 1

@ func()
+ func()
- func()
EOF
}
