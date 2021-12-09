function [pts_in_smallBin, pts_in_bigBin, hrfdur_stat] = cbMapper(X,dX,options)
% Function cbMapper = connected b-Mapper
% Takes a distance matrix as input, builds a knn graph, and
% returns a cover of the graph. The cover includes disconnected pieces of
% the knn graph. 
% 
% Input includes data and fixed r,k,g values. For optimization, look at
% optim_cbMapper
% 
% Apr 13, 2020
% samirc@stanford.edu

%% Obtain options. If a parameter is missing, switch to a default value.
resolution  = getoptions(options,'resolution',30);
gain        = getoptions(options,'gain',25);
k           = getoptions(options,'knnparam',3);
hrfdur      = getoptions(options,'hrfdur',11);
hrfdurprc   = getoptions(options,'hrfdurprc',0.3);
tr          = getoptions(options,'tr',1.5);
dfXtype     = getoptions(options,'dfXtype','cityblock');
sl_histo_bins = getoptions(options,'sl_histo_bins',10);

%% For while loop used below, check that exit conditions are okay
if max(hrfdurprc) > 1
    error('Check hrfdurprc')
end

%% Check that helper files have been loaded
if ~exist('px_maxmin.m','file')
    error('Load the "tools" folder')
end

%% Compute cbMapper

%hrfdur = 11; %seconds. hrfdurpc % bins have two nodes that are at least hrfdur s apart
% tr = 1.5;

rad = ceil(hrfdur/tr); 

% ev_help = @(v) find(v,1,'last') - find(v,1,'first');
cv_help = @(v) max(v) - min(v);

memberMat = construct_cover(X,resolution,gain,k,dfXtype);%first pass
pts_in_bigBin = cellfun(@find,num2cell(memberMat,2),'UniformOutput',false);
pts_in_smallBin = pc_sl_hist(pts_in_bigBin,dX,sl_histo_bins);%second pass
cover_width = cellfun(cv_help,pts_in_smallBin);
hrfdur_stat = sum(cover_width > rad)/length(cover_width);

end


