# Anti-Project Manager

The anti-manager for your Jai projects.

# Usage

After adding `apm` to your PATH:

```bash
λ apm help

λ Usage:
    apm new [name] <directory>      creates a new project and skeleton
    apm get [url] <import name>     fetches an external module (via git)
    apm update [-f] <module name>   updates a module, -f will forcibly apply the update
    apm build <compiler arguments>  builds the project, passing any arguments given
```

# Building

```bash
git clone https://github.com/judah-caruso/apm && cd apm
jai first.jai
```

# License

[zlib](license.text)