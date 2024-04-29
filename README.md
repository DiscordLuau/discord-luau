# Discord-Luau

A Luau discord API wrapper. This is the 'refactor' branch, where I take what i've learned from my first impl, and create a better library from what i've learned..!

## Project Structure

- Package: responsible for containing all of the code used in this library
  - Classes: Generally contains the Luau 'objects' that the developer will be interacting with.
  - Data: Contains data that is used in multiple areas of the library, a singl source of truth in some sense.
  - Enums: Enums used internally
  - Std: The standard libraries that this project uses
    - If for instance, this library was to be ported to another runtime besides lune, you'd only need to change the Std files to get things up and working again :)
  - Types: Contains both internal and external types developers can use to assign types to things such as Messages
  - Utils: Simple utility scripts
  - Vendor: Modules pulled from other resources, most likely modified to run under Lune!

- init.luau: requires 'Package/init.luau', useful if you call require() on this directory.

## Project status

I'm activly working on this branch, ideally I have two days per week to commit/work on this project, so it's not going to be a quick library, but it'll be something!

:)