function [pts_in_clusterBins, memberMat] = get_cluster_bins(pts_in_coverBins,dX)
% Function get_cluster_bins
% 
% Inputs:
% pts_in_coverBins      : cell array of cover bin membership
% dX                    : distance matrix in native space
% 
% Outputs:
% pts_in_clusterBins    : cell array of cluster bin membership
% memberMat             : cluster bin membership matrix
% 
% Notes:
% Loop through each cover bin, cluster when needed

num_coverBins = length(pts_in_coverBins);

% Store indices of the cluster bins in each cover bin
% indices_clusterBins_in_coverBin = cell(num_covBins,1);

% Initialize list of cover bins
coverBin_index = 0;
pts_in_clusterBins= [];

% Loop over cover bins. Inside each cover bin, create new cluster bins
% as needed. Extra variables defined here:
% 
% cluster_indices_within_coverBin : cluster membership in a cover bin
% 
for bin = 1:num_coverBins
    len = length(pts_in_coverBins{bin});
    
    % Split into cluster bins if needed
    if len == 0
        continue; % Pass control to next loop iteration
    elseif len == 1
        cluster_indices_within_coverBin = [1]; % single cluster
    elseif len > 1
        % Restrict distance matrix to this cover element
        coverBin_dX = dX(pts_in_coverBins{bin}, pts_in_coverBins{bin});
        % Perform clustering
        [Z, cutoff] = find_cluster_cutoff(coverBin_dX, 10, 'single');
        cluster_indices_within_coverBin = cluster(Z, 'cutoff',cutoff, 'criterion','distance');
    end
    num_clusterBins_in_coverBin = max(cluster_indices_within_coverBin);
    
    % Create cluster bins, using a separate pointer for cluster bin indices
    for j = 1:num_clusterBins_in_coverBin
        coverBin_index = coverBin_index + 1;  
        pts_in_clusterBins{coverBin_index} = pts_in_coverBins{bin}(cluster_indices_within_coverBin==j);
    end 
    
end

% Convert into membership matrix
memberMat = false(length(pts_in_clusterBins),size(dX,1));
for ii = 1:size(memberMat,1)
   memberMat(ii,pts_in_clusterBins{ii}) = true; 
end

end
