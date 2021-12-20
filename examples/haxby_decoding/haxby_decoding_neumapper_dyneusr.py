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
membership = res.clusterBins
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