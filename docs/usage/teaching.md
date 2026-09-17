# Teaching on Aire

Aire provides dedicated teaching partition for practical classes, demonstrations, and other teaching activities. Teaching jobs use a cohort-specific Slurm account and the `teachingnodes` partition.

Teaching accounts are created for each cohort. Your lecturer or teaching coordinator will provide the account code and arrange access for teaching staff and students. Replace `teaching_account` in the examples below with the account code provided for your cohort.

:::{important}
You must specify both the teaching account and the `teachingnodes` partition when submitting a job. Teaching accounts can only be used with the teaching partition.
:::

## Submitting a teaching job

You can specify the account and partition in the job script:

```bash
#!/bin/bash
#SBATCH --job-name=teaching_job
#SBATCH --time=00:10:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=1G
#SBATCH --output=teaching_job.out
#SBATCH --partition=teachingnodes
#SBATCH --account=teaching_account    # Remember to replace the teaching account ID!

echo "Job started at: $(date)"
echo "Running on node: $(hostname)"
echo "Current directory: $(pwd)"
echo "Number of CPUs: $SLURM_CPUS_PER_TASK"
echo "Account: $SLURM_JOB_ACCOUNT"
echo "Partition: $SLURM_JOB_PARTITION"

# Run your teaching workload here
echo "Running a simple test..."
sleep 10
echo "Test complete!"

echo "Job finished at: $(date)"
```

Save the script, for example as `teaching_job.sh`, and submit it with:

```bash
sbatch teaching_job.sh
```

The account and partition must be specified in the job script as shown above. You can check the status of your jobs with `squeue --me` and cancel a job with `scancel <job_id>`.

## Teaching job limits

The following limits apply to each teaching cohort:

- Maximum runtime per job: 8 hours
- Maximum CPUs per job: 8
- Maximum running jobs at one time: 3
- Maximum jobs submitted at one time: 10
- Group CPU limit across the cohort: 336 CPUs

You can submit more jobs than can run at once, up to the submission limit. Jobs beyond the running limit wait in the queue until resources become available.

## Accounts and partitions

Users who have more than one Slurm account must specify which account to use for each job. Your normal account can be used with the regular partitions, while a teaching account must be used with `teachingnodes`. You can verify all Slurm accounts associated with your user using:

```bash
sacctmgr show user withassoc format=account where name=$USER
```

```{note}
For help with the cohort account, access permissions, or teaching job limits, contact the lecturer or teaching coordinator responsible for the class.
```
