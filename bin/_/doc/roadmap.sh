#!/bin/bash

.doc:roadmap()
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
   \(@:.s)_Var       (@:.s)_Var        _s___Var
   \(@:p)_Var        (@:p)_Var         p___Var
   \(@@)_Var         (@@)_Var          ___Var
   \(@@:.s)_Var      (@@:.s)_Var       _s___Var

   \(@):Func         (@):Func          .doc:Func
   \(@:.s):Func      (@:.s):Func       .doc.s:Func
   \(@:p):Func       (@:p):Func        p:Func
   \(@@):Func        (@@):Func         :Func
   \(@@:.s):Func     (@@:.s):Func      .s:Func

   \(@)/Path         (@)/Path          "$_lib_dir/_/doc"/Path
   \(@:.s)/Path      (@:.s)/Path       "$_lib_dir/_/s"/Path
   \(@:p/s)/Path     (@:p/s)/Path      "$_lib_dir/p/s"/Path
   \(@@)/Path        (@@)/Path         "$_lib_dir/_/_"/Path
   \(@@:.s)/Path     (@@:.s)/Path      "$_lib_dir/_/s"/Path

   <b>COMPONENT NAMESPACE</b>

   \(+)_Var          (+)_Var           _doc_____Var
   \(+:c)_Var        (+:c)_Var         _doc__c___Var
   \(+:.s:c)_Var     (+:.s:c)_Var      _s__c___Var
   \(+:p:c)_Var      (+:p:c)_Var       p__c___Var
   \(++:c)_Var       (++:c)_Var        __c___Var
   \(++:.s:c)_Var    (++:.s:c)_Var     _s__c___Var

   \(+):Func         (+):Func          .doc::Func
   \(+:c):Func       (+:c):Func        .doc:c:Func
   \(+:.s:c):Func    (+:.s:c):Func     .doc.s:c:Func
   \(+:p:c):Func     (+:p:c):Func      p:c:Func
   \(++:c):Func      (++:c):Func       :c:Func
   \(++:.s:c):Func   (++:.s:c):Func    .s:c:Func

   \(+)/Path         (+)/Path          "$_lib_dir/_/doc/"/Path
   \(+:c)/Path       (+:c)/Path        "$_lib_dir/_/doc/c"/Path
   \(+:.s:c)/Path    (+:.s:c)/Path     "$_lib_dir/_/s/c"/Path
   \(+:p/s:c)/Path   (+:p/s:c)/Path    "$_lib_dir/p/s/c"/Path
   \(++:c)/Path      (++:c)/Path       "$_lib_dir/_/_/c"/Path
   \(++:.s:c)/Path   (++:.s:c)/Path    "$_lib_dir/_/s/c"/Path

   <b>UNIT NAMESPACE</b>

   \(-)_Var          (-)_Var           _doc_______Var
   \(-:u)_Var        (-:u)_Var         _doc____u___Var
   \(-:c:u)_Var      (-:c:u)_Var       _doc__c__u___Var
   \(--:c:u)_Var     (--:c:u)_Var      __c__u___Var

   \(-):Func         (-):Func          .doc:::Func
   \(-:u):Func       (-:u):Func        .doc::u:Func
   \(-:c:u):Func     (-:c:u):Func      .doc:c:u:Func
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

@ public_package_func() { true; }^
@ PrivatePackageFunc() { true; }^

+ public_component_func() { true; }^
+ PrivateComponentFunc() { true; }^

- PrivateUnitFunc() { true; }^

======================================================================================================================

2. BUILTINS:

   Builtins are namespace-unprotected function names that provide special capabilities.
   Commonly, these builtins consist of non-alphabetic characters that are permissible
   for use as function names.

2.1 INDIRECTION BUILTIN: -

   The - builtin, otherwise known as the indirection builtin, is intended to provide
   an alternate implementation or a wrapper for external commands and functions.

   Syntax:
      - --def <indirect-from> <indirect-to>              # Define <indirect-from> to call <indirect-to>
      - <options> <indirect-from> [<arguments>]          # Use <indirect-from> to call <indirect-to>

   For example, the bashc framework provides an indirection builtin definition for 'python' to
   ensure that some valid python executable can be relied on to be available.
   Consider the implementation of (++:json):is_valid:

      - python -c "import sys,json;json.loads(sys.stdin.read())" &>/dev/null

   This idiom can be used to ensure that commands and functions can be relied on to be available
   with desired semantics and yet be done in a way that requires only minimal syntactic intrusion.

2.2 INJECTION BUILTIN: =

   The = builtin, otherwise known as the injection builtin, is intended to provide
   an implementation of the Hooks and Callbacks design pattern. This design pattern
   makes it possible to treat functions as templates with specific implementations
   at designated places within function bodies.

   Syntax:  = <directive> [<arguments>]

   = add HookName .doc::List <add-args>                    # Add callbacks to the HookName hook with add-provided args
   = del HookName .doc::List                               # Delete callbacks from the HookName hook
   = run HookName <run-args>                             # Run HookName callbacks with add- and run-provided args

