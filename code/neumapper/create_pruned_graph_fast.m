function [adja_pruned, prunedMat, prunedBins] = create_pruned_graph_fast(memberMat)
% Input:
% - memberMat: matrix of nr small bins by nr datapoints. 1 if datapoint in
% smallbin

%% Find identical rows
prunedMat = unique(memberMat,'rows');

%% Create weighted adjacency matrix
n = size(prunedMat,1);

% adja_pruned = zeros(n);
% for ii = 1:n
%     for jj = ii+1:n
%         adja_pruned(ii,jj) = double(prunedMat(ii,:))*double(prunedMat(jj,:))';
%     end
% end
% adja_pruned = adja_pruned + adja_pruned';

% we can speed up the loop above by doing a single dot product
adja_pruned = double(prunedMat) * double(prunedMat)' ; 
adja_pruned = adja_pruned .* (1-eye(n));               % zero-out diagonal

prunedBins = cellfun(@find,num2cell(prunedMat,2),'UniformOutput',false);

end