function memberMat = get_cover_bins(g,resolution,gain)
% Function get_cover_bins
% 
% Inputs:
% g             : rkNN graph
% resolution    : int, number of landmarks for farthest point sampling
% gain          : int, used to create overlaps
% 
% Outputs:
% memberMat     : cover bin membership matrix
% 
% Notes:
% For disconnected rkNN graphs, the number of landmarks is divided 
% proportional to the size of each connected component.

n = g.numnodes;
[cc,ccs] = conncomp(g);
binAlloc = ceil((ccs/n)*resolution); %grab extra landmarks if needed

memberMat = zeros(sum(binAlloc),n); %membership Matrix
landmk_idx_in_g = zeros(size(memberMat,1),1);

curr_row = 1;curr_col = 1;
% Loop over connected components
for ii = 1:size(ccs,2)
   sg = subgraph(g,cc==ii);
   dX = sg.distances;
   memberSubMat = zeros(binAlloc(ii),ccs(ii));
   
   % FPS
   [landmk_idx, dist_to_landmk, epsilon] = px_maxmin(dX,'metric',binAlloc(ii),'n', 1,'seeds');
   for jj = 1:binAlloc(ii)
        tmp = dist_to_landmk(jj,:);
        pt_idx = tmp <= max((gain/100)*(4*epsilon), eps);
        % Gain should be at least 25 to make sure we're covering the dataset
        memberSubMat(jj,:) = pt_idx;
   end
   next_row = curr_row + binAlloc(ii) -1;
   next_col = curr_col+ccs(ii) -1;
   
   memberMat(curr_row:next_row,curr_col:next_col) = memberSubMat;
   landmk_idx_in_g(curr_row : next_row) = curr_col -1 + landmk_idx;
   
   curr_row = next_row + 1;
   curr_col = next_col + 1;
end

end