# Anti-Project Manager

An anti-manager for your Jai projects.

# Usage

After adding `apm` to your PATH:

```bash
apm new some_project                      # Creates a new project
apm get https://github.com/person/library # Fetches an external library
apm build fast dev                        # Builds the project with the compiler arguments "fast" and "dev"
apm run debug -- "Hello, World"           # Runs the project with the compiler argument "debug" and the program argument "Hello, World"
apm help                                  # Prints more information about APM
```

# Building

```bash
git clone https://github.com/judah-caruso/apm && cd apm
jai first.jai
```

# License

[Zlib](license.text)