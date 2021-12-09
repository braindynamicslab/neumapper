function [adja_pruned, prunedMat, prunedBins] = create_pruned_graph(memberMat)

%% Find identical rows
prunedMat = unique(memberMat,'rows');

%% Create weighted adjacency matrix
n = size(prunedMat,1);
adja_pruned = zeros(n);

for ii = 1:n
    for jj = ii+1:n
        adja_pruned(ii,jj) = double(prunedMat(ii,:))*double(prunedMat(jj,:))';
    end
end
adja_pruned = adja_pruned + adja_pruned';

prunedBins = cellfun(@find,num2cell(prunedMat,2),'UniformOutput',false);

end