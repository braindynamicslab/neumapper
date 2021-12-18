function datToNPY(inFilename, outFilename, dataType, shape, varargin)
% Original repository: https://github.com/kwikteam/npy-matlab
% Please see below for details, and credit the original authors if you use
% this file.
% 
% 
% function datToNPY(inFilename, outFilename, shape, dataType, [fortranOrder, littleEndian])
%
% make a NPY file from a flat binary file, given that you know the shape,
% dataType, ordering, and endianness of the flat binary file. 
% 
% The point here is you don't want to read in all the data from the
% existing binary file - instead you can just create the appropriate header
% and then concatenate it with the data. 
%
% BSD 2-Clause License
% 
% Copyright (c) 2015, npy-matlab developers
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
% 
% 1. Redistributions of source code must retain the above copyright notice, this
%    list of conditions and the following disclaimer.
% 
% 2. Redistributions in binary form must reproduce the above copyright notice,
%    this list of conditions and the following disclaimer in the documentation
%    and/or other materials provided with the distribution.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% 


if ~isempty(varargin)
    fortranOrder = varargin{1}; % must be true/false
    littleEndian = varargin{2}; % must be true/false
else
    fortranOrder = true;
    littleEndian = true;
end

header = constructNPYheader(dataType, shape, fortranOrder, littleEndian);

fid = fopen(tempFilename, 'w');
fwrite(fid, header, 'uint8');
fclose(fid)

str = computer;
switch str
    case {'PCWIN', 'PCWIN64'}
        [~,~] = system(sprintf('copy /b %s+%s %s', tempFilename, inFilename, outFilename));
    case {'GLNXA64', 'MACI64'}
        [~,~] = system(sprintf('cat %s %s > %s', tempFilename, inFilename, outFilename));
        
    otherwise
        fprintf(1, 'I don''t know how to concatenate files for your OS, but you can finish making the NPY youself by concatenating %s with %s.\n', tempFilename, inFilename);
end
    
