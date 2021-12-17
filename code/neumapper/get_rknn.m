function g = get_rknn(X,options)
% Function get_rknn
% Inputs:
% 
% X : (num_obs, num_features) data matrix.
% options : struct containing several parameters.
%       - metric     : 'euclidean', 'cityblock', etc (see choices for pdist)    
%       - k          : int, parameter for reciprocal nearest neighbor graphs
% 
% Outputs:
% g : reciprocal kNN graph.


[nnid,~] = knnsearch(X,X,'K',options.k,'Distance',options.metric);
n = size(nnid,1);
g = graph;
g = addnode(g,n);
for ii = 1:size(nnid,1)
    v = nnid(ii,:); %get vertices that ii points to
    w = max(nnid(v,:)==ii,[],2); %get vertices that also point back to ii
    e = [repmat(ii,sum(w),1),v(w)']; %build edges
    g = addedge(g,e(:,1),e(:,2));
end
g = simplify(g); % remove self loops
end