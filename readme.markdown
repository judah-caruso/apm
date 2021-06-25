# (Jai) Project Manager

A project manager so small it almost doesn't exist.

# Usage

With `pm` visible to your PATH:

```bash
pm new some_project                      # Creates a new project
pm get https://github.com/person/library # Fetches an external library
pm build fast developer                  # Builds the project with the compiler arguments "fast" and "debug"
pm run debug -- "Hello, World"           # Runs the project with the compiler argument "debug" and the program argument "Hello, World"
```

# Building

```bash
git clone https://github.com/judah-caruso/pm && cd pm
jai first.jai
```
