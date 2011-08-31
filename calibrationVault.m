classdef calibrationVault < handle
    %% CALIBRATIONVAULT Create a calibrationVault object
    %
    % calib = calibrationVault(dm,wfs,calibMatrix) create a
    % calibrationVault object storing the calibration matrix between the dm
    % and the wfs. The svd of calibMatrix is computed and used to compute
    % the dm command matix
    
    properties
        % the device to calibrate
        device;
        % the sensor used to calibrate the device
        sensor;
        % the calibration matrix
        D;
        % the SVD decomposition of the calibration matrix
        U;
        eigenValues;
        V;
        % the command matrix
        M;
        % the truncated calibration matrix based on the threshold of SVD eigen values
        truncD;
        % a matrix to project the command matrix in another sub-space
        spaceJump = 1;
        % tag
        tag = 'CALIBRATION VAULT';
    end
    
    properties (Dependent)
        % the SVD threshold
        threshold;
        % the number of tresholded eigen values
        nThresholded;
    end
    
    properties (Access=private)
        log;
        eigAxis;
        eigLine;
        p_threshold;
        p_nThresholded;
    end
    
    methods
        
        %% Constructor
        function obj = calibrationVault(device,sensor,calibMatrix)
            
            obj.device = device;
            obj.sensor = sensor;
            obj.D      = calibMatrix;
            obj.log    = logBook.checkIn(obj);
            
            
            add(obj.log,obj,'Computing the SVD of the calibration matrix!')
            
            [obj.U,S,obj.V] = svd(calibMatrix);
            obj.eigenValues = diag(S);
            
            figure
            subplot(1,2,1)
            imagesc(calibMatrix)
            xlabel('DM actuators')
            ylabel('WFS slopes')
            ylabel(colorbar,'slopes/actuator stroke')
            obj.eigAxis = subplot(1,2,2);
            semilogy(obj.eigenValues,'.')
            xlabel('Eigen modes')
            ylabel('Eigen values')
            
        end
        
        %% Destructor
        function delete(obj)
            checkOut(obj.log,obj)
        end
        
        
        %% Set/Get threshold
        function set.threshold(obj,val)
            obj.p_threshold = val;
            obj.p_nThresholded = sum(obj.eigenValues<val);
            updateCommandMatrix(obj)
        end
        function val = get.threshold(obj)
            val = obj.p_threshold;
        end
        
        %% Set/Get nTthresholded
        function set.nThresholded(obj,val)
            obj.p_nThresholded = val;
            obj.p_threshold = obj.eigenValues(end-val);
            updateCommandMatrix(obj)
        end
        function val = get.nThresholded(obj)
            val = obj.p_nThresholded;
        end
        
    end
    
    methods (Access=private)
        
        function updateCommandMatrix(obj)
            %% UPDATECOMMANDMATRIX Update the command matrix
            
            figure(get(obj.eigAxis,'parent'))
            if isempty(obj.eigLine)
                line(get(obj.eigAxis,'xlim'),ones(1,2)*obj.p_threshold,'color','r','parent',obj.eigAxis)
            else
                set('ydata',ones(1,2)*obj.p_threshold)
            end
            drawnow

            add(obj.log,obj,'Updating the command matrix!')

            iS = diag(1./obj.eigenValues(1:end-obj.nThresholded));
            [nS,nC] = size(obj.D);
            if obj.nThresholded>0
                iS(nC,nS) = 0;
            end
            obj.M = obj.V*iS*obj.U';
            obj.M = obj.spaceJump*obj.M;
        end
        
    end
end