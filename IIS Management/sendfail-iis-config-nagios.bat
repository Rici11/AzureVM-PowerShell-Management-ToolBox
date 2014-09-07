set NSCA_HOME="C:\Program Files\NSClient++"
set NSCA_BIN=%NSCA_HOME%\send_nsca.exe
set NSCA_CFG=%NSCA_HOME%\send_nsca.cfg
set NSCA_SERVER="nagios.example.com"

echo host.example.com;iis_backup;2;IIS Configuration Backup has exploded | %NSCA_BIN% -H %NSCA_SERVER% -p 5667 -to 10 -c %NSCA_CFG% -d ;
