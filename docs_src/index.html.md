---
title: Flatbuffers

language_tabs: # must be one of https://git.io/vQNgJ
  - cpp: C++
  - java: Java
  - csharp: C#
  - python: Python

toc_footers:
  - <a href='https://github.com/google/flatbuffers'>Flatbuffer's Source on GitHub</a>
  - <a href='https://github.com/slatedocs/slate'>Documentation Powered by Slate</a>

search: true

code_clipboard: true
---

# Introduction

FlatBuffers is an efficient cross platform serialization library for [C++](#cpp), C#, C, Go, Java, Kotlin, JavaScript, Lobster, Lua, TypeScript, PHP, Python, Rust and Swift. It was originally created at Google for game development and other performance-critical applications.

## License

It is available as Open Source on [GitHub](https://github.com/google/flatbuffers) under the Apache license, v2 (see [LICENSE.txt](../LICENSE.txt)).

## Why Use FlatBuffers?

* **Access to serialized data without parsing/unpacking** - What sets FlatBuffers apart is that it represents hierarchical data in a flat binary buffer in such a way that it can still be accessed directly without parsing/unpacking, while also still supporting data structure evolution (forwards/backwards compatibility).

* **Memory efficiency and speed** - The only memory needed to access your data is that of the buffer. It requires 0 additional allocations (in C++, other languages may vary). FlatBuffers is also very suitable for use with mmap (or streaming), requiring only part of the buffer to be in memory. Access is close to the speed of raw struct access with only one extra indirection (a kind of vtable) to allow for format evolution and optional fields. It is aimed at projects where spending time and space (many memory allocations) to be able to access or construct serialized data is undesirable, such as in games or any other performance sensitive applications. See the benchmarks for details.

* **Flexible** - Optional fields means not only do you get great forwards and backwards compatibility (increasingly important for long-lived games: don't have to update all data with each new version!). It also means you have a lot of choice in what data you write and what data you don't, and how you design data structures.

* **Tiny code footprint** - Small amounts of generated code, and just a single small header as the minimum dependency, which is very easy to integrate. Again, see the benchmark section for details.
Strongly typed - Errors happen at compile time rather than manually having to write repetitive and error prone run-time checks. Useful code can be generated for you.

* **Convenient to use** - Generated C++ code allows for terse access & construction code. Then there's optional functionality for parsing schemas and JSON-like text representations at runtime efficiently if needed (faster and more memory efficient than other JSON parsers). Java, Kotlin and Go code supports object-reuse. C# has efficient struct based accessors.

* **Cross platform code with no dependencies** - C++ code will work with any recent gcc/clang and VS2010. Comes with build files for the tests & samples (Android .mk files, and cmake for all other platforms).

### Why not use Protocol Buffers, or .. ?

Protocol Buffers is indeed relatively similar to FlatBuffers, with the primary difference being that FlatBuffers does not need a parsing/ unpacking step to a secondary representation before you can access data, often coupled with per-object memory allocation. The code is an order of magnitude bigger, too. Protocol Buffers has no optional text import/export.

### But all the cool kids use JSON!

JSON is very readable (which is why we use it as our optional text format) and very convenient when used together with dynamically typed languages (such as JavaScript). When serializing data from statically typed languages, however, JSON not only has the obvious drawback of runtime inefficiency, but also forces you to write more code to access data (counterintuitively) due to its dynamic-typing serialization system. In this context, it is only a better choice for systems that have very little to no information ahead of time about what data needs to be stored.

If you do need to store data that doesn't fit a schema, FlatBuffers also offers a schema-less (self-describing) version!

Read more about the "why" of FlatBuffers in the white paper.

# Getting Started

## Tutorial

### Writing the Monsters FlatBuffer Schema

> Example IDL file for our monster's schema:

```
  namespace MyGame.Sample;

  enum Color:byte { Red = 0, Green, Blue = 2 }

  union Equipment { Weapon } // Optionally add more tables.

  struct Vec3 {
    x:float;
    y:float;
    z:float;
  }

  table Monster {
    pos:Vec3; // Struct.
    mana:short = 150;
    hp:short = 100;
    name:string;
    friendly:bool = false (deprecated);
    inventory:[ubyte];  // Vector of scalars.
    color:Color = Blue; // Enum.
    weapons:[Weapon];   // Vector of tables.
    equipped:Equipment; // Union.
    path:[Vec3];        // Vector of structs.
  }

  table Weapon {
    name:string;
    damage:short;
  }

  root_type Monster;
```
To start working with FlatBuffers, you first need to create a `schema` file,
which defines the format for each data structure you wish to serialize. Here is
the `schema` that defines the template for our monsters

As you can see, the syntax for the `schema`
[Interface Definition Language (IDL)](https://en.wikipedia.org/wiki/Interface_description_language)
is similar to those of the C family of languages, and other IDL languages. Let's
examine each part of this `schema` to determine what it does.

The `schema` starts with a `namespace` declaration. This determines the
corresponding package/namespace for the generated code. In our example, we have
the `Sample` namespace inside of the `MyGame` namespace.

Next, we have an `enum` definition. In this example, we have an `enum` of type
`byte`, named `Color`. We have three values in this `enum`: `Red`, `Green`, and
`Blue`. We specify `Red = 0` and `Blue = 2`, but we do not specify an explicit
value for `Green`. Since the behavior of an `enum` is to increment if
unspecified, `Green` will receive the implicit value of `1`.

Following the `enum` is a `union`. The `union` in this example is not very
useful, as it only contains the one `table` (named `Weapon`). If we had created
multiple tables that we would want the `union` to be able to reference, we
could add more elements to the `union Equipment`.

After the `union` comes a `struct Vec3`, which represents a floating point
vector with `3` dimensions. We use a `struct` here, over a `table`, because
`struct`s are ideal for data structures that will not change, since they use
less memory and have faster lookup.

The `Monster` table is the main object in our FlatBuffer. This will be used as
the template to store our `orc` monster. We specify some default values for
fields, such as `mana:short = 150`. If unspecified, scalar fields (like `int`,
`uint`, or `float`) will be given a default of `0` while strings and tables will
be given a default of `null`. Another thing to note is the line `friendly:bool =
false (deprecated);`. Since you cannot delete fields from a `table` (to support
backwards compatability), you can set fields as `deprecated`, which will prevent
the generation of accessors for this field in the generated code. Be careful
when using `deprecated`, however, as it may break legacy code that used this
accessor.

The `Weapon` table is a sub-table used within our FlatBuffer. It is
used twice: once within the `Monster` table and once within the `Equipment`
union. For our `Monster`, it is used to populate a `vector of tables` via the
`weapons` field within our `Monster`. It is also the only table referenced by
the `Equipment` union.

The last part of the `schema` is the `root_type`. The root type declares what
will be the root table for the serialized data. In our case, the root type is
our `Monster` table.

The scalar types can also use alias type names such as `int16` instead
of `short` and `float32` instead of `float`. Thus we could also write
the `Weapon` table as:

### Reading and Writing Monster FlatBuffers

#### Importing dependencies

```cpp
  #include "monster_generated.h" // This was generated by `flatc`.

  using namespace MyGame::Sample; // Specified in the schema.
```

```java
  import MyGame.Sample.*; //The `flatc` generated files. (Monster, Vec3, etc.)

  import com.google.flatbuffers.FlatBufferBuilder;
```

```csharp
  using FlatBuffers;
  using MyGame.Sample; // The `flatc` generated files. (Monster, Vec3, etc.)
```

```python
  import flatbuffers

  # Generated by `flatc`.
  import MyGame.Sample.Color
  import MyGame.Sample.Equipment
  import MyGame.Sample.Monster
  import MyGame.Sample.Vec3
  import MyGame.Sample.Weapon
```

Now that we have compiled the schema for our programming language, we can
start creating some monsters and serializing/deserializing them from
FlatBuffers.

#### Initialize the flatbuffer builder

```cpp
  // Create a `FlatBufferBuilder`, which will be used to create our
  // monsters' FlatBuffers.
  flatbuffers::FlatBufferBuilder builder(1024);
```

```java
  // Create a `FlatBufferBuilder`, which will be used to create our
  // monsters' FlatBuffers.
  FlatBufferBuilder builder = new FlatBufferBuilder(1024);
```

```csharp
  // Create a `FlatBufferBuilder`, which will be used to create our
  // monsters' FlatBuffers.
  var builder = new FlatBufferBuilder(1024);
```

```python
  # Create a `FlatBufferBuilder`, which will be used to create our
  # monsters' FlatBuffers.
  builder = flatbuffers.Builder(1024)
```

The first step is to import/include the library, generated files, etc.

Now we are ready to start building some buffers. In order to start, we need
to create an instance of the `FlatBufferBuilder`, which will contain the buffer
as it grows. You can pass an initial size of the buffer (here 1024 bytes),
which will grow automatically if needed:

# FlatBuffer Schema

## Schema (`.fbs`) 

```
// example IDL file

namespace MyGame;

attribute "priority";

enum Color : byte { Red = 1, Green, Blue }

union Any { Monster, Weapon, Pickup }

struct Vec3 {
  x:float;
  y:float;
  z:float;
}

table Monster {
  pos:Vec3;
  mana:short = 150;
  hp:short = 100;
  name:string;
  friendly:bool = false (deprecated, priority: 1);
  inventory:[ubyte];
  color:Color = Blue;
  test:Any;
}

root_type Monster;
```

The syntax of the schema language (aka IDL, Interface Definition Language) should look quite familiar to users of any of the C family of languages, and also to users of other IDLs. Let's look at an example first:

### Tables

```
table Monster {
  pos:Vec3;
  mana:short = 150;
  hp:short = 100;
  name:string;
  friendly:bool = false (deprecated, priority: 1);
  inventory:[ubyte];
  color:Color = Blue;
  test:Any;
}
```

Tables are the main way of defining objects in FlatBuffers, and consist of a name (here Monster) and a list of fields. Each field has a name, a type, and optionally a default value. If the default value is not specified in the schema, it will be 0 for scalar types, or null for other types. Some languages support setting a scalar's default to null. This makes the scalar optional.

Fields do not have to appear in the wire representation, and you can choose to omit fields when constructing an object. You have the flexibility to add fields without fear of bloating your data. This design is also FlatBuffer's mechanism for forward and backwards compatibility. Note that:

* You can add new fields in the schema ONLY at the end of a table definition. Older data will still read correctly, and give you the default value when read. Older code will simply ignore the new field. If you want to have flexibility to use any order for fields in your schema, you can manually assign ids (much like Protocol Buffers), see the id attribute below.

* You cannot delete fields you don't use anymore from the schema, but you can simply stop writing them into your data for almost the same effect. Additionally you can mark them as deprecated as in the example above, which will prevent the generation of accessors in the generated C++, as a way to enforce the field not being used any more. (careful: this may break code!).

* You may change field names and table names, if you're ok with your code breaking until you've renamed them there too.

See "Schema evolution examples" below for more on this topic.

### Structs

```
struct Vec3 {
  x:float;
  y:float;
  z:float;
}
```

Similar to a table, only now none of the fields are optional (so no defaults either), and fields may not be added or be deprecated. Structs may only contain scalars or other structs. Use this for simple objects where you are very sure no changes will ever be made (as quite clear in the example Vec3). Structs use less memory than tables and are even faster to access (they are always stored in-line in their parent object, and use no virtual table).

<aside class="notice">
  Structs may only contain scalars or other structs.
</aside>

## Schema Compiler (`flatc`)

```
flatc [ GENERATOR OPTIONS ] [ -o PATH ] [ -i PATH ] FILES
```

Schema are processed by the FlatBuffers Compiler `flatc` and generate the code for the specified language.

### Generator Options
Generator Options | Comment
------------------|--------
`--cpp`   | Generate a C++ header for all definitions in this file
`--java`  | Generate Java code


# Languages

Flatbuffers supports a variety of languages. The follow sections highlight 
specifics of the languages.

<!-- Using this instead of #C++ as that doesn't produce the correct anchor-->
<h2 id="cpp">C++</h2>

```cpp
  #include "flatbuffers/flatbuffers.h"
  #include "monster_test_generate.h"
  #include <iostream> // C++ header file for printing
  #include <fstream> // C++ header file for file access
  
  
  std::ifstream infile;
  infile.open("monsterdata_test.mon", std::ios::binary | std::ios::in);
  infile.seekg(0,std::ios::end);
  int length = infile.tellg();
  infile.seekg(0,std::ios::beg);
  char *data = new char[length];
  infile.read(data, length);
  infile.close();
  
  auto monster = GetMonster(data);
```

Note: See [Tutorial](#tutorial) for a more in-depth example of how to use FlatBuffers in C++.

FlatBuffers supports both reading and writing FlatBuffers in C++.

# FILLER

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)

This is filler text due to bug [#1440](https://github.com/slatedocs/slate/issues/1440)