#!/bin/bash

_doc:roadmap()
{
   cat <<'EOF'

0. IDIOM OVERVIEW

   Idioms fall into only 6 categories:

      <namespace-group> <function>()                     # Declare functions with namespace protection
         @ + -                                           # The namespaces in which functions can be declared

      (<idiom-id><idiom-detail>)[<idiom-type>]           # Most idioms syntactically match this pattern
         <idiom-id>:    @ + - ! { } < >                  # Idioms for: namespace, indirection, plugins, redirection
         <idiom-type>:  _ : / =                          # Variable, function, path, and access idioms

      .. <instance>                                      # Set instance for chaining
      + <method> <args>                                  # Chain current instance and invoke method with args
      : <annotation>                                     # Facilitate code to operate on code
      = <injection>                                      # Facilitate hooks and callbacks code injection

   Everything below is an expanded discussion of the above summary.

======================================================================================================================

1. NAMESPACE PROTECTION

1.1 References

   p: package s: sub-package
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

   \(+)_Var         (+)_Var          _doc_____Var
   \(+:c)_Var       (+:c)_Var        _doc__c___Var
   \(+:.s:c)_Var    (+:.s:c)_Var     _doc_s__c___Var
   \(+:p:c)_Var     (+:p:c)_Var      p__c___Var
   \(++:c)_Var      (++:c)_Var       ___c___Var
   \(++:.s:c)_Var   (++:.s:c)_Var    ___.s:c___Var

   \(+):Func        (+):Func         _doc::Func
   \(+:c):Func      (+:c):Func       _doc:c:Func
   \(+:.s:c):Func   (+:.s:c):Func    _doc.s:c:Func
   \(+:p:c):Func    (+:p:c):Func     p:c:Func
   \(++:c):Func     (++:c):Func      :c:Func
   \(++:.s:c):Func  (++:.s:c):Func   :.s:c:Func

   \(+)/Path        (+)/Path         "$_lib_dir/_/doc/"/Path
   \(+:c)/Path      (+:c)/Path       "$_lib_dir/_/doc/c"/Path
   \(+:.s:c)/Path   (+:.s:c)/Path    "$_lib_dir/doc/s/c"/Path
   \(+:p/s:c)/Path  (+:p/s:c)/Path   "$_lib_dir/p/s/c"/Path
   \(++:c)/Path     (++:c)/Path      "$_lib_dir/_/_/c"/Path
   \(++:.s:c)/Path  (++:.s:c)/Path   "$_lib_dir/_/_/.s:c"/Path

   UNIT

   \(-)_Var         (-)_Var          _doc_______Var
   \(-:u)_Var       (-:u)_Var        _doc____u___Var
   \(-:c:u)_Var     (-:c:u)_Var      _doc__c__u___Var
   \(--:c:u)_Var    (--:c:u)_Var     ___c__u___Var

   \(-):Func        (-):Func         _doc:::Func
   \(-:u):Func      (-:u):Func       _doc::u:Func
   \(-:c:u):Func    (-:c:u):Func     _doc:c:u:Func
   \(--:c:u):Func   (--:c:u):Func    :c:u:Func

   \(-)/Path        (-)/Path         "$_lib_dir/_/doc//"/Path
   \(-:u)/Path      (-:u)/Path       "$_lib_dir/_/doc//u"/Path
   \(-:c:u)/Path    (-:c:u)/Path     "$_lib_dir/_/doc/c/u"/Path
   \(--:c:u)/Path   (--:c:u)/Path    "$_lib_dir/_/_/c/u"/Path

   FUNCTION VARIABLES

   \(.)_Var         (.)_Var          _doc____roadmap__roadmap___Var

1.3 Directory Layout

   src/<TLD>/<SUBDOMAIN>/<FILE>.sh
   src/<TLD>/<SUBDOMAIN>/<COMPONENT>/<FILE>.sh
   src/<TLD>/<SUBDOMAIN>/<COMPONENT>/<UNIT>/**/<FILE>.sh

   Where:

      <PACKAGE>   ::= <TLD> [ "." <SUBDOMAIN> ]          # Optional portion only if <SUBDOMAIN> is not empty
      <TLD>       ::= { reverse DNS top-level domain } | # Domains registered by NIC registry operators
                      "_"                                # The _ TLD is the "system" TLD
      <SUBDOMAIN> ::= { reverse sub-domain } |           # Dot-separated subdomain
                      "_"                                # The _ SUBDOMAIN is represents no subdomain (direct domain)
      <COMPONENT> ::= { component namespace name }
      <UNIT>      ::= { unit namespace name }
      <FILE>      ::= { file name }

1.2 Function Declarations

   PACKAGE DECL            @ func() { ... }
   COMPONENT DECL          + func() { ... }
   UNIT DECL               - func() { ... }

_doc:pfunc() { true; }
_doc::cfunc() { true; }
_doc:::ufunc() { true; }

======================================================================================================================

2. OBJECT ORIENTATION

2.1 Constructor and Method Declarations

   @ <Class>:()
   {
      :extends <Class>

      $_this:def [+|-]<option>
      $_this:def <key> <value>
   }
   @ <Class>:<method>()
   {
      .. <instance>                                      # Instance for chaining; default: $_this
   }

   Instances have a JSON data store associated with them that can directly be accessed thru the instance variable.
   Instances can also have fields associated with them

   The following shorthands are defined:

   (!)=  $_this:def
   (!)   $_this

2.2 New and Destroy Instance

   :new <Class> <instance-var>                           # :new Array a
   :destroy <instance>                                   # :destroy $a

   Example:
      :new Array a                                       # Note that <instance-var> is usually namespace protected
      :destroy $a                                        # Note that an <instance> not an <instance-var> is used

2.3 Setters and Getters

   (!<instance-var>)[<access>]                           # Indirection (!) to instance data store with access

   Setter Examples:
      :new JSON j                                        # Create a JSON instance
      (!j)=37                                            # Set unnamed field
      (!j).a.b.c=37                                      # Set named field .a.b.c
      (!).x.y.z=42                                       # Set named field .x.y.z from current context

   Getter Examples:

      $(!j)                                              # Get unnamed field
      $(!j).a.b.c                                        # Get named field .a.b.c
      $(!).x.y.z                                         # Get named field .x.y.z from current context

2.4 Chaining

   The .. function is used within a method to set the instance that should be used for chaining.
   The :new function sets the instance created via the .. function.
   By default a method does the following as the last step:

      .. $_this

   The + function is used to invoke a method using the last instance on the execution stack.

   Examples:

      :new JSON j
      + readfile /path/to/file
      + dump

======================================================================================================================

3. PLUGINS

   Plugins are idioms that are replaced at compile time to achieve added capabilities

   ({<name> [<args>]})
   ({<name> [<args>])<input>(})

   The <name> is a function call that can take arguments
   The empty <name> is the same as 'closure'.
   The <name> of ':' is the same as 'json'.

3.1 Closure Example

   The closure idiom ({)...(}) is replaced by a function call to a dynamically-generated anonymous function reference

   local c=({)
   local -i Sum=0 I
   for (( I=$1; I<$2; I++ )); do ((Sum += I)); done
      $_this:return "$Sum"
   (})

   $c:call 1 10                                          # Computes the sum from 1..10 = 55

3.2 Closure with a Data Context

   ({with <instance>)...(})                              # Allow for

   ({with $j)                                            # Start a context block
      (!).a.b.c=37                                       # Assign value in current context
      (!k).x.y.z=42                                      # Assign value to some non-context instance
   (})                                                   # End a context block

3.3 JSON Example

   local j=({:) { "a": 1 } (})                           # Create a JSON instance j

   $j:join --string '{"b": 2}'                           # Use the join method on the created-JSON instance
   $j:dump                                               # Emits: {"a": 1, "b": 2}

======================================================================================================================

4. REDIRECTION

   Some additional file descriptors are made available symbolically as the following examples show:

   echo 'Hello There!' (>out)                            # Script out
   echo 'Bad syntax!!' (>err)                            # Script err
   sed 's|Hi|There!!|' (<in) (>out)                      # Script in and script out
   echo '{"result":3}' (>data)                           # Script data
   echo 'Succeeded!!!' (>log)                            # Script log

======================================================================================================================

5. INJECTION

   Code can be written using the hooks and callbacks design pattern.

   = add HookName _doc::List <add-args>                    # Add callbacks to the HookName hook with add-provided args
   = del HookName _doc::List                               # Delete callbacks from the HookName hook
   = run HookName <run-args>                             # Run HookName callbacks with add- and run-provided args

======================================================================================================================

6. ANNOTATIONS

   Annotations are merely functions that are exercised at compile time that operate on code and
   can perform create, replace, update, and delete operations on the code.

   Annotations are invoked as follows:


      : <name> args                                      # Find and apply annotation <name> with <args>
      : <name> args <<MARKER                             # Find and apply annotation <name> with <args> and <stdin>
      ...
      MARKER

   The compiler operates in 2 passes: it first compiles all code without annotations, but makes note of the
   annotation requests that are encountered along with contextual information (such as the current namespace and
   the function name that immediately follows the annotation).

   Then, if any annotation requests have been made, the annotation functions are called to modify the compiled code.

   The <name> can be a fully-qualified function, or it can be a name that is searched for in a map of
   defined annotation functions.
EOF
}
