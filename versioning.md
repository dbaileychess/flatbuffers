# FlatBuffers Versioning

This specifies how we version things in FlatBuffers, as there are some unique
challenges present.

The overall philosophy of the project is to "live at head" and not worry about
version numbers. Due to our Continuous Integration process, any of our commits
are valid versions to work off and have been tested as a whole together.

But we also realize that others rely on package managers for their languages for
integration into their projects. So we too ocassionally cut releases and upload
a snapshot to various package managers.

## Releases

Releases occur when the maintainers decide a formal release is warrented. Either
some new feature is available or a critical bug is fixed. There is no real road
map or schedule that is followed.

## Versioning Scheme

FlatBuffers has a version in the format: `YY.MM.DD[-GITHASH]`

Where `YY` is the current year minus 2000 (e.g., `2023` is `23`).

The `MM` is the month from Jan (`0`) to Dec (`12`).

And `DD` is the day of the month, from `0` to `31`.

Since it is possible for multiple releases to happen on the same date an
optional git hash may be present. 

The `GITHASH` is the 7-digit prefix of the git commit hash of the **previous**
commit to the annotated tag that marks a release. This allows one to easily find
the commit (e.g. https://github.com/google/flatbuffers/commit/bc44fad)

An Example version would be:

`22.09.14-bc44fad`


This format has the folloing nice properties:

1. Its has lexicographic ordering, so easy to tell what is newer.
1. It's a date, so it is easy to know when in time it was released.
1. Compatible with package managers that expect Semantic Versioning
1. Simple to generate
  
### Not Semantic Versioning

This is very smilar format to [Semantic Versioning](https://semver.org/), but we
don't prescribe to hold to semantic versioning. Why Not?

Since flatbuffers involves multiple pieces working in tandem:

1. The `flatc` compiler that parses schema and write codes gen
2. The individual language "run time" libraries
3. The schema version

Its hard to assign one version to unite all those things together and follow
Semantic Versioning exactly.

#### Single Version

As an example, consider using a single version at `1.2.3`. Suppose Jane spotted
a bug in the Java runtime library which needs to be fixed and it is breaking
change. She could fix the bug and bump up the "major" version to `2.0.0` and
release. This would cause all the other languages to be updated to `2.0.0`.
Peter the `python` developer notices that the major version of flatbuffers
changed, and may A) hesitate to update because he thinks there are breaking
changes, or B) updates but doesn't see anything different with the python
libraries and wonder why he spent time updating. Either choice causes unneeded
friction, since there is zero change for python code in this release update.

#### Multiple Versions

The alternative is to assign each language their own version and have them
evolve independently. That avoids the churn for unrelated version bumps, but
because we have tight coupling with `flatc` a compatibility matrix of versions
is now required.

Taking the previous example, say that `flatbuffers-java-2.0.0` is released, what
version should `flatc` be at? If the change was just in the java runtime
libraries, no change to `flatc` is warranted, and it might stay at
`flatbuffers-flatc-1.2.3` still. This will now cause confusion on which runtime
libraries are supported by which `flatc`. The complexity expands with each
additional language.

This is a headache to maintain, and will lead to greater confusion just to fit
the mold of semantic versioning.

