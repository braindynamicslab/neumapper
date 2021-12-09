## **NeuMapper**


[NeuMapper](https://braindynamicslab.github.io/neumapper/) is a Matlab implementation of a scalable Mapper algorithm designed specifically for neuroimaging data analysis.

<p align="center"><img src="https://raw.githubusercontent.com/braindynamicslab/neumapper/master/docs/assets/neumapper_pipeline.png" width="75%"></p>

Developed with neuroimaging data analysis in mind, NeuMapper implements a novel landmark-based intrinsic binning strategy that eliminates the need for dimensionality reduction. Rather than projecting the high-dimensional data to a low-dimensional embedding, NeuMapper stays in high-dimensional space and performs the binning directly on a reciprocal kNN graph. By using geodesic distances, NeuMapper is able to better captures the high-dimensional, non-linear structure underlying the dynamical landscape of brain activity.

NeuMapper was designed specifically for working with complex, high-dimensional neuroimaging data and produces a shape graph representation that can be annotated with meta-information and further examined using network science tools. These shape graphs can be visualized using [DyNeuSR](https://braindynamicslab.github.io/dyneusr/), a Python visualization library that provides a custom web interface for exploring and interacting with shape graphs, and several other tools for anchoring these representations back to neurophysiology and behavior. To see how NeuMapper and DyNeuSR can be used together to create beautiful visualizations of high-dimensional data, check out the [examples](https://github.com/braindynamicslab/neumapper/tree/master/examples/) folder. See below for a [demo](https://braindynamicslab.github.io/neumapper/demo/haxby-decoding/) of the interactive visualization interface.

<p align="center">
    <iframe width="100%" height="500px" seamless frameborder="0" scrolling="no" src="./demo/haxby-decoding/"></iframe>
</p>



For more details about the original Mapper algorithm and related applications to neuroimaging data, see "[Generating dynamical neuroimaging spatiotemporal representations (DyNeuSR) using topological data analysis](https://www.mitpressjournals.org/doi/abs/10.1162/netn_a_00093)" (Geniesse et al., 2019) and "[Towards a new approach to reveal dynamical organization of the brain using topological data analysis](https://www.nature.com/articles/s41467-018-03664-4)" (Saggar et al., 2018). Check out this [blog post](https://braindynamicslab.github.io/blog/tda-cme-paper/) for more about the initial work that inspired the development of NeuMapper. 








## **Setup**

### **Dependencies**

#### [MATLAB R2020b](https://www.mathworks.com/products/new_products/release2020b.html)

* [Statistics and Machine Learning Toolbox](https://www.mathworks.com/products/statistics.html)
* [Parallel Computing Toolbox](https://www.mathworks.com/products/parallel-computing.html)







## **Demos**

- [Haxby fMRI data](https://braindynamicslab.github.io/neumapper/demo/haxby-decoding/) ([NeuMapper code](https://github.com/braindynamicslab/neumapper/blob/master/examples/haxby-decoding/haxby_decoding_neumapper.m), [DyNeuSR code](https://github.com/braindynamicslab/neumapper/blob/master/examples/haxby-decoding/haxby_decoding_neumapper_dyneusr.py))






## **Examples**

This repository includes several [examples](https://github.com/braindynamicslab/neumapper/tree/master/examples/) that introduce NeuMapper's core functions and highlight different options.


### **Trefoil knot** ([examples/trefoil_knot](https://github.com/braindynamicslab/neumapper/tree/master/examples/trefoil_knot/))


The code below walks through a simple example using NeuMapper to visualize
the shape of data sampled from a trefoil knot.

```matlab
%% Configure paths
addpath(genpath('~/neumapper/code/neumapper'));
addpath(genpath('~/neumapper/code/tools'));


%% Load the data
X = create_trefoil_knot(1000,'euclidean');


%% Configure options
options = struct();
options.binning = 'cball';
options.dimreduce = 'none';
options.resolution = 100;
options.knnparam = 8;
options.gain = 40;

options.save_to = 'trefoil_knot_neumapper.mat';
options.save_plot = 'trefoil_knot_neumapper.png';
options.show_plot = true;
options.show_embed = true;


%% Run NeuMapper
res = neumapper(X, options);
```

<p align="center"><img src="https://raw.githubusercontent.com/braindynamicslab/neumapper/master/examples/trefoil_knot/trefoil_knot_neumapper.png"></p>







### **Haxby fMRI data** ([examples/haxby_decoding](https://github.com/braindynamicslab/neumapper/tree/master/examples/haxby_decoding/))


First, let's fetch some data from the Haxby fMRI visual decoding dataset, 
using Nilearn's `fetch_haxby` function. We can then save the data and timing 
labels, so that we can read these variables into Matlab before running 
NeuMapper.

```python
import numpy as np 
import pandas as pd
from nilearn.datasets import fetch_haxby
from nilearn.input_data import NiftiMasker

# Fetch dataset, extract time-series from ventral temporal (VT) mask
dataset = fetch_haxby(subjects=[2])
masker = NiftiMasker(
    dataset.mask_vt[0], 
    standardize=True, detrend=True, smoothing_fwhm=4.0,
    low_pass=0.09, high_pass=0.008, t_r=2.5,
    memory="nilearn_cache")
X = masker.fit_transform(dataset.func[0])

# Encode labels as integers
df = pd.read_csv(dataset.session_target[0], sep=" ")
target, labels = pd.factorize(df.labels.values)
timing = pd.DataFrame().assign(task=target, task_name=labels[target])
timing_onehot = pd.DataFrame({l:1*(target==i) for i,l in enumerate(labels)})

# Save X and y
np.save('SBJ02_mask_vt.npy', X)
timing.to_csv('SBJ02_timing_labels.tsv', sep='\t', index=0)
timing_onehot.to_csv('SBJ02_timing_onehot.tsv', sep='\t', index=0)
```



Now we can simply load the data into Matlab, and run NeuMapper.

```matlab
%% Configure paths
addpath(genpath('~/neumapper/code/neumapper'));
addpath(genpath('~/neumapper/code/dimReducMethods'));
addpath(genpath('~/neumapper/code/tools'));


%% Load the data
X = readNPY('SBJ02_mask_vt.npy');
timing = readtable('SBJ02_timing_labels.tsv','FileType','text','Delimiter','\t');
colors = timing.task;
labels = string(timing.task_name);


%% Configure options
options = struct();
options.binning = 'ball';
options.dimreduce = 'bdl_isomap';
options.dim_embed = 3;
options.resolution = 240;
options.knnparam = 50;
options.gain = 40;

options.dXtype = 'correlation';
options.dXgeod = false;
options.dfXtype = 'cityblock';
options.dfXgeod = true;

options.save_to = 'haxby_decoding_neumapper.mat';
options.save_plot = 'haxby_decoding_neumapper.png';
options.show_plot = true;
options.show_embed = true;
options.colors = colors;
options.labels = labels;


%% Run NeuMapper
res = neumapper(X, options);
```

<p align="center"><img src="https://raw.githubusercontent.com/braindynamicslab/neumapper/master/examples/haxby_decoding/haxby_decoding_neumapper.png"></p>



While NeuMapper provides a basic visualization of the shape graph, to create 
a more interactive visualization, we can go back to Python and use the DyNeuSR 
visualization library. Compared to the simpler visualizations produced by 
NeuMapper, where each node is represented by the average coloring, the
visualizations produced by DyNeuSR represent each node as a pie-chart, colored 
by the relative proportion of each label associated with the node.

Note, after loading the result file in Python, a few additional steps are 
required to extract the relevant node/link information from the `memberMat` 
matrix stored in the `res` structure returned by NeuMapper.

```python
import numpy as np 
import pandas as pd
import networkx as nx
import scipy as sp
from sklearn.utils import Bunch
from scipy.io import loadmat
from dyneusr.core import DyNeuGraph  
from collections import defaultdict


## Load the NeuMapper result
mat = loadmat('haxby_decoding_neumapper.mat')
res = mat['res'][0][0]
res = Bunch(**{k:res[i] for i,k in enumerate(res.dtype.names)})
res = res.get('res', res.get('var', res))

# load one-hot encoding matrix of timing labels 
timing_onehot = pd.read_csv('SBJ02_timing_onehot.tsv', sep='\t') 


## Convert to KeplerMapper format
membership = res.memberMat.A
adjacency = membership @ membership.T
np.fill_diagonal(adjacency, 0)
adjacency = (adjacency > 0).astype(int)

# get node link data 
G = nx.Graph(adjacency)
graph = nx.node_link_data(G)

# update format of nodes  e.g. {node: [row_i, ...]}
nodes = defaultdict(list) 
for n, node in enumerate(membership):
    nodes[n] = node.nonzero()[0].tolist()

# update format of links  e.g. {source: [target, ...]}
links = defaultdict(list) 
for link in graph['links']:
    u, v = link['source'], link['target']
    if u != v:
        links[u].append(v)

# update graph data
graph['nodes'] = nodes
graph['links'] = links


## Visualize the shape graph using DyNeuSR's DyNeuGraph
dG = DyNeuGraph(G=graph, y=timing_onehot)
dG.visualize('haxby_decoding_neumapper_dyneusr.html')
```

<p align="center"><img src="https://raw.githubusercontent.com/braindynamicslab/neumapper/master/examples/haxby_decoding/haxby_decoding_neumapper_dyneusr.png"></p>




## **Related Projects** 

- [DyNeuSR](https://braindynamicslab.github.io/dyneusr/) is a Python library for visualizing topological representations of neuroimaging data. The package combines visual web components with a high-level Python interface for interacting with, manipulating, and visualizing topological graph representations of functional brain activity.



## **References**

If you find NeuMapper useful, please consider citing:
> Geniesse, C., Chowdhury, S., Saggar, M. (2021). [NeuMapper: A Scalable Computational Framework for Multiscale Exploration of the Brain's Dynamical Organization](https://direct.mit.edu/netn). *Network Neuroscience*. Under revision. 

For more information about DyNeuSR, please see:
> Geniesse, C., Sporns, O., Petri, G., & Saggar, M. (2019). [Generating dynamical neuroimaging spatiotemporal representations (DyNeuSR) using topological data analysis](https://www.mitpressjournals.org/doi/abs/10.1162/netn_a_00093). *Network Neuroscience*. Advance publication. doi:10.1162/netn_a_00093

For more information about the Mapper approach, please see:
> Saggar, M., Sporns, O., Gonzalez-Castillo, J., Bandettini, P.A., Carlsson, G., Glover, G., & Reiss, A.L. (2018). [Towards a new approach to reveal dynamical organization of the brain using topological data analysis](https://www.nature.com/articles/s41467-018-03664-4). *Nature Communications, 9*(1). doi:10.1038/s41467-018-03664-4





