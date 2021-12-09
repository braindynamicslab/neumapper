function dX = buildDist(X,options)
% Function buildDist
% Create a distance matrix from data matrix X


% Options for metric
dXtype      = getoptions(options,'dXtype','euclidean');
dXgeod      = getoptions(options,'dXgeod',true);
num_k       = getoptions(options,'knnparam',6);
pknng       = getoptions(options,'pknng',true);


tmpdx       = pdist2(X,X,dXtype); %use for normalization
% force symmetrization; sometimes Matlab has round-off errors
tmpdx       = (tmpdx + tmpdx')/2;

diam        = max(max(tmpdx));

if dXgeod 
    %fprintf("Computing geodesic distances...\n");
    %[~, mapping] = bdl_isomap(X,2,num_k,pknng,dXtype);
    [~, mapping] = bdl_isomap(tmpdx,2,num_k,pknng); % Oct 8, 2019

    dX           = mapping.graphDist;
    % normalize to have original diameter
    graphDiam    = max(max(dX));
    tmp          = graphDiam/diam;
    dX           = dX./tmp;
else
    %fprintf("Using non-geodesic distances (metric = %s)\n", dXtype);
    dX           = tmpdx;
end

