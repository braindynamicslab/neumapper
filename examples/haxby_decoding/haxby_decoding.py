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