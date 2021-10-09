#!/bin/bash

_doc:roadmap()
{
   :highlight: <<'EOF'

0. IDIOM OVERVIEW:

   Idioms fall into only 6 categories:

      <namespace-group> <function>()                     ^<G# Declare functions with namespace protection
         @ + -                                           ^<G# The namespaces in which functions can be declared

      (<idiom-id><idiom-detail>)[<idiom-type>]           ^<G# Most idioms syntactically match this pattern
         <idiom-id>:    @ + - ! { } < >                  ^<G# Idioms for: namespace, indirection, plugins, redirection
         <idiom-type>:  _ : / =                          ^<G# Variable, function, path, and access idioms

      .. <instance>                                      ^<G# Set instance for chaining
      + <method> <args>                                  ^<G# Chain current instance and invoke method with args
      : <annotation>                                     ^<G# Idiom is outside of functions: modifies code generation
      = <injection>                                      ^<G# Facilitate hooks and callbacks code injection

   Everything below is an expanded discussion of the above summary.

======================================================================================================================

1. NAMESPACE PROTECTION:

1.1 REFERENCES:

   The top-level namespace is the package and optional sub-package taken together,
   and collectively called the <b>package namespace</b>.
   The component is the second-level namespace: typically, a collection of related APIs.
   The unit is the third-level namespace: typically, an implementation of an API.

   p: package                                            ^<G# Example: com.example
   s: sub-package                                        ^<G# Example: utils.numbers
   c: component                                          ^<G# Example: compare
   u: unit                                               ^<G# Example: complex

   <b>PACKAGE NAMESPACE</b>

   ESCAPED           UNESCAPED         EXPANDED
   ==============    ==============    ==============
   \(@)_Var          (@)_Var           _doc___Var
   \(@:.s)_Var       (@:.s)_Var        _doc_s___Var
   \(@:p)_Var        (@:p)_Var         p___Var
   \(@@)_Var         (@@)_Var          ___Var
   \\(@@:.s)_Var      \(@@:.s)_Var       (@@:.s)_Var

   \(@):Func         (@):Func          _doc:Func
   \(@:.s):Func      (@:.s):Func       _doc.s:Func
   \(@:p):Func       (@:p):Func        p:Func
   \(@@):Func        (@@):Func         :Func
   \\(@@:.s):Func     \(@@:.s):Func      (@@:.s):Func

   \(@)/Path         (@)/Path          "$_lib_dir/_/doc"/Path
   \(@:.s)/Path      (@:.s)/Path       "$_lib_dir"/doc/s/Path
   \(@:p/s)/Path     (@:p/s)/Path      "$_lib_dir"/p/s/Path
   \(@@)/Path        (@@)/Path         "$_lib_dir"/_/_/Path
   \\(@@:.s)/Path     \(@@:.s)/Path      (@@:.s)/Path

   <b>COMPONENT NAMESPACE</b>

   \(+)_Var          (+)_Var           _doc_____Var
   \(+:c)_Var        (+:c)_Var         _doc__c___Var
   \(+:.s:c)_Var     (+:.s:c)_Var      _doc_s__c___Var
   \(+:p:c)_Var      (+:p:c)_Var       p__c___Var
   \(++:c)_Var       (++:c)_Var        ___c___Var
   \(++:.s:c)_Var    (++:.s:c)_Var     ___.s:c___Var

   \(+):Func         (+):Func          _doc::Func
   \(+:c):Func       (+:c):Func        _doc:c:Func
   \(+:.s:c):Func    (+:.s:c):Func     _doc.s:c:Func
   \(+:p:c):Func     (+:p:c):Func      p:c:Func
   \(++:c):Func      (++:c):Func       :c:Func
   \(++:.s:c):Func   (++:.s:c):Func    :.s:c:Func

   \(+)/Path         (+)/Path          "$_lib_dir/_/doc/"/Path
   \(+:c)/Path       (+:c)/Path        "$_lib_dir/_/doc/c"/Path
   \(+:.s:c)/Path    (+:.s:c)/Path     "$_lib_dir/doc/s/c"/Path
   \(+:p/s:c)/Path   (+:p/s:c)/Path    "$_lib_dir/p/s/c"/Path
   \(++:c)/Path      (++:c)/Path       "$_lib_dir/_/_/c"/Path
   \(++:.s:c)/Path   (++:.s:c)/Path    "$_lib_dir/_/_/.s:c"/Path

   <b>UNIT NAMESPACE</b>

   \(-)_Var          (-)_Var           _doc_______Var
   \(-:u)_Var        (-:u)_Var         _doc____u___Var
   \(-:c:u)_Var      (-:c:u)_Var       _doc__c__u___Var
   \(--:c:u)_Var     (--:c:u)_Var      ___c__u___Var

   \(-):Func         (-):Func          _doc:::Func
   \(-:u):Func       (-:u):Func        _doc::u:Func
   \(-:c:u):Func     (-:c:u):Func      _doc:c:u:Func
   \(--:c:u):Func    (--:c:u):Func     :c:u:Func

   \(-)/Path         (-)/Path          "$_lib_dir/_/doc//"/Path
   \(-:u)/Path       (-:u)/Path        "$_lib_dir/_/doc//u"/Path
   \(-:c:u)/Path     (-:c:u)/Path      "$_lib_dir/_/doc/c/u"/Path
   \(--:c:u)/Path    (--:c:u)/Path     "$_lib_dir/_/_/c/u"/Path

   <b>FUNCTION VARIABLES</b>

   \(.)_Var          (.)_Var           _doc____roadmap__roadmap___Var

1.2 DIRECTORY LAYOUT:

   Namespace macros can be used at any directory level. Typically:

   -  Package namespace macros servicing multiple components are placed at the package directory level.

   -  Any namespace macros related to a single component can be placed at the component directory level.

      The component level is the fundamental level at which APIs are designed.
      While components typically expose only component namespace macros for API use, components that offer
      services to other components may use package namespace macros for inter-component use.

   -  Unit namespace macros for complex component implementation are placed under a unit directory level

   src/<TLD>/<SUBPACKAGE>/<FILE>.sh                       ^<G#Package directory level: Package macros only
   src/<TLD>/<SUBPACKAGE>/<COMPONENT>/<FILE>.sh           ^<G#Component directory level: All macros
   src/<TLD>/<SUBPACKAGE>/<COMPONENT>/<UNIT>/**/<FILE>.sh ^<G#Unit directory level: Unit macros only

   Where:

      <PACKAGE>   ::= <TLD> [ "." <SUBPACKAGE> ]         ^<K# Optional portion only if <SUBPACKAGE> is not empty
      <TLD>       ::= { reverse DNS top-level domain } | ^<K# Domains registered by NIC registry operators
                      "_"                                ^<K# The _ TLD is the "system" TLD
      <SUBPACKAGE> ::= { reverse sub-package } |         ^<K# Dot-separated sub-package
                      "_"                                ^<K# The _ SUBPACKAGE indicates there is no sub-package
      <COMPONENT> ::= { component namespace name }       ^<K# The _ COMPONENT indicates there is no component directory
      <UNIT>      ::= { unit namespace name }            ^<K# The _ UNIT indicates there is no unit directory or file
      <FILE>      ::= { file name }                      ^<K# The file name does not include the filetype extension

1.3 FUNCTION DECLARATIONS:

   Function declarations must begin in column 1 with one of the namespace macro characters followed by one
   or more spaces and the function body. The function body is typically on subsequent lines.

   Public APIs by convention consist of all lower-case characters with underscores separating words.
   Private APIs by convention consist of Pascal case characters without the use of underscores.

   Note: unit namespace functions are typically private APIs only; however, it is permissible to
   create a public unit namespace function.

   PACKAGE DECL            @ public_func() { ... }       ^# A public package namespace function declaration
   COMPONENT DECL          + public_func() { ... }       ^# A public component namespace function declaration
   UNIT DECL               - PrivateFunc() { ... }       ^# A private unit namespace function declaration

   For example (noting the definitions begin in column 1):

_doc:public_package_func() { true; }^
_doc:PrivatePackageFunc() { true; }^

_doc::public_component_func() { true; }^
_doc::PrivateComponentFunc() { true; }^

_doc:::PrivateUnitFunc() { true; }^

======================================================================================================================

2. PLUGINS:

   Plugins are idioms that are replaced at compile time to achieve added capabilities

   ({<name> [<args>]})
   ({<name> [<args>])<input>(})

   The <name> is a function call that can take arguments
   The empty <name> is the same as 'closure'.
   The <name> of ':' is the same as 'json'.

2.1 CLOSURE EXAMPLE:

   The closure idiom ({)...(}) is replaced by a function call to a dynamically-generated anonymous function reference

   local c=({)
   local -i Sum=0 I
   for (( I=$1; I<$2; I++ )); do
      Sum=$(( Sum += I ))
   done
   + return "$Sum"
   (})

   $c:call 1 10                                          # Computes the sum from 1..10 = 55

2.2 CLOSURE WITH A DATA CONTEXT:

   ({with <instance> [as <alias>])...(})                 # Allow data access to <instance>

   ({with $JSONInstance as j)                            # Start a context block
      (!).a.b.c=37                                       # Assign value in current context $JSONInstance
      (!!j).a.b.c=37                                     # Assign value in context using the alias name
      (!k).x.y.z=42                                      # Assign value to some non-context instance
   (})                                                   # End a context block

2.3 JSON EXAMPLE:

   local j=({:) { "a": 1 } (})                           # Create a JSON instance j

   $j:join --string '{"b": 2}'                           # Use the join method on the created-JSON instance
   $j:dump                                               # Emits: {"a": 1, "b": 2}

======================================================================================================================

3. OBJECT ORIENTATION:

3.1 CONSTRUCTOR, DESTRUCTOR, AND METHOD DECLARATIONS:

   : extends <OtherClass>                                ^<K# Extend this <Class> from <OtherClass>
   @ <Class>:()                                          ^<K# The constructor is the <class> with a colon suffix
   {
      (!).<field>[=<value>]                              ^<K# Define <field> in $_this, with optional <value>
      :def <Class> <field>                               ^<K# Define <field> a separate class field
   }

   @ ~<Class>:()                                         # The destructor is the constructor name with a tilde prefix
   {
      :delete <field>                                    # Delete <field>
   }

   @ <Class>:<method>()                                  ^<K# A method name follows the class name
   {
      + return <instance> <return-status>                ^<K# Return instance for chaining; default: $_this 0
   }

   Instances have a JSON data store associated with them that can directly be accessed thru the instance variable.
   Instances can also have fields associated with them.

3.2 NEW AND DESTROY INSTANCE:

   :new <Class> <instance-var>                           # :new Array a
   :destroy <instance>                                   # :destroy $a

   Example:
      :new Array _doc_____a                                   # Create the instance _doc_____a
      :destroy $_doc_____a                                    # Note that an <instance> not an <instance-var> is used

3.3 SETTERS AND GETTERS:

   (!<instance-var>)[<access>]                           # Indirection (!) to instance data store with access

   Setter Examples:
      :new JSON j                                        # Create a JSON instance
      (!j)=37                                            # Set unnamed field
      (!j).a.b.c=37                                      # Set named field .a.b.c
      (!).x.y.z=42                                       # Set named field .x.y.z from current context

   Getter Examples:

      $(!)                                               # Get unnamed field
      $(!j).a.b.c                                        # Get named field .a.b.c
      $(!).x.y.z                                         # Get named field .x.y.z from current context

3.4 CHAINING:

   In a non-method, the :new function creates an instance that can be used for subsequent chaining.
   In a method, the chaining  instance is $_this, unless the + return method is called.
   By default a method does the following as the last step:

      + return $_this 0

   The + function is used to invoke a method using the last instance on the execution stack.

   Examples:

      :new JSON j
      + readfile /path/to/file
      + dump

======================================================================================================================

4. REDIRECTION:

   Some additional file descriptors are made available symbolically as the following examples show:

   echo 'Hello There!' (>out)                            # Script out
   echo 'Bad syntax!!' (>err)                            # Script err
   sed 's|Hi|There!!|' (<in) (>out)                      # Script in and script out
   echo '{"result":3}' (>data)                           # Script data
   echo 'Succeeded!!!' (>log)                            # Script log

======================================================================================================================

5. INJECTION:

   Code can be written using the hooks and callbacks design pattern.

   = add HookName _doc::List <add-args>                    # Add callbacks to the HookName hook with add-provided args
   = del HookName _doc::List                               # Delete callbacks from the HookName hook
   = run HookName <run-args>                             # Run HookName callbacks with add- and run-provided args

======================================================================================================================

6. ANNOTATIONS:

   Annotations are merely functions that are exercised at compile time that operate on code and
   can perform create, replace, update, and delete operations on the code.

   Annotations are invoked as follows:

      : <name> <args>                                    # Find and apply annotation <name> with <args>
      : <name> <args> <<MARKER                           # Find and apply annotation <name> with <args> and <stdin>
      ...
      MARKER

   The compiler operates in 2 passes: it first compiles all code without annotations, but makes note of the
   annotation requests that are encountered along with contextual information (such as the current namespace and
   the function name that immediately follows the annotation).

   Then, if any annotation requests have been made, the annotation functions are called to modify the compiled code.

   The <name> can be a fully-qualified function, or it can be a name that is searched for in a map of
   defined annotation functions.

   An annotation without <name> and <args> returns true.
EOF
}
