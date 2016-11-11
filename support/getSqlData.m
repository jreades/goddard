function data = getSqlData(connection,sql)
    e    = exec(connection,sql);
    e    = fetch(e);
    data = e.Data;
    clear e;
end