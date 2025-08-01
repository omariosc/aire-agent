# Getting Started

## What is HPC?

A High Performance Computing system, often called a Cluster or SuperComputer is a specially constructed computing system which is designed to allow multiple processors to work on the same problem at the same time and to thus speed up the rate of work above the speed of a single computer. This is very attractive to researchers as problems which might take years to run on a single processor might run 10 or 100 times faster using 10 or 100 processors in parallel, thus reducing the time to results for the researcher. Over many years, hardware and software has been developed to enhance this and to enable faster and faster supercomputers, to the extent that HPC simulations and modelling are now seen as the 3rd pillar of modern scientific research alongside theory and experiment.
While this is all well and good, it’s not magic, there is no fairy dust that can just make code run on hundreds of processors. So a lot of work and effort has to be put into using these system effectively and to get the most out of them. There are special programming models and techniques which are used to program the systems which might require you to totally rewrite your code. Nevertheless many algorithms have been implemented to run in parallel and take advantage of HPC, bringing significant benefits to research.
If you are a researcher and find that your current computational work running on your workstation is taking a long time to run, for example longer than overnight, or you find yourself trying to grab your colleagues machines and run your work on them at night or over weekends, then you might like to start to explore how HPC might help you.

## What type of work do we support?

Aire supports a number of different categories of work. These include:

**Serial jobs**, running on a single processor. We can accommodate large numbers of these, and the system provides tools to automatically manage these and co-ordinate the workflow. It is capable of running **many jobs at the same time**, without it interfering with other work on the system. There are **job arrays**, which help to automate tasks such as parameter sweeps and the processing of large numbers of datasets, using a single command to initiate the runs.
**Parallel jobs**, running on a few CPUs or more, up to the size of a single compute node. These jobs often use techniques such as OpenMP, pthreads, or tasking to spread the work for a particular run over several cores, thus reducing the overall run time.
**Multi-node parallel jobs**, these usually use the MPI programming model, which allows the user program to co-ordinate its work across large numbers of processors and nodes, and is the de facto standard for large simulations. Some codes can scale up to thousands of processors using this technique. Aire and many other HPC systems have a special hardware feature linking the nodes together, called a low latency interconnect, (an example is Infiniband) which improves the performance of these types of code, especially at larger scale.

In general we can support most areas where there are long runs that take hours, and/or there are a lot of them. The system uses the Linux OS, so if your code is Windows based, you’ll need to port it to the Linux environment, or find an existing Linux code that does the job you want. It’s well worth the small effort to learn a bit of Linux and get the benefits of running work on the HPC and the tools you can use.

## How to get started with HPC?

Before diving into HPC, it's beneficial to have discussions with your colleagues and supervisor to understand how HPC can best support your research. They can provide valuable insights and advice based on their experience. If you're new to HPC, consider taking introductory training courses such as [HPC0: Introduction to Linux for HPC](https://arc.leeds.ac.uk/courses/hpc0-introduction-to-linux-for-hpc/) and [HPC1: Introduction to High Performance Computing](https://arc.leeds.ac.uk/courses/hpc1-introduction-to-high-performance-computing/) to build a solid foundation. Additionally, explore self-help resources and join relevant teams or forums where you can ask questions and share knowledge with other HPC users. These steps will help you make the most of the HPC resources available to you.

<!-- ## Table of Contents

```{tableofcontents}
``` -->
