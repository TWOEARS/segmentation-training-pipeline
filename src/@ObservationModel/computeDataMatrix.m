function dataMatrix = computeDataMatrix( azimuth, modelOrder )
% COMPUTEDATAMATRIX This function computes the angular data matrix of the
%   regression model, using an azimuth angle in radians as input. The model
%   order must be an odd number, as only odd factors in the sinusoidal
%   terms are considered for model building.
%
% REQUIRED INPUTS:
%   azimuth                         - Azimuth angle in radians.
%   modelOrder                      - Order of the regression model.
%                                     Corresponds to the largest
%                                     coefficient in the sinusoidal terms
%                                     of the data matrix.
%
% OUTPUTS:
%   dataMatrix                      - [N x M + 1] data matrix, where N is
%                                     the number of samples and M is the
%                                     model order.
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

% Check input arguments.

validateattributes( azimuth, {'numeric'}, {'real', '>=', -pi, '<=', pi, 'vector'} );
validateattributes( modelOrder, {'numeric'}, {'integer', 'scalar', 'odd', 'positive'} );

% Compute maximum number of iterations which satisfies the model order
% specifications and initialize data matrix. The first column of the matrix
% represents the 0-th order terms and is hence initialized with "1".
numSamples = length( azimuth );
maxIter = ( modelOrder + 1 ) / 2;
dataMatrix = zeros( numSamples, maxIter + 1 );
dataMatrix( :, 1 ) = ones( numSamples, 1 );

% Assemble data matrix.
for idx = 1 : maxIter
    dataMatrix( :, idx + 1 ) = sin( (2 * idx - 1) .* azimuth(:) );
end

end