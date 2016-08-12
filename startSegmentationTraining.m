function startSegmentationTraining()
%STARTSEGMENTATIONTRAINING Summary of this function goes here
%   Detailed explanation goes here

basePath = fileparts( mfilename('fullpath') );
addpath( fullfile(basePath, 'src') );
downloadExternalLibraries();

end

