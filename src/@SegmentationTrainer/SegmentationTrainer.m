classdef SegmentationTrainer < handle
    % SEGMENTATIONTRAINER This is the base class for training models for
    % the segmentation knowledge source.
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
    
    properties ( GetAccess = public, SetAccess = private )
        models                  % List of trained models according to the
                                % specified config-files.
    end
    
    properties ( Access = private )
        configFiles             % List of config file names.
    end
    
    methods ( Access = public )
        function obj = SegmentationTrainer( varargin )
            % SEGMENTATIONTRAINER The class constructor is used to set all
            %   parameters desired for training. A parameter set is
            %   provided via a configuration file in *.yaml-format. Please
            %   take a look into the files provided with the example for
            %   details.
            %
            % REQUIRED INPUTS:
            %   [configFile1, configFile2, ...] - Configuration files 
            %                                     in *.yaml-format.
                        
            % Automatically download all external toolboxes that are needed
            % for training the SegmentationKS.
            downloadExternalLibraries();
            
            % Loop over all configuration files that should be processed.
            obj.models = cell( nargin, 1 );
            obj.configFiles = cell( nargin, 1 );
            
            for fileIdx = 1 : nargin
                % Check if file exists.
                if exist( varargin{fileIdx}, 'file' )
                    % Read configuration file and get all contained 
                    % parameters.
                    trainingParameters = ReadYaml( varargin{fileIdx} );
                    
                    % Append config file name to class properties.
                    [~, obj.configFiles{fileIdx}] = fileparts( varargin{fileIdx} );
                    
                    % Train/load corresponding observation model.
                    obj.models{fileIdx} = ObservationModel( trainingParameters );
                else
                    error( 'SegmentationTrainer:SegmentationTrainer:FileNotFound', ...
                        ['The file ', varargin{fileIdx}, ' does not exist.'] );
                end
            end
        end
        
        showTrainingResults( obj )
    end    
end