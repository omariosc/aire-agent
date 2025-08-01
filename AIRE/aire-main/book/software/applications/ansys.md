# Ansys

Ansys is a comprehensive software suite that spans the entire range of physics, providing access to virtually any field of engineering simulation that a design process requires. For more detailed information, please refer to the [official documentation](https://www.ansys.com/en-gb/academic/learning-resources).

## Available versions on Aire

| Version  | Load Command               |
|----------|----------------------------|
| 2024R2   | `module load ansys/2024R2` |
| 2023R2   | `module load ansys/2023R2` |

## Setting up the license

To use Ansys, you need to set up the license environment variable:

```bash
export ANSYSLMD_LICENSE_FILE=port@host
```

:::{note}
To obtain the correct `port` and `host` values for your group/department, please contact the Client IT Team via <a href="https://leeds.service-now.com/it?id=sc_cat_item&table=sc_cat_item&sys_id=e36fd2230f3c2300a82247ece1050e0a&searchTerm=request" target="_blank">ServiceNow</a>.
:::

## Ansys packages

The following Ansys packages are available on Aire:

- [Ansys Command-Line Interface](./ansys/ansys_cli)
- [CFX](./ansys/cfx)
- [Chemkin Pro](./ansys/chemkin)
- [Fluent](./ansys/fluent)
- [LS-DYNA](./ansys/ls-dyna)
