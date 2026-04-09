# Data lifecycle management

:::{warning}
This page is still being updated. If you have any feedback regarding this section, please contact the RSE team.
:::

## Storage Tiers and Policies

- Scratch Storage

  * Purpose: Temporary storage for data generated during active job execution.
  * Location: `/mnt/scratch/users/`
  * Retention: Data in scratch storage is not automatically deleted and is not backed up. Users are responsible for managing their scratch data.
  * Quota: A storage quota is applied to scratch directories. Exceeding your quota may prevent you from saving or moving additional data. Ensure that your data usage stays within the allocated limit.
  * Best Use: Store intermediate files and large datasets during active computations. Data should be moved to a more permanent storage location once it is no longer required in scratch storage.

- Home Directories

  * Purpose: Personal storage for code, configurations, and small datasets.
  * Location: `/users/<username>`
  * Retention: Data in home directories is occasionally backed up by the system. However, backups can only be restored within 7 days of the backup date.
  * Quota: A default quota of 15GB is applied to home directories. Users who require more space can request an increase to their storage quota.
  * Best Use: Store essential files, scripts, and results that need to be preserved long-term.

- Shared Project/Research Storage

  * Purpose: Collaborative storage for teams or research groups to share large datasets and results.
  * Location: TBC
  * Retention: Managed based on project needs and user policies.
  * Best Use: Store large datasets shared between team members or across projects.

## Best Practices for Data Management

- Organising Data: Use a consistent and logical folder structure to manage your files. For example:

  ```
  /home/username/project_name/
      ├── code/       # Store your code and scripts here
      ├── data/       # Place your input data and large datasets here
      ├── results/    # Store the output files and results here
      └── README.txt  # Key details about the project, data, and any relevant information
  ```
  * README.txt Example

  > Project: HPC Data Analysis
  >
  > This directory contains the data and scripts for the analysis of computational fluid dynamics results.
  >
  > /code/ contains all the scripts and programmes used for data processing and simulation.
  > /data/ contains raw input data and intermediate files.
  > /results/ contains the final output, including analysis and visualisation.
  >
  > Important Notes:
  > 1. Make sure to regularly back up the data in /data and /results.
  > 2. For any questions, contact [Your Name] at [Your Email].

- Efficient Storage Usage: 

  * Regularly clean up your scratch storage to ensure you don't exceed your quota.
  * Compress large datasets using tools like `tar` or `gzip` to reduce storage consumption.
  * Remove any obsolete data from scratch storage to free up space for new work.

- Data Transfer

  * Use `rsync` and `scp` for transferring data securely and efficiently.
  * For large datasets, consider using parallel data transfer tools like Globus for faster, multi-threaded transfers.

- Data Backup
- Version Control

## Temporary vs Long-term Data

- Temporary Data: Scratch storage is intended for temporary data that can be removed after job completion. As it is not backed up, make sure to transfer any important data to home directories or permanent storage before it's deleted or overwritten.

- Long-term Data: For files that need to be kept beyond the lifetime of a job, use home directories for small files, and shared project/research storage or other permanent storage for large files.

## Monitoring Storage Usage

- Check Usage: Monitor your scratch directory storage to ensure you stay within your quota:

```bash
du -hs /mnt/scratch/users/<username>/
```

- Check Quotas: To verify your current storage quota and limits, use:

```bash
quota -s
```

If you are nearing your quota, consider cleaning up or transferring data to home or project storage. If more space is required, contact HPC support for assistance.

## Data Security and Compliance

- Access Control: Set appropriate file permissions using `chmod` and `chown` to ensure that sensitive data is only accessible to authorised users.
- Secure Data Transfers: Always use secure methods (e.g., `scp`, `rsync`, or Globus) when transferring data, especially for sensitive or confidential files.
- Compliance: Ensure your data management practices align with legal and regulatory requirements, such as General Data Protection Regulation (GDPR) and NHS Privacy Enhancing Technology (PET), if applicable.

## End-of-Project Data Archival

- Archiving or Deletion: At the end of a project, move relevant data to an archive storage (for example, OneDrive) for future access. Ensure that any necessary backups are taken before the project is completed.
- Cleanup: Clean up scratch and home directories to free up space for future users and projects.
- Documentation: Include clear documentation about archived data, including directory structures and any important details in `README.txt` files.