2.3 CHAINING BUILTIN: +

   The + builtin, otherwise known as the chaining builtin, is intended to provide
   access to instance methods. See section 3 below.

2.4 ANNOTATION BUILTIN: :

   The : builtin, otherwise known as the annotation builtin, is intended to modify
   code generation and execution behavior.

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

======================================================================================================================

3. OBJECT ORIENTATION:

3.1 CONSTRUCTOR, DESTRUCTOR, AND METHOD DECLARATIONS:

   : extends <OtherClass>                                ^<K# Extend this <Class> from <OtherClass>
   @ <Class>:()                                          ^<K# The constructor is the <class> with a colon suffix
   {
      (!).<field>[=<value>]                              ^<K# Define <field> in $_this, with optional <value>
      :def <Class> <field>                               ^<K# Define <field> a separate class field
   }

   @ ~<Class>:()                                         ^<K# The destructor is the constructor name with a tilde prefix
   {^<K
      :delete <field>                                    ^<K# Delete <field>
   }^<K

   @ <Class>:<method>()                                  ^<K# A method name follows the class name
   {
      + return <instance> <return-status>                ^<K# Return instance for chaining; default: $_this 0
   }

   Instances have a JSON data store associated with them that can directly be accessed thru the instance variable.
   Instances can also have fields associated with them.

3.2 NEW AND DESTROY INSTANCE:

   :new <Class> <instance-var>                           ^<K# :new Array a
   :destroy <instance>                                   ^<K# :destroy $a

   Example:
      :new Array _doc_____a                                   ^# Create the instance _doc_____a
      :destroy $_doc_____a                                    ^# Note that an <instance> not an <instance-var> is used

3.3 SETTERS AND GETTERS:

   (!<instance-var>)[<access>]                           ^<K# Indirection (!) to instance data store with access

   Setter Examples:
      :new JSON j                                        ^# Create a JSON instance
      (!j)=37                                            ^# Set unnamed field
      (!j).a.b.c=37                                      ^# Set named field .a.b.c
      (!).x.y.z=42                                       ^# Set named field .x.y.z from current context

   Getter Examples:
      $(!)                                               ^# Get unnamed field
      $(!j).a.b.c                                        ^# Get named field .a.b.c
      $(!).x.y.z                                         ^# Get named field .x.y.z from current context

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

4. PLUGINS:

   Plugins are idioms that are replaced at compile time to achieve added capabilities.

   Syntax:
      ({<name> [<args>]})                                ^<K# Plugin without input
      ({<name> [<args>])<input>(})                       ^<K# Plugin with input between markers

   The <name> is a function alias or an existing function name that is to be called.
   The <args> are arguments to be passed to that function.

   Notes:
      The empty <name> is the same as 'closure'.
      The <name> of ':' is the same as 'json'.

4.1 CLOSURE PLUGIN EXAMPLE:

   The closure idiom ({)...(}) is replaced by a function call to a dynamically-generated function reference:

      local c=({)^
      local -i Sum=0 I^
      for (( I=$1; I<$2; I++ )); do^
         Sum=$(( Sum += I ))^
      done^
      + return "$Sum"^
      (})^

      $c:call 1 10                                       ^# Computes the sum from 1..10 = 55

4.2 WITH PLUGIN EXAMPLE:

   The with plugin

   Syntax:
      ({with <instance> [as <alias>])...(})              ^<K# Allow data access to <instance>

   Example:
      ({with $JSONInstance as j)                         ^# Start a context block
         (!).a.b.c=37                                    ^# Assign value in current context $JSONInstance
         (!!j).a.b.c=37                                  ^# Assign value in context using the alias name
         (!k).x.y.z=42                                   ^# Assign value to some non-context instance
      (})                                                ^# End a context block

4.3 JSON EXAMPLE:

   local j=({:) { "a": 1 } (})                           ^# Create a JSON instance j

   $j:join --string '{"b": 2}'                           ^# Use the join method on the created-JSON instance
   $j:dump                                               ^# Emits: {"a": 1, "b": 2}

======================================================================================================================

5. REDIRECTION:

   Some additional file descriptors are made available symbolically.

   Syntax:
      (<in)                                              ^<K# Input redirection; same as <&3
      (>out)                                             ^<K# Output redirection; same as >&4
      (>err)                                             ^<K# Error redirection; same as >&5
      (>data)                                            ^<K# Error redirection; same as >&6
      (>log)                                             ^<K# Error redirection; same as >&7

   Examples:
      echo 'Hello There!' (>out)                         ^# Script out
      echo 'Bad syntax!!' (>err)                         ^# Script err
      sed 's|Hi|There!!|' (<in) (>out)                   ^# Script in and script out
      echo '{"result":3}' (>data)                        ^# Script data
      echo 'Succeeded!!!' (>log)                         ^# Script log
EOF
}
