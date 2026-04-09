# VASP

VASP (Vienna *Ab initio* Simulation Package) is a first-principles code for electronic-structure calculations and *ab initio* molecular dynamics using DFT, the projector-augmented-wave (PAW) method, and plane-wave basis sets.

For further information, see the [official VASP documentation](https://www.vasp.at/wiki/).

## Available versions on Aire

| Version | Load Command                                                     |
| :------ | :--------------------------------------------------------------- |
| 6.5.1   | `module load vasp/6.5.1/intel-2024.2.1_impi-2021.13_hdf5-1.14.6` |
| 6.3.2   | `module load vasp/6.3.2/intel-2024.2.1_impi-2021.13_hdf5-1.14.6` |

**Executables provided:** `vasp_std`, `vasp_gam`, `vasp_ncl`

> **Note:** Versions 6.3.2 and 6.5.1 are currently **available for user testing**. <br>
Users should validate their results before publication.

---

## Licensing

VASP is licensed per research group and is not licensed on a personal, departmental, or institution-wide basis.

Licenses are issued only to well-defined research groups. All authorised users must belong to the same organisational unit (e.g. Department or Institute) and be based at the same physical location.

VASP licenses are not transferable between research institutions. Any transfer of a license to another group within the same institution requires explicit approval from VASP Software GmbH.

Only users officially registered under a valid VASP group license may use VASP. Users who leave a licensed group must stop using VASP immediately, unless they move to another group holding a valid VASP license.

Responsibility for managing authorised VASP users rests with the research group and its designated license contact. ARC provides VASP as a managed application but does not verify, track, or audit individual licensing eligibility.

### User declaration

Use of VASP on Aire is conditional on the user’s declaration. Please contact IT with the following statement:

> *I confirm that I am an authorised user under a valid VASP group licence and will comply with the VASP Software GmbH licensing and citation conditions.*

### Download and access

Access to the VASP download portal is managed by VASP Software GmbH.

Only the group leader (or an assigned primary contact) may download VASP or manage license membership. Standard users may use VASP but cannot download the software or manage users.

### Further information

For licensing queries, contact VASP Software GmbH at
[licensing@vasp.at](mailto:licensing@vasp.at)


## Scratch space

VASP produces large temporary and output files such as `WAVECAR`, `CHGCAR`, `PROCAR`, and `vasprun.xml`.
These files can grow to tens or hundreds of gigabytes depending on system size, so choosing the right scratch location is essential for performance and cleanup.

* **Multi-node jobs:**
  Use the **shared NVMe flash filesystem** provided by Aire —
  `**$TMP_SHARED**` (path: `/mnt/flash/tmp/job.<JOB-ID>`).
  This is fast, visible to all nodes in your job, and automatically deleted when the job finishes.

* **Single-node jobs:**
  Use **node-local temporary storage** —
  `**$TMP_LOCAL**` or `**$TMPDIR**` (path: `/tmp/job.<JOB-ID>`).
  This is the fastest option for I/O-intensive runs confined to one node, but it is *not* shared across nodes.

**Best practice**

* Keep only the files required for restart or post-processing (`WAVECAR`, `CHGCAR`, `OUTCAR`).
* Avoid writing outputs to `$HOME`. It is slower, backed up, and has strict quotas.
* Always monitor disk usage; VASP can generate 10–100 GB or more of scratch data for large systems.

---

## How to submit a job

Select the appropriate binary:

| Executable | Purpose                                              |
| :--------- | :--------------------------------------------------- |
| `vasp_gam` | Γ-point-only calculations (fastest when applicable). |
| `vasp_std` | General spin-polarised calculations.                 |
| `vasp_ncl` | Non-collinear magnetism or spin–orbit coupling.      |


### Example job (VASP 6.x – Intel MPI build)

```bash
#!/bin/bash
#SBATCH --job-name=vasp_std
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=64
#SBATCH --time=04:00:00

module purge
module load vasp/6.5.1/intel-2024.2.1_impi-2021.13_hdf5-1.14.6
# (use 6.3.2/... for that version)

# Licence file (if not in $HOME)
#export VASP_LICENSE_FILE=$HOME/vasp.license

# Pure MPI run
export OMP_NUM_THREADS=1

# Run with Slurm + PMIx
srun --mpi=pmix vasp_std > vasp.out 2>&1

```

**Notes:**

* The module provides Intel MPI 2021.13 and automatically configures Slurm bootstrap via `I_MPI_HYDRA_BOOTSTRAP=slurm` (validated on Aire PMIx v5).
* Do **not** load `openmpi` or other MPI stacks.
*  Aire builds are MPI-only. Keep `OMP_NUM_THREADS=1`



## Common pitfalls

* **Mixed MPI stacks** – never load OpenMPI with the Intel MPI build.
* **Licence not found** – ensure `$VASP_LICENSE_FILE` or `$HOME/vasp.license` is valid.
* **Scratch space full** – write to `$TMPDIR` or `/mnt/scratch/$USER/vasp_scratch`.
* **Threading mismatch** – leave `OMP_NUM_THREADS=1` (pure MPI build).



## Performance notes

Performance characteristics have been validated on Aire compute nodes using the Intel oneAPI 2024.2.1 runtimes and Intel MPI 2021.13 stack.

* Initial tests show both VASP 6.3.2 and 6.5.1 scale efficiently up to **64 MPI ranks per node**.
* Scaling beyond 64 ranks per node gives diminishing returns; cross-node scaling depends on system size and FFT grid.
* Optimal configuration: **one MPI rank per physical core**, `OMP_NUM_THREADS=1`.
  (Ref: [VASP Wiki: Parallelization](https://www.vasp.at/wiki/index.php/Parallelization))
* **`vasp_gam`** is faster than `vasp_std` for Γ-point-only calculations.
* Node-local scratch (`$TMPDIR`) yields measurable I/O gains vs. shared storage.



