# Job Priority

The Slurm scheduler manages resources and decides the order in which jobs run. On Aire, a **fair share algorithm** is used to calculate the priority for each job. The idea is simple:
* With more use of resources priority decreases for a user.
* With less use of resources priority increases for a user.

Usage is **aged over time**, so priority improves for all users until they match when jobs are scheduled based on resource availability and the order in which they are submitted. The system gradually reduces the impact of past resource usage when calculating job priority. This is also known as "ageing" or "decay".


## Fair Share: What to expect

* The scheduler recalculates job priorities and reschedules jobs regularly as new jobs are submitted, jobs start running, and resource availability changes.
* After priorities are updated, the order of jobs in the queue adjusts based on resource availability, requested resources, and job priority.
* A new job that requests the same resources (time, memory, CPU/GPU) but has higher priority will be scheduled ahead of jobs submitted earlier with lower priority. This can look like queue jumping, but it’s the result of periodic priority updates.
* The scheduler may fit small jobs, those requesting fewer resources for shorter periods, around larger jobs to utilise available resource.
* After a job finishes, the actual resources used, not the requested resources, are factored into the user’s future job priority. Because a job will fail if it doesn’t request enough resources, it’s better to slightly overestimate. However, requesting significantly more resources than needed can increase queue time.

