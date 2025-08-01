(page:rules)=
# Rules and Regulations for using Aire

HPC systems are shared systems and support many users simultaneously. There are tools and protocols in place which allow the different tasks  from different users to co-exist on the one system, but they aren’t 100% bullet proof. You are required to use the appropriate tools and protocols we offer on the system and to ensure that your programs don’t misbehave by interfering with other work. You are also required to ensure that your runs are efficient and make good use of the resources. **We will terminate, without warning, runs which do not meet these criteria.**

Occasionally we will ask you to modify your usage, or to not run certain tasks which cause issues. We appreciate your co-operation in this and will try to help you find ways to avoid the issues. If you find a colleague causing issues, please advise them and contact us so we can help. Please be considerate to your fellow users and the community as a whole.
We reserve the right to disable your access to Aire without warning if we perceive you are causing problems. We will normally try to contact you beforehand.

:::{Note}
In exceptional circumstances when required, we reserve the right to access and/or modify any of your files on the system. While this is not usual , it may be necessary to do this for example to resolve a system issue.
:::

Ensure that you have a valid e-mail address and that you monitor it when you are running work. This will be the normal way we, and the system itself, will communicate with you, especially of there are problems or errors occurring.

:::{warning}
The HPC service is not intended for processing sensitive or personal data. In general data which has been de-identified (eg the names have been removed, so that an individual cannot be identified from the data) can be used on the system. If in doubt, you should seek advice.

Personal or sensitive data must not be stored on the system.
:::

## HPC Acknowledgement

When you publish research papers, or make posters or presentations at conferences and the like, we ask that you give credit for use of the service. The following sentence is appropriate in your acknowledgements:

> This work was undertaken on the Aire HPC system at the University of Leeds, UK.

## Fair share/priority

As well as managing resources, the scheduler also looks after job priorities.

On Aire a **fair share algorithm** is used to manage job priorities. The basis of fair share is that as you use more and more resources over time, your priority reduces in proportion to your usage. This happens to all users. The net effect is that less usage gives you higher priority, and heavier usage decreases your priority. This is applied to all users, in proportion to your usage. Thus, when you submit a job, a job submitted by another user later on may run before yours, if your usage is higher than the second user.

Your usage value is periodically aged, so that with time your priority goes up again. This helps smooth the usage pattern over longer periods of time, so you don’t suffer from lower priority forever.

The purpose of fair share is to give users equitable and reasonable access to the HPC resources. The HPC systems are shared by many users. Fair share prevents one, or a small group of users from dominating the system and using up large proportions of the available resources. Additionally it does not prevent any users from running work if there are spare/idle resources that can run that work.

For example, if you are a heavy user, you may find that a large job submitted at lunchtime does not start quickly, as lots of other users are also running work and your priority is quite low, as you’ve consumed lots of resources in the preceding days. However, by late evening or nighttime, the system will have completed a lot of work, and you may find that your job starts overnight. If you go on holiday for a couple of weeks and don’t run work, your priority will have improved, and when you return, your jobs may start running sooner.
In practice this means everyone gets a fair amount of work run and the system is fully utilised as much as possible.

:::{note}
Note that **short test jobs**, such as debugging runs are treated separately by the scheduler and you should be able to run small numbers of such jobs alongside your other work without undue delays.
:::
