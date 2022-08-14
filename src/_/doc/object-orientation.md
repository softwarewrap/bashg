# Object Orientation: Implementation Overview

BashG offers object-oriented capabilities.
<details>
<summary markdown="span">Overview</summary>

Functions are used to instrument various object-oriented behaviors:

* Constructors
* Destructors
* Methods
* Field Setters and Getters

The code samples below are presented using italics, bold, and color to convey examples in a practical manner.

| Style                           | Meaning           |
|---------------------------------|-------------------|
| **Bold** or Regular             | Literal           |
| _Italics_ or **_Bold Italics_** | Indicative Syntax |

**Bold** is used with a concrete instance to refer to a class of possible substitutions,
any of which can be used. Non-bold text can also have this meaning, if introduced
earlier by bold text.

_Italics_ or **_Bold Italics_** is used to convey the syntax of allowed substitutions.
In this case, bold is added only for additional emphasis.
</details>

## Constructors

A _constructor_ is used to create an instance of a class and is a BashG PascalCase function
declaration with a **colon** as the final character.

* The default constructor has no medial hyphens.
* Alternate constructors for the same class add the suffix _-Signature_ after the class name.

**Component-Scope Class Function Declaration Examples**
<pre>
<span style="color:red">+</span> <i style="color:blue">ClassName</i><b>:()</b>
<span style="color:red">+</span> <i style="color:blue">ClassName-Signature</i><b>:()</b>
</pre>

**Instance Creation**

Within the body of a any function, do:
<pre>
:new <i style="color:blue">(+):ClassName (+)_InstanceName CtorArgs...</i>
:new <i style="color:blue">(+):ClassName-Signature (+)_InstanceName CtorArgs...</i>
</pre>

## Methods

An instance has access to methods, defined as follows:

<pre>
<span style="color:red">+</span> <i style="color:blue">ClassName</i><b>:</b><i style="color:blue">public_method_name</i>()
<span style="color:red">+</span> <i style="color:blue">ClassName</i><b>:</b><i style="color:blue">PrivateMethodName</i>()
</pre>


### extends

All constructors extend the `(@@):Object:` class and may explicitly extend other classes via the `extends` method. Multiple inheritance is achieved when more than one class name is specified.

<pre>
+ extends <i style="color:blue">(+):OtherClassA (+):OtherClassB</i>
</pre>

**Note**: In multiple inheritance, if there are duplicate functions or fields, then the last class defining the class or field is used.
