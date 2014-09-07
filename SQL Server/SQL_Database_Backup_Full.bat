set NSCA_HOME="C:\Program Files\NSClient++"
set NSCA_BIN=%NSCA_HOME%\send_nsca.exe
set NSCA_CFG=%NSCA_HOME%\send_nsca.cfg
set NSCA_SERVER="nagios.example.com"
sqlcmd -S . -E -Q "EXEC sp_BackupDatabases @backupLocation='F:\SQLBackups\', @backupType='F'" && echo host.example.com;sql_full_backup;0;MS SQL Full Backup completed| %NSCA_BIN% -H %NSCA_SERVER% -p 5667 -to 10 -c %NSCA_CFG% -d ;
