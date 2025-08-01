# TeX Live
<!-- Brief introduction -->
TeX Live is a large collection of open-source tools for the TeX typesetting system. It contains an extensive list TeX-related programs, libraries and fonts. For a complete list, as well as usage instructions, please see the [official documentation](https://www.tug.org/texlive/doc/texlive-en/texlive-en.html).

## The TeX Live Module on Aire
<!-- List the available versions of this module on Aire -->
| Version | Load Command                    |
|---------|---------------------------------|
| 2025    | `module load texlive/2025`      |

:::{note}
To make TeX Live-provided fonts available as system fonts (for use with XeteX and LuaTeX) there is an additional configuration step. First, users should copy the `09-texlive.conf` file to their home directory, using:

```bash
mkdir ~/.fonts.conf.d && cp /opt/apps/pkg/tools/texlive/2025/texmf-var/fonts/conf/texlive-fontconfig.conf ~/.fonts.conf.d/09-texlive.conf
```

This first step only needs to be done once. Then, to store the fonts in the system cache, run:

```bash
fc-cache -fv
```

:::
