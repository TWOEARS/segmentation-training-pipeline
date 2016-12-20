function [dataObj, managerObj, requests, afeParameters] = ...
    setupAuditoryFrontend( trainingParameters )
% SETUPAUDITORYFRONTEND This function initializes a data and a manager
%   object of the Two!Ears Auditory Front-End for a given set of training
%   parameters.
%
% REQUIRED INPUTS:
%   trainingParameters              - Struct-variable, containing all
%                                     parameters used for training.
%
% AUTHOR:
%   Copyright (c) 2016      Christopher Schymura
%                           Cognitive Signal Processing Group
%                           Ruhr-Universitaet Bochum
%                           Universitaetsstr. 150
%                           44801 Bochum, Germany
%                           E-Mail: christopher.schymura@rub.de
%
% LICENSE INFORMATION:
%   This program is free software: you can redistribute it and/or
%   modify it under the terms of the GNU General Public License as
%   published by the Free Software Foundation, either version 3 of the
%   License, or (at your option) any later version.
%
%   This material is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program. If not, see <http://www.gnu.org/licenses/>

% Check inputs.
p = inputParser();
p.addRequired( 'TrainingParameters', @isstruct );
p.parse( trainingParameters );

% Initialize cell-array of requests. Only binaural cues are needed to train
% models for the SegmentationKS.
requests = {'itd', 'ild'};

% Generate Two!Ears Auditory-Front-End parameter structure.
afeParameters = genParStruct( ...
    'pp_bNormalizeRMS', trainingParameters.features.normalize_rms, ...
    'pp_bMiddleEarFiltering', trainingParameters.features.use_middle_ear_filter, ...
    'pp_middleEarModel', trainingParameters.features.middle_ear_model, ...
    'fb_type', trainingParameters.features.filterbank, ...
    'fb_lowFreqHz', trainingParameters.features.fb_low_freq, ...
    'fb_highFreqHz', trainingParameters.features.fb_high_freq, ...
    'fb_nChannels', trainingParameters.features.fb_num_channels, ...
    'ihc_method', trainingParameters.features.ihc_model, ...
    'cc_wSizeSec', trainingParameters.features.win_size, ...
    'cc_hSizeSec', trainingParameters.features.hop_size, ...
    'cc_maxDelaySec', trainingParameters.features.cc_maxDelaySec, ...
    'cc_wname', 'hann', ...
    'ild_wSizeSec', trainingParameters.features.win_size, ...
    'ild_hSizeSec', trainingParameters.features.hop_size, ...
    'ild_wname', 'hann' );

% Initialize AFE manager and data objects. As some annoying warnings can
% occur during intitialization, these are suppressed here.
warning( 'off', 'all' );
dataObj = dataObject( [], trainingParameters.simulator.fs, 1, 2 );
managerObj = manager(dataObj, requests, afeParameters);
warning( 'on', 'all' );

end
