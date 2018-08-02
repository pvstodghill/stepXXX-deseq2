# stepXXX-deseq2

Module to run [DESeq2](https://bioconductor.org/packages/DESeq2/), and
[R](https://www.r-project.org/) package for performing differential
expression analysis on, say, RNA-Seq data.

To use this module, first create a configuration file from the
template.

    $ cp config-template.bash config.bash

Then update `config.bash` according to your needs.

Finally, run the module

    $ ./doit.bash

By default, this module uses the [Docker](https://www.docker.com/) image,

<https://hub.docker.com/r/pvstodghill/deseq2/>

To use a use a native executables, uncomment the "USE_NATIVE" assignment in
the configuration file.
