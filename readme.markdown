# Anti-Project Manager

An anti-manager for your Jai projects.

# Usage

After adding `apm` to your PATH:

```bash
apm new some_project                      # Creates a new project
apm get https://github.com/person/library # Fetches an external library
apm update some-module                    # Updates a local module
apm build fast dev                        # Builds the project, passing "fast" and "dev" to the compiler
apm help                                  # Prints more information about APM
```

# Building

```bash
git clone https://github.com/judah-caruso/apm && cd apm
jai first.jai
```

# License

[zlib](license.text)