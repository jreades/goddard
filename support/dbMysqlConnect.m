function [connection] = dbMysqlConnect(dbname,user,password,varargin)
    % Connect to a specified MySQL database using the 
    % database name, username, and password. Optional
    % arguments include the server name and the port.
    
    dsn  = 'jdbc:mysql://';
    host = 'localhost';
    port = '';
    
    if (length(varargin) > 0) 
       for (i=1:length(varargin))
           if (regexpi(varargin{i},'(?:\w+\.){2,4}\w{2,4}')) 
               host = varargin{i};
           end
           if (regexpi(varargin{i},'^\d{3,6}+$'))
               port = varargin{i};
           end
       end
    end
    
    if (~ strcmp(port,''))
        dsn = [dsn,host,':',port];
    end
    
    dsn = [dsn,'/',dbname];
    
    disp(sprintf('DSN: %s',dsn));
    
    connection = database(dbname,user,password,'com.mysql.jdbc.Driver',dsn);
end
