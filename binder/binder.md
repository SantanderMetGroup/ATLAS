(binder)=
# Binder image deployment

This folder provides Reproducible Execution Environment Specifications (REES) to deploy a execution environment for all the scripts and notebooks included in the repository. These REES ensure the use of the same versions of all tools and libraries as those used during the development of the Atlas data and graphical products. This is the same execution environment as the virtual enviroment accessed through the MyBinder badge available in the [introduction](intro) file.

Docker users can use the *Dockerfile* file to deploy the image of the environment. This file can also be used in a local binder setup (e.g. to have access to larger amounts of memory, as compared to the free MyBinder service). Additionally, the *environment.yml* file can be used to deploy the execution environment using conda. It is advisable to create a separate conda environment using:

```sh
conda env create -n ipcc-wgi-ar6-atlas --file binder/conda/environment.yml
```


<script src="https://utteranc.es/client.js"
        repo="PhantomAurelia/Atlas"
        issue-term="pathname"
        theme="preferred-color-scheme"
        crossorigin="anonymous"
        async>
</script>