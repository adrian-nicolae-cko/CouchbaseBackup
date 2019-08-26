#i/bin/bash

set -e

# Importing util functions.
# Added in couchbase image build with packer (https://github.com/gruntwork-io/bash-commons).
# Packer build (https://github.com/CKOTech/checkout-devops-packer).
source "/opt/gruntwork/bash-commons/log.sh"
source "/opt/gruntwork/bash-commons/string.sh"
source "/opt/gruntwork/bash-commons/assert.sh"

#################################
#     Main Code Block           #
#################################
function main
{
  POSITIONAL=()
  while [[ $# -gt 0 ]]
  do
    key="$1"

    # Argument Specification for Script
    case $key in
        -c|--cluster)
        local readonly clusternode="$2"
        shift
        shift
        ;;
        -cn|--clustername)
        local readonly clustername="$2"
        shift
        shift
        ;;
        -bl|--backuplocation)
        local readonly backuplocation="$2"
        shift
        shift
        ;;
        -sp|--sourcepath)
        local readonly sourcepath="$2"
        shift
        shift
        ;;
        -bt|--backuptype)
        local readonly backuptype="$2"
        shift
        shift
        ;;
        -u|--username)
        local readonly username="$2"
        shift
        shift
        ;;
        -p|--password)
        local readonly password="$2"
        shift
        shift
        ;;
        -P|--parallelism)
        local readonly parallelism="$2"
        shift
        shift
        ;;
        -br|--backupretention)
        local readonly backupretention="$2"
        shift
        shift
        ;;
        --default) DEFAULT=YES
        shift
        ;;
        *) POSITIONAL+=("$1")
        shift
        ;;
    esac
  done

  ParamExitCode=0

  if [ -z $clusternode ]
  then
    echo "Parameter Required: --cluster (-c)"
    ParamExitCode=1
  fi

  if [ -z $backuplocation ]
  then
    echo "Parameter Required: --backuplocation (-bl)"
    ParamExitCode=1
  fi

  if [ -z $backuptype ]
  then
    echo "Parameter Required: --backuptype (-bt)"
    ParamExitCode=1
  fi

  if [ -z $username ]
  then
    echo "Parameter Required: --username (-u)"
    ParamExitCode=1
  fi

  if [ -z $password ]
  then
    echo "Parameter Required: --password (-p)"
    ParamExitCode=1
  fi

  # Check if all required parameters were provided; if not, exit
  if [ $ParamExitCode == 1 ]
  then
    exit 1
  fi

  #echo "Cluster - $clusternode"
  #echo "BackupLocation - $backuplocation"
  #echo "BackupType - $backuptype"
  #echo "Username - $username"
  #echo "Password - $password"
  #echo "SourcePath - $sourcepath"
  #echo "Parallelism - $parallelism"
  #echo "Backup Rentention (Days) - $backupretention"


  ######################################################################################
  #  Parameter Validation Complete. Main Script Now...
  #######################################################################################

  local readonly backupsetname="Full_$(date +\%Y%m%d_%H%M)"
  local readonly backuplocation="$backuplocation/$backupsetname"
  local readonly clustername="$(basename "$(dirname $backuplocation)")"

  BackupCommand="/opt/couchbase/bin/cbbackupwrapper $clusternode $backuplocation --path=$sourcepath -u $username -p '$password' -m $backuptype -P $parallelism"

  local readonly command_name="CBBackupWrapper"
  local readonly command_path="$BackupCommand"
  local readonly mail_to="ryan.gillooly@checkout.com"
  local readonly subject="Prod-Onboarding-CB"
  local readonly box_ip=$(ip r s | awk '$0 ~ /link src/ {print $9}')
  local readonly log_path="/root/errwrap/$command_name.txt"

  assert_is_installed mail
  assert_is_installed $command_path

  ##########################################################################################
  #  Get command output + the time the command took. Then delete the temp Backup.Time file #
  ##########################################################################################

  command_output=$(time (eval $BackupCommand) 2> backup.time)
  cmdruntime_full=$(awk 'NR==2' backup.time)
  cmdruntime=$(echo "${cmdruntime_full/real/}" | xargs)
  currentdatetime=$(date +"%Y-%m-%d %H:%M:%S")

  ##########################################################################################
  #   Run through IF statement and make sure backup completed successfully
  ##########################################################################################

  if [[ $command_output = *"SUCCESSFULLY COMPLETED!"* && $command_output != *"Error"* ]]; then

       # Write Success line into the log file
       echo "[$currentdatetime] [$clustername] [Backup]          [$backupsetname] [Success] [$cmdruntime]"  >> /root/errwrap/$command_name.txt

       # Output Success to console window
       log_info "[$clustername] [Backup]          [$backupsetname] [Success] [$cmdruntime]"

       ##########################################################################################
       #  Since backup completed successfully, now run the integrity check + clear old backups  #
       ##########################################################################################

       # Run IntegrityCheck and output errs to temp file
       IntegrityCheck $backuplocation 2> IntegCheck.Results
       IntCheckErrCount="$(cat IntegCheck.Results | wc -l)"
       IntCheckErrors="$(cat IntegCheck.Results)"

       # If an error has been caught, log error
       if [ $IntCheckErrCount -gt 0 ];
       then
           echo "[$currentdatetime] [$clustername] [Integrity Check] [$backupsetname] [Failure] [$cmdruntime] [Errors($IntCheckErrCount) - $IntCheckErrors]" >> /root/errwrap/$command_name.txt
           log_error "[$clustername] [Integrity Check] [$backupsetname] [Failure] [$cmdruntime]"
           log_error "[$clustername] [Backup Purge]    [$backupsetname] [Aborted] [$cmdruntime]"
       else
           echo "[$currentdatetime] [$clustername] [Integrity Check] [$backupsetname] [Success] [$cmdruntime]"  >> /root/errwrap/$command_name.txt
           log_info "[$clustername] [Integrity Check] [$backupsetname] [Success] [$cmdruntime]"

           if [ -z "$backupretention" ];
           then
              echo "Don't Purge Backups"
           else
             # echo "Purge backups after $keepbackupsfor days"
              PurgeBackups "$(dirname $backuplocation)" $backupretention
           fi

           log_info "[$clustername] [Backup Purge]    [$backupsetname] [Success] [$cmdruntime]"
       fi;
       ##########################################################################################

      # Send email confirming successful backup (temporary)
      echo "The Couchbase backup of the Prod-Onboarding-CB cluster completed successfully" | mail -s $subject $mail_to
  else
      # Output Failure to the console window
      log_error "[$clustername] [Backup]         [$backupsetname] [Failure] [$cmdruntime]  -  Please review the logs"

      # Write Failure line into the log file, along with failure output
      echo "[$currentdatetime] [$clustername] [Backup]          [$backupsetname] [Failure] [$cmdruntime]  [ERROR - $command_output]" >> /root/errwrap/$command_name.txt

      # Send email advising of the backup failure
      echo "Command $command_name failed on host $box_ip. Location of the logs: $box_ip:/root/errwrap/$command_name.txt" | mail -s $subject $mail_to
  fi

  ### Cleanup ###
  rm -r backup.time
  rm -r IntegCheck.Results
}

function IntegrityCheck
{
   for bucket in $(find $1 -type d -name 'bucket-*');
   do
      BUCKET_CHECK="$(find ${bucket} -name '*.cbb' -exec sqlite3 {} 'PRAGMA integrity_check' \;)"
   done
}

function PurgeBackups
{
  # The find Statement is not working into a variable
  for file in $(find $1 -type d -name "*_*_*" -not -newermt "$(date "+%Y-%m-%d %H:%M:%S" -d "$2 days ago")")
  do
    log_info "[$clustername] Backup File Deleted - $file. Older than $2 days."
    # rm -r $file
    # Write Failure line into the log file, along with failure output
    echo "[$currentdatetime] [$clustername] Backup File Deleted - $file. Older than $2 days." >> /root/errwrap/$command_name.txt
  done
}

main $@
