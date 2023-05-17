# Template CXX Project

This is a template cxx project using the **Pitchfork Layout** (**PFL**) as set out by [Colby Pike](https://api.csswg.org/bikeshed/?force=1&url=https://raw.githubusercontent.com/vector-of-bool/pitchfork/develop/data/spec.bs).

# Layout

```
project
├── build
|
├── src
├── include
|
├── tests
├── examples
├── external
├── tools
├── data
├── docs
|
├── CMakeLists.txt
├── .gitignore
└── README.md
```
## build
Output build files. 
- Run cmake from here.

---

## src
All project source files.
- Short for *"source"*.
- Any files placed directly into the source directory are compiled into executables.
- All source files for libraries should be placed into appropriately named subdirectories, mirroring the structure of the [include directory](#include).

## include
All project headers.
- **Optional** to allow for smaller projects. 
- The [source directory](#src) should mirror subdirectory structure of this.

---

## tests
Source files describing (non-unit) tests.
- **Optional** but requires a `CMakeLists.txt` to function.
- Structure should mirror the [include directory](#include), with each source file describing groups of similar tests.
- Can only be built if this is the root project.
- Disabled with the [`BUILD_TESTS`](#build_tests) option.

## examples
Source files for example executables.
- **Optional** but requires a `CMakeLists.txt` to function.
- Examples utilizing multiple files should be given individual subdirectories.
- Single source file examples can exist at the top level of this directory.
- Can only be built if this is the root project.
- Disabled with the [`BUILD_EXAMPLES`](#build_examples) option.

## external
Externally linked projects.
- **Optional** but requires a `CMakeLists.txt` to function.
- Each embedded project should occupy a single, appropriately named, subdirectory.
- Place all `git submodules` here.
- Any edits to projects stored here should be done upstream at their source.

## tools
Contains extra scripts and tools related to the project.
- Included with template, may require a `CMakeLists.txt`.
- By default contains the [`AutoLib.cmake`](#auto-lib) under the `cmake` subdirectory.

## data
Holds any project files which are not code.
- **Optional**.
- Examples of data files are:
    - Graphics
    - Localization
    - Audio
- Explicitly not test data, this goes in the [tests directory](#tests).

## docs
Project documentation.
- **Optional**.
- Generate using `doxygen`.

---

## CMakeLists.txt
Top level cmake file for this project.
- Define the project here.
- Generate targets using the [`auto_lib`](#auto-lib) command.
- Enables `Werror` if this is the root project.

## .gitignore
Files to be ignored on the git tree.
- By default contains the [`build`](#build) and `.vscode` directories.

## README.MD
This file.
- Should be replaced with project specific readme.

---

# Auto Lib
Macro/Function for generating targets with using the given structure.
Clone of [pitchfork auto](https://github.com/vector-of-bool/pitchfork/blob/develop/extras/pf-cmake/auto.cmake), manually re-written to get a better understanding.

## Arguments

---

### NO_INSTALL
Set to `OFF` to install the built project at `/lib/{PROJECT_NAME}`. 
- Ignored if not run from root project.

### BUILD_TESTS
Option for enabling/disabling the building of [tests](#tests).
- Ignored if not run from root project.

### BUILD_EXAMPLES
Option for enabling/disabling the building of [examples](#examples).

---

### LIBRARY_NAME
Generated library name. 
- Defaults to `CMAKE_PROJECT_NAME`.

### ALIAS
Alias for genereated library.
- Defaults to `{CMAKE_PROJECT_NAME}::{`[`LIBRARY_NAME`](#library_name)`}`.
- Naming convention requires a separating double-colon (`::`).
- Alias is a separate name that can be used to refer to the library, often-times when linking to, in cmake files.

### OUTPUT_NAME
Similar to [`LIBRARY_NAME`](#library_name) but only changes the name of the built library file.
- **Optional**.

### VERSION_COMPATIBILITY
Compatibility version at for the install.
- Defaults to current version.

---

### LINK
List of publicly linked projects.

### PRIVATE_LINK
List of privately linked projects.