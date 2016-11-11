function output = createCsvContent(rows, data)
    
    header = cell(1,size(data,2)+1);
    
    header{1} = 'TAZ';
    for i=2:length(header)
        header{i} = ['Region',num2str(i-1)];
    end
    
    %header
    
    output = cell(length(rows)+1, length(header));
    
    for i=1:length(header)
        output{1,i} = header{i};
    end
    
    %fprintf('Size of output is: %d x %d\n',size(output,1),size(output,2));
    
    cdata = num2cell(data);
    
    for i=1:length(rows)
        %fprintf('Reading from row %d, writing to row %d\n',i,i+1);
        for j=1:length(header)
            %fprintf('\tReading column %d\n',j);
            if j==1
                output{i+1,j} = rows{i};
            else
                output{i+1,j} = cdata{i,j-1};
            end
        end
    end
    
end