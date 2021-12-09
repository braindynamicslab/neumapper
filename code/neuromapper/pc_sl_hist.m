function [pts_in_smallBin, bigbin_idx_in_smallBin] = pc_sl_hist(...
                    pts_in_bigBin, distMat, sl_histo_bins, linkage_method)
% Function pc_sl_hist
% Partial clustering with single linkage and histograms

% Notation: Mapper does two binning steps. We give the name "bigBins" to
% the bins produced in the first pass. Each bigBin is then clustered
% further through a partial clustering step. The resulting clusters are
% called "smallBins".

% Inputs: 
% (1) cell array of bigBins containing indices of the data points in
% each bigBin 
% (2) full distance matrix of original space
% (3) number of histogram bins used when determining the cutoff

% Output: cell array of smallBins containing indices of the data points in
% each smallBin. 

if nargin < 4
    linkage_method = 'single';
end

% Implementation notes: loop through each bigBin, cluster when possible

num_bigBins = length(pts_in_bigBin);

% The next variable stores, for each bigBin, the indices of the smallBins
% in that bigBin.
indices_smallBins_in_bigBin = cell(num_bigBins,1);

% Initialize list of smallBins
smallBin_index = 0;
pts_in_smallBin= [];
bigbin_idx_in_smallBin = [];


for bin = 1:num_bigBins
% First we use an if statement to figure out how many smallBins will be
% produced from the current bigBin (i.e. how many clusters we will obtain)
% Then we loop over each smallBin to record the indices of the observations
% in the smallBin.
    
    len = length(pts_in_bigBin{bin});
    
    if len == 0
       %fprintf(1,'Level set is empty\n');
       indices_smallBins_in_bigBin{bin} = -1;
       continue;
    elseif len == 1
       %fprintf(1,'Level set has only 1 pt\n');
       num_smallBins_in_bigBin = 1;
       cluster_indices_within_bigBin = [1];
       % initialize a new smallBin and give it an index
       indices_smallBins_in_bigBin{bin} = smallBin_index + 1;
    elseif len > 1
       %fprintf(1,'Level set has %d pts\n', len);
       % get restriction of distance matrix
       bigBin_distMat = distMat(pts_in_bigBin{bin}, pts_in_bigBin{bin});
       
       % perform clustering
       [Z, cutoff] = find_cluster_cutoff(bigBin_distMat, sl_histo_bins, linkage_method);
       cluster_indices_within_bigBin = cluster(Z, 'cutoff',cutoff, 'criterion','distance');
       
       % above returns a list of clusters [1:number of clusters]
       num_smallBins_in_bigBin = max(cluster_indices_within_bigBin);
       % initialize new smallBins, give them indices relative to the last
       % used index
       indices_smallBins_in_bigBin{bin} = smallBin_index + ...
                                            (1:num_smallBins_in_bigBin);
    end
    
    for j = 1:num_smallBins_in_bigBin 
    % if the latter was not defined, i.e. we had len==0, then the continue
    % statement passes to the next iteration of the enclosing loop
    
       % iterate counter for each new smallBin
       smallBin_index = smallBin_index + 1;  
       pts_in_smallBin{smallBin_index} = pts_in_bigBin{bin}(cluster_indices_within_bigBin==j);
       bigbin_idx_in_smallBin{smallBin_index} = bin;
%      pts_in_smallBin changes size on each iteration, which can likely be 
%      optimized. But this is not immediate because we do not know how many
%      smallBins will be created, a priori.
       
    end
end
end

