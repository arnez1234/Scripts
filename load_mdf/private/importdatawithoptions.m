function sout = importdatawithoptions(options)
% Core data import function called from GUI and comand line
% Copyright 2006-2014 The MathWorks, Inc.

  channelsImported=0;
  numDataBlocks=length(options.MDFInfo.DGBlock);
  
  if strcmpi(options.importTo,'workspace')
    ws='base';
  else
    ws='caller';
  end
  
  % Load signals
  ixOut=1;
  for dataBlock=1:numDataBlocks
    foundChannels=cell2mat(options.selectedChannelList(:,4))==dataBlock; % What channels are in this block
    thisBlockChannels=options.selectedChannelList(foundChannels,:); % Extract channel info
    selectedChannelIndices=cell2mat(thisBlockChannels(:,3));
    
    if strcmpi(options.timeVectorChoice,'actual') % If using actual time vectors
      if length(selectedChannelIndices)>=1
        % TO DO generalize time channel
        timechannel=findtimechannel(options.MDFInfo.DGBlock(dataBlock).CGBlock(1).CNBlock);
        channelIndices=sort([timechannel; selectedChannelIndices]); % Add time channel and sort
        if nargout == 0
          mdfload(options.MDFInfo,dataBlock,channelIndices,options.blockDesignation,ws,options.additionalText);
        else
          sout{ixOut} = mdfload(options.MDFInfo,dataBlock,channelIndices,options.blockDesignation,ws,options.additionalText);
          ixOut = ixOut + 1;
        end
        channelsImported=channelsImported+length(channelIndices);
      end
    else % Create ideal uniform time vectors
      
      if length(selectedChannelIndices)>=1 % If some channels in this block
        thisBlockChannelRateIndices=options.possibleRateIndices(foundChannels); % All should be the same
        rateVariableSampled=options.possibleRates(thisBlockChannelRateIndices(1)); % All same
        rateComment=options.MDFInfo.DGBlock(dataBlock).CGBlock.TXBlock.comment; % Comment rate for this block
        
        numberOfRecords=double(options.MDFInfo.DGBlock(dataBlock).CGBlock.numberOfRecords);
        channelIndices=sort(selectedChannelIndices); % sort
        if nargout == 0
          mdfload(options.MDFInfo,dataBlock,channelIndices,options.blockDesignation,ws,options.additionalText);
        else
          sout{ixOut} = mdfload(options.MDFInfo,dataBlock,channelIndices,options.blockDesignation,ws,options.additionalText);
        end
        %  Make time channel and import to choose location
        
        % Construct variable name
        switch options.blockDesignation
          case 'ratenumber'
            varName= ['time_' int2str(dataBlock) options.additionalText];
          case 'ratestring'
            varName=['time_' rateComment options.additionalText];
          otherwise
            error('Block designator not known');
        end
        varName=mygenvarname(varName); % Make legal if you can
        
        % Test if legal
        if isvarname(varName)  % If legal var name (usually is for time)
          if nargout == 0
            assignin(ws, varName, ((0:numberOfRecords-1)')*rateVariableSampled); % Save it in choose location
          else
            sout{ixOut}.(varName) = ((0:numberOfRecords-1)')*rateVariableSampled;
          end
            disp(['... and 1 ideal uniform time vector ''' varName '''']);
        else % If still not legal
          warning(['Ignoring modified signal name ''' varName '''. Cannot be turned into a variable name.']);
        end
        
        % Increment output and channel count
        if nargout == 0
          ixOut = ixOut + 1;
        end
        channelsImported=channelsImported+length(channelIndices);
      end
    end
    
    % If being called from GUI
    if ~isempty(options.waitbarhandle)
      waitbar(channelsImported/length(options.selectedChannelList),options.waitbarhandle,'Importing...');
    end
  end
  
  % Save to MAT file is requested
  if ~strcmpi(options.importTo,'workspace') % If not going to workspace
    
    % Find variables in this workspace
    vars=whos;
    allVariables=cell(1,length(vars)); % Preallocate cell array
    for var=1:length(vars)
      allVariables{var}=vars(var).name;
    end
    %%%R14Sp3%%% allVariables=arrayfun(@(x) x.name,whos,'UniformOutput',false);
    
    functionVariables={'MDFInfo';... % Variables used in the function
      'blockDesignation';'channelIndices';'channelsImported';...
      'dataBlock';'eventdata';'foundChannels';'hObject';'handles';'numDataBlocks';...
      'selectedChannelIndices';'thisBlockChannels';'uibackgroundcolor';'waitbarhandle';...
      'ws';'options';'timechannel'};
    
    % Difference is what was generated by mdfload
    generatedVariables=setdiff(allVariables,functionVariables);
    
    if strcmpi(options.importTo,'MAT-File')  % If called from GUI and MAT-File specified
      % Set MAT-file name initialy to MDF file name
      fileNameBase=options.fileName(1:end-4);
      
      % Let user specify a different name and location
      [selectionFileName,pathName]= uiputfile([fileNameBase '.mat'],'Specify MAT File to Save Signals');
      
      % Save MAT-file
      MATFileName=[pathName selectionFileName];
    else % MAT-File given as parameter
      MATFileName=options.importTo; % MAT-File is specified in import to parameter
    end
    
    % If being called from GUI
    if ~isempty(options.waitbarhandle)
      waitbar(1,options.waitbarhandle,'Saving MAT-File...');
    end
    
    save(MATFileName,generatedVariables{:});   % Save MAT-file
  end
end