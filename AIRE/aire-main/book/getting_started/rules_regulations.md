(page:rules)=

<!--
IMPORTANT:
This document defines formally approved rules and regulations for the Aire HPC service.
Substantive changes to meaning, policy, or requirements MUST NOT be made without formal approval from the relevant governance body.

Readability improvements, formatting changes, typo corrections, and link fixes are welcome, provided they do not alter the approved content or intent.
-->

# Rules and Regulations for using Aire

Aire is a shared High Performance Computing (HPC) system that supports many users simultaneously. To enable different users’ work to co-exist effectively, there are tools and protocols in place to manage access to resources. These mechanisms are not infallible, so all users are required to use the system responsibly and in accordance with these rules.

You must use the appropriate tools and protocols provided on the system and ensure that your programs do not interfere with other users’ work. You are also required to ensure that your workloads are efficient and make good use of the resources allocated to them. **Runs that do not meet these criteria may be terminated without warning**.

## Responsibilities of Users

- Use the system in a way that is considerate of other users and the wider research community.
- Ensure that your programs and workflows do not negatively affect system stability or other users’ jobs.
- Be prepared to modify your usage or avoid running particular tasks if requested to do so by the system administrators in order to resolve issues.
- Ensure that you have a valid email address and monitor it while running work on the system. Email is the primary method by which system administrators and automated system messages will contact you, particularly if problems or errors occur.

*If you become aware of a colleague causing issues on the system, please advise them and contact the <a href="https://leeds.service-now.com/it?id=sc_cat_item&sys_id=7587b2530f675f00a82247ece1050eda" target="_blank">service team</a>  so that assistance can be provided.*

## Enforcement and Access

- We reserve the right to terminate runs without warning if they interfere with other users or the operation of the system.
- We also reserve the right to disable access to Aire without warning if we believe a user is causing problems.

*Where possible, we will normally try to contact users beforehand to resolve issues cooperatively.*

## System Access and File Management

- In exceptional circumstances, we reserve the right to access and/or modify any user files on the system.

*While this is not normal practice, it may be necessary, for example, to resolve a system issue or restore service operation.*

## Sensitive and Personal Data

- Personal or sensitive data must not be stored or processed on the system.
- In general, data that has been de-identified (for example, where names have been removed such that individuals cannot be identified) may be used on the system.

Additional guidance about data is available at:

- <a href="https://it.leeds.ac.uk/it?id=kb_article_view&sysparm_article=KB0018252" target="_blank">Research information management guide to data classification</a>: Define data confidentially tiering and help you to assess data sensitivity.
- <a href="https://it.leeds.ac.uk/sys_attachment.do?sys_id=b0d335c6fb402a5033b5fd9aaeefdc64&view=true" target="_blank"> Research Information Management Guide (PDF)</a> Sets out what kinds of research data can be stored in what kinds of storage solution for each tier.

If you are unsure whether your data is appropriate for use on Aire, you should seek advice before proceeding.

## Fair Share, Job Priority, and Scheduling

Aire is a shared HPC service used by many users concurrently. To ensure fair, equitable, and efficient access to resources:

- Jobs must be submitted via the centrally managed scheduler. Users are required to use the Slurm scheduler to run processes on compute nodes.
- Job scheduling and prioritisation are managed centrally by the system scheduler.
- A fair share algorithm is used to balance access to resources across users over time.
- The purpose of fair share is to prevent individual users or groups from disproportionately consuming shared resources and to support reasonable access for all users.
- System administrators will periodically review scheduler priority and fair share parameters to ensure that resource usage remains fair and appropriate under changing patterns of demand.

Further technical and operational details of job scheduling and fair share are documented separately [here](page:job-scheduler).

## Acknowledging Use of Aire

When publishing research papers, posters, presentations, or similar outputs that have made use of the system, users are asked to acknowledge the service. The following sentence is appropriate:

> This work was undertaken on the Aire HPC system at the University of Leeds, UK.
