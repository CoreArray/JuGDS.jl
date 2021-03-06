jugds: Julia Interface to CoreArray Genomic Data Structure (GDS) Files
===

![GPLv3](http://www.gnu.org/graphics/gplv3-88x31.png)
[GNU General Public License, GPLv3](http://www.gnu.org/copyleft/gpl.html) (2015-2020)

[![Build Status](https://travis-ci.org/CoreArray/jugds.jl.svg?branch=master)](https://travis-ci.org/CoreArray/jugds.jl)

pre-release version: v0.1.0


## Features

This package provides a high-level Julia interface to CoreArray Genomic Data Structure (GDS) data files, which are portable across platforms with hierarchical structure to store multiple scalable array-oriented data sets with metadata information. It is suited for large-scale datasets, especially for data which are much larger than the available random-access memory. The jugds package offers the efficient operations specifically designed for integers of less than 8 bits, since a diploid genotype, like single-nucleotide polymorphism (SNP), usually occupies fewer bits than a byte. Data compression and decompression are available with relatively efficient random access.


## Installation

* Development version from Github, requiring `julia >= v1.0`
```julia
using Pkg

Pkg.status()
Pkg.add(PackageSpec(url="https://github.com/CoreArray/jugds.jl.git"))
```


## Package Maintainer

Dr. Xiuwen Zheng ([zhengxwen@gmail.com](zhengxwen@gmail.com))


## Tutorials

* Learn X in Y minutes (where X=Julia): [http://learnxinyminutes.com/docs/julia/](http://learnxinyminutes.com/docs/julia/)


## Citation

#### Original papers (implemented in R/Bioconductor):

Zheng X, Levine D, Shen J, Gogarten SM, Laurie C, Weir BS (2012). A High-performance Computing Toolset for Relatedness and Principal Component Analysis of SNP Data. *Bioinformatics*. [DOI: 10.1093/bioinformatics/bts606](http://dx.doi.org/10.1093/bioinformatics/bts606).

Zheng X, Gogarten S, Lawrence M, Stilp A, Conomos M, Weir BS, Laurie C, Levine D (2017). SeqArray -- A storage-efficient high-performance data format for WGS variant calls. *Bioinformatics*. [DOI: 10.1093/bioinformatics/btx145](http://dx.doi.org/10.1093/bioinformatics/btx145).


## Copyright Notice

* CoreArray C++ library, [LGPL-3 License](./COPYRIGHTS), 2007-2017, Xiuwen Zheng


## Examples

```julia
using jugds

fn = abspath(dirname(pathof(jugds)), "..", "demo", "data", "ceu_exon.gds")
f = open_gds(fn)
f
close_gds(f)
```

```
File: jugds/demo/data/ceu_exon.gds (32.5K)
+    [  ] *
|--+ description   [  ] *
|--+ sample.id   { Str8 90 LZMA_ra(35.8%), 258B } *
|--+ variant.id   { Int32 1348 LZMA_ra(16.8%), 906B } *
|--+ position   { Int32 1348 LZMA_ra(64.6%), 3.4K } *
|--+ chromosome   { Str8 1348 LZMA_ra(4.63%), 158B } *
|--+ allele   { Str8 1348 LZMA_ra(16.7%), 902B } *
|--+ genotype   [  ] *
|  |--+ data   { Bit2 1348x90x2 LZMA_ra(26.3%), 15.6K } *
|  |--+ extra.index   { Int32 0x3 LZMA_ra, 19B } *
|  \--+ extra   { Int16 0 LZMA_ra, 19B }
|--+ phase   [  ]
|  |--+ data   { Bit1 1348x90 LZMA_ra(0.91%), 138B } *
|  |--+ extra.index   { Int32 0x3 LZMA_ra, 19B } *
|  \--+ extra   { Bit1 0 LZMA_ra, 19B }
|--+ annotation   [  ]
|  |--+ id   { Str8 1348 LZMA_ra(38.4%), 5.5K } *
|  |--+ qual   { Float32 1348 LZMA_ra(2.26%), 122B } *
|  \--+ filter   { Int32,factor 1348 LZMA_ra(2.26%), 122B } *
\--+ sample.annotation   [  ]
   \--+ family   { Str8 90 LZMA_ra(57.1%), 222B }
```


## Also See

[JSeqArray.jl](https://github.com/CoreArray/JSeqArray.jl): data manipulation of whole-genome sequencing variants in Julia
