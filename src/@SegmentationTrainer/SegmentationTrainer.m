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
        trainingParameters      % Struct-variable, containing all
                                % parameters used for training.
    end
    
    properties ( Access = private )
        parameterHash           % Hash-value that serves as a unique 
                                % identifier for a specific set of training
                                % parameters.
    end
    
    methods ( Static, Hidden )
        downloadExternalLibraries()
    end
    
    methods ( Access = public )
        function obj = SegmentationTrainer( configFile )
            % SEGMENTATIONTRAINER The class constructor is used to set all
            %   parameters desired for training. A parameter set is
            %   provided via a configuration file in *.yaml-format. Please
            %   take a look into the files provided with the example for
            %   details.
            %
            % REQUIRED INPUTS:
            %   configFile          - Configuration file in *.yaml-format.
                        
            % Check input arguments.
            p = inputParser();
            p.addRequired( 'ConfigFile', @(x) exist(x, 'file') );
            p.parse( configFile );
            
            % Automatically download all external toolboxes that are needed
            % for training the SegmentationKS.
            obj.downloadExternalLibraries();
            
            % Read configuration file and get all contained parameters.
            obj.trainingParameters = ReadYaml( p.Results.ConfigFile );
            
            % Compute parameter hash for current settings.
            obj.parameterHash = DataHash( obj.trainingParameters );
        end
    end    
end