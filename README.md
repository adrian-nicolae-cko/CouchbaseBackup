# CouchbaseBackup

Custom Backup Wrapper for Couchbase

# Parameters

***-c  | --cluster***           
Mandatory          
Specifies the IP Address of the Cluster Node in which to perform the backup + port (e.g. http://192.168.0.10:8091)
  
***-bl | --backuplocation***  
Mandatory          
Specifies the location in which the backup should be written to. Creates a folder inside of this location with the  backup type + date (e.g. Full_20190901_2000)

***-sp | --sourcepath***         
Optional          
Specifies the location of the Couchbase BIN directory (e.g. Default - /opt/couchbase/bin)
  
***-bt | --backuptype***          
Mandatory          
Specifies the type of backup we will be running (e.g. full, diff accu)
  
***-u  | --username***         
Mandatory          
Specified the username to use when connecting to the specified cluster (e.g. backup-admin)
  
***-p  | --password***         
Mandatory          
Specifies the password to use when connecting to the specified cluster (should be using environment variable to stop passing plain text password)
  
***-P  | --parallelism***               
Optional          
Specifies the number of threads to use when running the backup. (e.g. 5)
  
***-br | --backupretention***           
Optional          
Specifies the number of days to keep backups for before purging them (e.g. 7)
  
# Usage Example
`opt/scripts/CouchbaseBackup.sh  --cluster         http://10.16.17.254:8091 
                                --backuplocation  /opt/couchbase-backup/Prod-Onboarding-CB 
                                --sourcepath      /opt/couchbase/bin 
                                --username        backup-admin 
                                --password        "***********" 
                                --backuptype      full 
                                --parallelism     5 
                                --backupretention 3`

# Output Example 

`2019-08-26 19:46:34 [INFO] [CouchbaseBackup.sh] [Prod-Onboarding-CB] [Backup]          [Full_20190826_1946] [Success] [0m8.653s]

2019-08-26 19:46:35 [INFO] [CouchbaseBackup.sh] [Prod-Onboarding-CB] [Integrity Check] [Full_20190826_1946] [Success] [0m8.653s]

2019-08-26 19:46:35 [INFO] [CouchbaseBackup.sh] [Prod-Onboarding-CB] Backup File Deleted - /opt/couchbase-backup/Prod-Onboarding-CB/Full_20190824_2000. Older than 0 days.

2019-08-26 19:46:35 [INFO] [CouchbaseBackup.sh] [Prod-Onboarding-CB] Backup File Deleted - /opt/couchbase-backup/Prod-Onboarding-CB/Full_20190825_2000. Older than 0 days.

2019-08-26 19:46:35 [INFO] [CouchbaseBackup.sh] [Prod-Onboarding-CB] Backup File Deleted - /opt/couchbase-backup/Prod-Onboarding-CB/Full_20190826_1945. Older than 0 days.

2019-08-26 19:46:35 [INFO] [CouchbaseBackup.sh] [Prod-Onboarding-CB] Backup File Deleted - /opt/couchbase-backup/Prod-Onboarding-CB/Full_20190826_1946. Older than 0 days.

2019-08-26 19:46:35 [INFO] [CouchbaseBackup.sh] [Prod-Onboarding-CB] [Backup Purge]    [Full_20190826_1946] [Success] [0m8.653s]`
