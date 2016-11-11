%% Read a shape file and set a value
%
% More info can be found at these places:
%  http://www.mathworks.com/access/helpdesk_r13/help/toolbox/map/shaperead.html
%  http://www.mathworks.co.uk/access/helpdesk/help/toolbox/map/f20-15124.html
%  
% Note two tricksy things about the fieldNames
% and fieldVals parameters:
% - If fieldNames has length of 2 then we assume 
%   that fieldNames(1) is the lookup column, and 
%   that fieldNames(2) is the column to update;
%   but if length is 1 then we assume that there
%   is no lookup to do and that the user somehow
%   knows the right order of the rows in the dbf
%   component of the shapefile.
%   --------------
%   NOTE: fieldNames is assumed to be a cell
%   --------------
% - If fieldVals has column-size of 2 then we assume
%   that the first column contains the lookup field
%   and that the second column contains the value to
%   write to the shapefile.
function appendDataToShape(srcFile,destFile,fieldNames,fieldVals)
    
    debugging = 0;
    format short;

    fprintf('Reading shape file: %s\n',srcFile);
    if debugging == 1
        shapeinfo(srcFile)
    end
    
    S    = shaperead(srcFile);
    spec = makedbfspec(S);
    
    if debugging == 1
        spec
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Some operations that can be
    % performed on a shape file
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Remove a field from the dbfspec
    % spec = rmfield(spec,'Count_');
    
    % Update a field from the dbfspec
    % spec.BAR.FieldName = 'Rebar';
    % spec.BAR.FieldDecimalCount = 1;
    
    % What fields are there?
    % fieldnames(S)
    
    % Modify a struct to add a new field
    % -- except this doesn't seem to work
    % with shapefiles!!!
    %
    % spec().CLUST_ID = struct('FieldName','CLUST','FieldType','N','FieldLength',3,'FieldDecimalCount',0);
    % S().CLUST = [];
    
    % Set the field names
    lookupColumn = NaN;
    appendColumn = NaN;
    
    if (size(fieldNames,2) == 1) 
        appendColumn = fieldNames{1};
    else 
        lookupColumn = fieldNames{1};
        appendColumn = fieldNames{2};
    end
    
    % If all we have is one column of data then
    % we assume that the user somehow knows that
    % everything is in the right order and will 
    % just write it in 
    if (size(fieldVals,2) == 1)
        
        disp(sprintf('\tWriting to column: %s',appendColumn));
        
        for i=1:length(S)
            j=mod(i-1,size(fieldVals,1))+1;
            expression = ['S(i).',appendColumn,' = fieldVals(j,2);'];
%             eval(expression);
        end
    
    % If we have more than one column then we 
    % assume that the first column contains a 
    % lookup value, and the second the data point
    else
        if (size(fieldVals,1) == length(S))

            fprintf('Size of data (fieldVals[%d,%d]) same as shape file (S[%d]), this is promising!\n',size(fieldVals,1),size(fieldVals,2),length(S));

            for i=1:size(fieldVals,1)
                expression = ['S(find([S.',lookupColumn,']==fieldVals(i,1))).',appendColumn,' = fieldVals(i,2);'];
%                 eval(expression);
            end

        elseif (size(fieldVals,1) < length(S))

            fprintf('Size of data (fieldVals[%d,%d]) less than shape file (S[%d]), this may not be what you want!\n',size(fieldVals,1),size(fieldVals,2),length(S));

            for i=1:size(fieldVals,1)
                expression = ['j=find([S.',lookupColumn,']==fieldVals(i,1));'];
                if (debugging == 1)
                    disp(expression);
                    disp(sprintf('Was looking in S.%s for %0.5d',lookupColumn,fieldVals(i,1)));
                end
                eval(expression);
                if isscalar(j)
                    expression = ['S(j).',appendColumn,' = fieldVals(i,2);'];
                    if (debugging == 1)
                        disp(expression);
                    end
                    disp(sprintf('Setting S(%d) [%d] to %0.5f',j,fieldVals(i,1),fieldVals(i,2)));
                    eval(expression);
                else
                    fprintf('Couldn''t find %d [fieldVals(%d)] in data\n',fieldVals(i,1),i);
                end
            end

        elseif (size(fieldVals,1) > length(S))

            fprintf('Size of data (fieldVals[%d,%d]) greater than shape file (S[%d]), this may not be what you want!\n',size(fieldVals,1),size(fieldVals,2),length(S));

            for i=1:size(fieldVals,1)
                expression = ['j=find([S.',lookupColumn,']==fieldVals(i,1));'];
%                 eval(expression);
                if isscalar(j)
                    expression = ['S(j).',appendColumn,' = fieldVals(i,2);'];
%                     eval(expression);
                else
                    fprintf('Couldn''t find %d [fieldVals(%d)] in data\n',fieldVals(i,1),i);
                end
            end

        else
            disp('No idea what''s happening if this branch executes');
        end
    end
    
    % Apparently, MATLAB doesn't like writing
    % out NULL values for a shape file field
    % which is set to numeric
    for i=1:length(S)
        expression = ['(S(i).',appendColumn,' > 0);'];
        if (~isscalar(eval(expression)))
            expression = ['S(i).',appendColumn,' = 0;'];
            eval(expression);
        end
    end
    
    for i=1:length(S)
        disp(S(i));
    end
    
    shapewrite(S,destFile,'DbfSpec',spec);
    
    fprintf('Writing shape file: %s\n',destFile);
    
    if debugging == 1
        shapeinfo(destFile)
    end
end