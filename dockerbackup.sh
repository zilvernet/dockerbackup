#!/bin/bash

if [ -z "$1" ]; then
  echo "Error: parameter is missing"
  exit 1
fi

#Set the application name
APP_NAME="$1"

###### Read INI ##########################
echo -e "\n- Loading Parameters from ini file\n"

INI="dockerbackup.ini"

# Read the backup directory from the INI file

BACKUP_DIR=$(sed -nr "/^\[$APP_NAME\]/ { :l /^BACKUP_DIR[ ]*=/ { s/[^=]*=[ ]*//; p; q;}; n; b l;}" ./$INI)
BACKUP_DESTINATION=$(sed -nr "/^\[global\]/ { :l /^BACKUP_DESTINATION[ ]*=/ { s/[^=]*=[ ]*//; p; q;}; n; b l;}" ./$INI)
BACKUP_DESTINATION_LOCATION=$BACKUP_DESTINATION$APP_NAME
DOCKER_NAME=$(sed -nr "/^\[$APP_NAME\]/ { :l /^DOCKER_NAME[ ]*=/ { s/[^=]*=[ ]*//; p; q;}; n; b l;}" ./$INI)
DOCKER_NAME1=$(sed -nr "/^\[$APP_NAME\]/ { :l /^DOCKER_NAME1[ ]*=/ { s/[^=]*=[ ]*//; p; q;}; n; b l;}" ./$INI)
DOCKER_NAME2=$(sed -nr "/^\[$APP_NAME\]/ { :l /^DOCKER_NAME2[ ]*=/ { s/[^=]*=[ ]*//; p; q;}; n; b l;}" ./$INI)
DOCKER_NAME3=$(sed -nr "/^\[$APP_NAME\]/ { :l /^DOCKER_NAME3[ ]*=/ { s/[^=]*=[ ]*//; p; q;}; n; b l;}" ./$INI)
DOCKER_NAME4=$(sed -nr "/^\[$APP_NAME\]/ { :l /^DOCKER_NAME4[ ]*=/ { s/[^=]*=[ ]*//; p; q;}; n; b l;}" ./$INI)
PORTAINER_STACK=$(sed -nr "/^\[$APP_NAME\]/ { :l /^PORTAINER_STACK[ ]*=/ { s/[^=]*=[ ]*//; p; q;}; n; b l;}" ./$INI)
RSYNC_DESTINATION=$(sed -nr "/^\[global\]/ { :l /^RSYNC_DESTINATION[ ]*=/ { s/[^=]*=[ ]*//; p; q;}; n; b l;}" ./$INI)
RSYNC_PATH=$(sed -nr "/^\[global\]/ { :l /^RSYNC_PATH[ ]*=/ { s/[^=]*=[ ]*//; p; q;}; n; b l;}" ./$INI)

# Check if the variable BACKUP_DIR was found
if [ -z "$BACKUP_DIR" ]; then
  echo "Error: backup directory not found for app $APP_NAME"
  exit 1
fi
echo "BACKUP_DIR=$BACKUP_DIR"

# Check if the variable BACKUP_DESTINATION_LOCATION was found
if [ -z "$BACKUP_DESTINATION_LOCATION" ]; then
  echo "Error: backup directory not found for app $APP_NAME"
  exit 1
fi
echo "BACKUP_DESTINATION_LOCATION=$BACKUP_DESTINATION_LOCATION"

# Check if the variable DOCKER_NAME was found
if [ -z "$DOCKER_NAME" ]; then
  echo "Error: backup directory not found for app $APP_NAME"
  exit 1
fi
echo "DOCKER_NAME=$DOCKER_NAME"
echo "DOCKER_NAME1=$DOCKER_NAME1"
echo "DOCKER_NAME2=$DOCKER_NAME2"
echo "DOCKER_NAME3=$DOCKER_NAME3"
echo "DOCKER_NAME4=$DOCKER_NAME4"

# Check if the variable PORTAINER_STACK was found
if [ -z "$PORTAINER_STACK" ]; then
  echo "Error: backup directory not found for app $APP_NAME"
  exit 1
fi
echo "PORTAINER_STACK=$PORTAINER_STACK"

# Check if the variable PORTAINER_STACK was found
if [ -z "$RSYNC_DESTINATION" ]; then
  echo "Error: backup directory not found for app $APP_NAME"
  exit 1
fi
echo "RSYNC_DESTINATION=$RSYNC_DESTINATION"

# Check if the variable PORTAINER_STACK was found
if [ -z "$RSYNC_PATH" ]; then
  echo "Error: backup directory not found for app $APP_NAME"
  exit 1
fi
echo "RSYNC_PATH=$RSYNC_PATH"

# Date File for resuming job
RESUME_DATE="resume-"$APP_NAME"-date.txt"
RESUME_STEP="resume-"$APP_NAME"-step.txt"

# Get the current date
DATE_START=$(date +"%Y-%m-%d-%H-%M-%S")
echo DATE_START=$DATE_START
echo $DATE_START > $RESUME_DATE

rsynctest-module () {
  #######################################################
  # Step1.1: Check if Rsync destination path is writable
  STEP=1.1
  echo $STEP > $RESUME_STEP

  testdestination=$RSYNC_DESTINATION:$RSYNC_PATH/$HOSTNAME
  echo -e "\n- STEP "$STEP": Checking rsync destination:"$testdestination"\n"

  # Define the file and destination
  testfile="testfile.txt"
  touch -d tomorrow $testfile
  testdestination=$RSYNC_DESTINATION:$RSYNC_PATH/$HOSTNAME"/testfile.txt"
  #echo "testfile="$testfile
  #echo "testdestination="$testdestination

  # Use rsync with the --dry-run option to check if the destination is writable
  rsync_result=$(rsync --dry-run -e ssh $testfile $testdestination)

  # Check the exit code of the rsync command
  if [ $? -ne 0 ]; then
    # If the exit code is non-zero, display an error message indicating that the destination is not writable
    echo -e "\nError: The destination is not writable."
    rm $testfile
    exit 1
  else
    # If the exit code is zero, display a message indicating that the destination is writable
    echo "The destination is writable."
    # Perform the actual file transfer
    #rsync -e ssh $testfile $destination
    #rsync -avzh -rptgo --progress -e ssh $testfile $destination
    rm $testfile
  fi
  #read -p "Press any key to resume..."
}

tagfindtest-module () {

  #######################################################
  # Step1.2: Check if Rsync destination path is writable
  STEP=1.2
  echo $STEP > $RESUME_STEP

  IMAGEFIND_FILE=docker_image_find_tag.sh 
  IMAGEFIND_URL=https://raw.githubusercontent.com/ryandaniels/docker-script-find-latest-image-tag/master/docker_image_find_tag.sh

  echo -e "\n- STEP "$STEP": Checking if Script exists:"$IMAGEFIND_FILE"\n"

  if [ ! -f "docker_image_find_tag.sh" ]; then
    echo "Script: $IMAGEFIND_FILE not found. Downloading from GitHub..."
    curl -o $IMAGEFIND_FILE $IMAGEFIND_URL
    sudo chmod +x $IMAGEFIND_FILE
  fi

}

localfolder-module () {

  #######################################################
  # Step2: Create folder for backup destination location Local
  STEP=2
  echo $STEP > $RESUME_STEP
  echo -e "\n- STEP "$STEP": Checking local storage folder\n"
  folder_name=$BACKUP_DESTINATION_LOCATION

  if [ ! -d "$folder_name" ]; then
    sudo mkdir "$folder_name"
    echo "Folder $folder_name created."
  else
    echo "Folder $folder_name already exists."
  fi

  if [ $(stat -c %a "$folder_name") != "1777" ]; then
     echo "Adding folder: "$folder_name" write permissions"
    sudo chmod -R 1777 "$folder_name"
  else
    echo "Folder permission: "$folder_name" already exists"	
  fi

  #NOTE: In the future exit with permission errors
  #read -p "Press any key to resume..."
}

container-info () {

  CONTAINER_NAME=$1
  INFO_FILE=$2
  JSON_FILE="filejson-"$CONTAINER_NAME".txt"
  TAG_FILE="filetag-"$CONTAINER_NAME".txt"


  if [ -e $INFO_FILE ]; then
    rm $INFO_FILE
    echo "File: "$INFO_FILE" removed successfully"
  fi


  if [ -e $TAG_FILE ]; then
    rm $TAG_FILE
    echo "File: "$TAG_FILE" removed successfully"
  fi

  if [ -e $JSON_FILE ]; then
    rm $JSON_FILE
    echo "File: "$JSON_FILE" removed successfully"
  fi


  #read -p "Press any key to resume [container-info]..."

  IMAGE_REPO=$(docker inspect --format='{{.Config.Image}}' $CONTAINER_NAME | awk -F":" '{print $1}')
  echo IMAGE_REPO=$IMAGE_REPO

  string=$IMAGE_REPO
  # Use the grep command to check if the string has more than 2 '/'
  if echo $string | grep -o '/' | wc -l | grep -q '2'; then
    # Use the cut command to extract the last two values
    # using the '/' as the delimiter
    IMAGE_REPO=$(echo $string | cut -d'/' -f2,3)
    #echo $IMAGE_REPO
  fi

  IMAGE_VER=$(docker inspect --format='{{.Config.Image}}' $CONTAINER_NAME |awk -F":" '{print $2}')
  echo IMAGE_VER=$IMAGE_VER

  IMAGE_ID=$(docker inspect --format='{{.Image}}' $CONTAINER_NAME)
  echo IMAGE_ID=$IMAGE_ID

  docker image inspect --format '{{json .}}' "$IMAGE_ID" | jq -r '. | {Id: .Id, Digest: .Digest, RepoDigests: .RepoDigests, Labels: .Config.Labels}' > $JSON_FILE

  IMAGE_DIGEST=$(awk -F"$IMAGE_REPO@" '{print $2}' $JSON_FILE | tr -d '\n' | tr -d '"')
  echo IMAGE_DIGEST=$IMAGE_DIGEST

  IMAGE_META_VER=$(awk -F"org.opencontainers.image.version" '{print $2}' $JSON_FILE | tr -d '\n' | tr -d '"' | tr -d " " | tr -d ":")
  echo IMAGE_MET_VER=$IMAGE_META_VER

  #read -p "Press any key to resume..."

  #echo ./docker_image_find_tag.sh -n $IMAGE_REPO -L $IMAGE_DIGEST -v
  echo ./docker_image_find_tag.sh -n $IMAGE_REPO -i $IMAGE_ID -v
  ./docker_image_find_tag.sh -n $IMAGE_REPO -i $IMAGE_ID -v  > $TAG_FILE

  #grep -oP '(?<=Found match. tag:)[^latest]*' findtag.txt | tr -d '\n'

  IMAGE_DH_VER=$(awk -F"Found match. tag: " '{print $2}' $TAG_FILE) 
  #| awk -F"linux-amd64" '{print $2}' | tr -d "\n" | tr -d "-")
  echo IMAGE_DH_VER=$IMAGE_DH_VER

  ########### BEST MATCH ############

  IMAGE_DH_VER=`echo $IMAGE_DH_VER | tr ' ' '|'`

  #echo IMAGE_DH_VER=$IMAGE_DH_VER

  # Split IMAGE_DH_VER into an array using "|" as a separator
  IFS='|' read -ra IMAGE_VERSIONS <<< "$IMAGE_DH_VER"

  # Initialize variables for best image version
  best_version=""
  best_version_has_numbers=false

  # Iterate through array of image versions
  for version in "${IMAGE_VERSIONS[@]}"; do
    # Check if version has numbers
    if [[ $version =~ [0-9] ]]; then
        if [[ $version != *"latest"* ]]; then
            best_version=$version
            best_version_has_numbers=true
            break
        fi
    fi
  done

  # If no image version with numbers found, iterate through array again
  if ! $best_version_has_numbers; then
    for version in "${IMAGE_VERSIONS[@]}"; do
        # Eliminate versions with "latest" keyword
        if [[ $version != *"latest"* ]]; then
            best_version=$version
            break
        fi
    done
  fi
  IMAGE_DH_VER_BEST=$best_version
  echo IMAGE_DH_VER_BEST=$IMAGE_DH_VER_BEST

  ### Exporting variables to the other script is not working

  #export IMAGE_REPO=$IMAGE_REPO
  #export IMAGE_VER=$IMAGE_VER
  #export IMAGE_ID=$IMAGE_ID
  #export IMAGE_DIGEST=$IMAGE_DIGEST
  #export IMAGE_MET_VER=$IMAGE_META_VER
  #export IMAGE_DH_VER=$IMAGE_DH_VER
  #export IMAGE_DH_VER_BEST=$IMAGE_DH_VER_BEST

  echo -e "IMAGE_REPO="$IMAGE_REPO"\nIMAGE_VER="$IMAGE_VER"\nIMAGE_ID="$IMAGE_ID$"\nIMAGE_DIGEST="$IMAGE_DIGEST"\nIMAGE_MET_VER="$IMAGE_META_VER"\nIMAGE_DH_VER="$IMAGE_DH_VER"\nIMAGE_DH_VER_BEST="$IMAGE_DH_VER_BEST > $INFO_FILE

  if [ -e $JSON_FILE ]; then
    rm $JSON_FILE
    echo "File: "$JSON_FILE" removed successfully"
  fi

  if [ -e $TAG_FILE ]; then
    rm $TAG_FILE
    echo "File: "$TAG_FILE" removed successfully"
  fi
}

tar-module () {

  CONTAINER_INFO_FILE="container-info-"$APP_NAME".txt"

  ############### SCRIPT START ##########################
  STEP=4.1
  echo -e "\n- STEP "$STEP": Generating Module Variables\n"
  echo $STEP > $RESUME_STEP

  # Create the backup file name with the date as a separator
  BACKUP_FILE=$APP_NAME"-backup-"$DATE_START"-data.tar.gz"
  echo BACKUP_FILE
  # Create the backup portainer stack file name with the date as a separator
  BACKUP_STACK=$APP_NAME"-backup-"$DATE_START"-portainerstack.tar.gz"
  echo BACKUP_STACK
  # Create the backup restore file name with the date as a separator
  BACKUP_RESTORE_FILE=$APP_NAME"-backup-"$DATE_START"-restore.sh"
  echo BACKUP_RESTORE_FILE
  # Declare the backup version file with the date as a separator
  BACKUP_VERSION=$APP_NAME"-backup-"$DATE_START".version"
  echo BACKUP_VERSION

  #######################################################
  # Step4.2 - Gather Docker IMAGE VERSION (requires docker_image_find_tag.sh)
  # Get Docker Image Version and Repo Hash
  STEP=4.2
  echo -e "\n- STEP "$STEP": Getting docker: "$DOCKER_NAME" image version information\n"
  echo $STEP > $RESUME_STEP
  ## If script doesn't exists install
  #./container-info.sh $DOCKER_NAME $CONTAINER_INFO_FILE
  container-info $DOCKER_NAME $CONTAINER_INFO_FILE

  #read -p "Press any key to resume..."

  # Write Backup Version
  STEP=4.3
  echo -e "\n- STEP "$STEP": Create version file file: "$BACKUP_VERSION" with version: "$IMAGE_VERSION"\n"
  echo $STEP > $RESUME_STEP

  mv $CONTAINER_INFO_FILE $BACKUP_DESTINATION_LOCATION/$BACKUP_VERSION

  #read -p "Press any key to resume..."

  #######################################################
  # Step4.4 - Backup to local folder
  # Use tar to create the backup archive
  STEP=4.4
  echo -e "\n- STEP "$STEP": tar data folder: "$BACKUP_DESTINATION_LOCATION/$BACKUP_FILE"\n"
  echo $STEP > $RESUME_STEP

  sudo tar -czvf $BACKUP_DESTINATION_LOCATION/$BACKUP_FILE $BACKUP_DIR

  #read -p "Press any key to resume..."

  STEP=4.5
  echo -e "\n- STEP "$STEP": tar portainerstack folder: "$BACKUP_DESTINATION_LOCATION/$BACKUP_FILE"\n"
  echo $STEP > $RESUME_STEP

  sudo tar -czvf $BACKUP_DESTINATION_LOCATION/$BACKUP_STACK $PORTAINER_STACK

  #read -p "Press any key to resume..."

  #######################################################
  # Step 4.6 - Create Restore Script to local folder
  # Use tar to create the backup restore command
  STEP=4.6
  echo -e "\n- STEP "$STEP": Create backup restore command file: "$BACKUP_RESTORE_FILE
  echo $STEP > $RESUME_STEP

  echo -e "#!/bin/bash\ntar -zxvf $BACKUP_FILE -C /" > $BACKUP_DESTINATION_LOCATION/$BACKUP_RESTORE_FILE

  #read -p "Press any key to resume..."

  STEP=4.7
  echo -e "\n- STEP "$STEP": Add executable permissions to file: "$BACKUP_RESTORE_FILE"\n"
  echo $STEP > $RESUME_STEP

  sudo chmod +x $BACKUP_DESTINATION_LOCATION/$BACKUP_RESTORE_FILE

  #read -p "Press any key to resume..."

}

rsync-module () {

  CONTAINER_INFO_FILE="container-info-"$APP_NAME".txt"

  ############### SCRIPT START ##########################
  STEP=6.1
  echo -e "\n- STEP "$STEP": Generating Module Variables\n"
  echo $STEP > $RESUME_STEP

  # Create the backup file name with the date as a separator
  BACKUP_FILE=$APP_NAME"-backup-"$DATE_START"-data.tar.gz"

  # Create the backup portainer stack file name with the date as a separator
  BACKUP_STACK=$APP_NAME"-backup-"$DATE_START"-portainerstack.tar.gz"

  # Create the backup restore file name with the date as a separator
  BACKUP_RESTORE_FILE=$APP_NAME"-backup-"$DATE_START"-restore.sh"

  # Declare the backup version file with the date as a separator
  BACKUP_VERSION=$APP_NAME"-backup-"$DATE_START".version"

  #######################################################
  # Step6.0 - Rsync backup to another location
  STEP=6.0
  echo -e "\n- STEP "$STEP": Rsync to "$RSYNC_DESTINATION
  echo $STEP > $RESUME_STEP

  STEP=6.1
  echo -e "\n- STEP "$STEP": Starting Rsync data file: "$BACKUP_DESTINATION_LOCATION/$BACKUP_FILE"\n"
  echo $STEP > $RESUME_STEP

  rsync -avzh -rptgo --progress -e ssh $BACKUP_DESTINATION_LOCATION/$BACKUP_FILE $RSYNC_DESTINATION:$RSYNC_PATH/$HOSTNAME/$BACKUP_FILE

  #read -p "Press any key to resume..."

  STEP=6.2
  echo -e "\n- STEP "$STEP": Starting Rsync stack file: "$BACKUP_DESTINATION_LOCATION/$BACKUP_STACK"\n"
  echo $STEP > $RESUME_STEP

  rsync -avzh -rptgo --progress -e ssh $BACKUP_DESTINATION_LOCATION/$BACKUP_STACK $RSYNC_DESTINATION:$RSYNC_PATH/$HOSTNAME/$BACKUP_STACK

  #read -p "Press any key to resume..."

  STEP=6.3
  echo -e "\n- Rsync backup restore command file: "$BACKUP_RESTORE_FILE"\n"
  echo $STEP > $RESUME_STEP

  rsync -avzh -rptgo --progress -e ssh $BACKUP_DESTINATION_LOCATION/$BACKUP_RESTORE_FILE $RSYNC_DESTINATION:$RSYNC_PATH/$HOSTNAME/$BACKUP_RESTORE_FILE

  #read -p "Press any key to resume..."

  STEP=6.4
  echo -e "\n- Rsync backup version file: "$BACKUP_VERSION"\n"
  echo $STEP > $RESUME_STEP

  rsync -avzh -rptgo --progress -e ssh $BACKUP_DESTINATION_LOCATION/$BACKUP_VERSION $RSYNC_DESTINATION:$RSYNC_PATH/$HOSTNAME/$BACKUP_VERSION

  #read -p "Press any key to resume..."

  #NOTE Missing Error Module
  #NOTE Missing SKIP Resume Module
}

cleanup-module() {

  CONTAINER_INFO_FILE="container-info-"$APP_NAME".txt"

  ############### SCRIPT START ##########################
  STEP=7.1
  echo -e "\n- STEP "$STEP": Delete Resume Files\n"
  echo $STEP > $RESUME_STEP
  rm $RESUME_DATE
  rm $RESUME_STEP

  #read -p "Press any key to resume..."

}

#######################################################
# Step1.1: Check if Rsync destination path is writable
#./dockerbackup-rsynctest-module.sh $DATE_START $APP_NAME $BACKUP_DIR $BACKUP_DESTINATION_LOCATION $DOCKER_NAME $PORTAINER_STACK $RSYNC_DESTINATION $RSYNC_PATH $RESUME_DATE $RESUME_STEP
rsynctest-module

if [ $? -ne 0 ]; then
    read -p "Error: Press any key to exit the script..."
    exit 1
fi

#read -p "Press any key to resume..."

#######################################################
# Step1.2: Check if Script docker_image_find_tag.sh exists
#./dockerbackup-rsynctest-module.sh $DATE_START $APP_NAME $BACKUP_DIR $BACKUP_DESTINATION_LOCATION $DOCKER_NAME $PORTAINER_STACK $RSYNC_DESTINATION $RSYNC_PATH $RESUME_DATE $RESUME_STEP
tagfindtest-module

if [ $? -ne 0 ]; then
    read -p "Error: Press any key to exit the script..."
    exit 1
fi

#read -p "Press any key to resume..."



#######################################################
# Step2: Create folder for backup destination location Local
#./dockerbackup-localfolder-module.sh $DATE_START $APP_NAME $BACKUP_DIR $BACKUP_DESTINATION_LOCATION $DOCKER_NAME $PORTAINER_STACK $RSYNC_DESTINATION $RSYNC_PATH $RESUME_DATE $RESUME_STEP
localfolder-module
if [ $? -ne 0 ]; then
    read -p "Error: Press any key to exit the script..."
    exit 1
fi

#read -p "Press any key to resume..."

#######################################################
# Step3: Stoping docker container
STEP=3
echo -e "\n- STEP "$STEP": Stoping Docker Containers\n"
echo $STEP > $RESUME_STEP

if [ -n "$DOCKER_NAME1" ]; then
  docker stop "$DOCKER_NAME1"
fi
if [ -n "$DOCKER_NAME2" ]; then
  docker stop "$DOCKER_NAME2"
fi
if [ -n "$DOCKER_NAME3" ]; then
  docker stop "$DOCKER_NAME3"
fi
if [ -n "$DOCKER_NAME4" ]; then
  docker stop "$DOCKER_NAME4"
fi
docker stop $DOCKER_NAME

#read -p "Press any key to resume..."

#######################################################
# Step4: Run backup tar module
#./dockerbackup-tar-module.sh $DATE_START $APP_NAME $BACKUP_DIR $BACKUP_DESTINATION_LOCATION $DOCKER_NAME $PORTAINER_STACK $RSYNC_DESTINATION $RSYNC_PATH $RESUME_DATE $RESUME_STEP
tar-module
if [ $? -ne 0 ]; then
    read -p "Error: Press any key to exit the script..."
    exit 1
fi

#read -p "Press any key to resume..."

#######################################################
# Step5: Start the docker container
STEP=5
echo -e "\n- STEP "$STEP": Starting Docker Containers\n"
echo $STEP > $RESUME_STEP

if [ -n "$DOCKER_NAME1" ]; then
  docker start "$DOCKER_NAME1"
fi
if [ -n "$DOCKER_NAME2" ]; then
  docker start "$DOCKER_NAME2"
fi
if [ -n "$DOCKER_NAME3" ]; then
  docker start "$DOCKER_NAME3"
fi
if [ -n "$DOCKER_NAME4" ]; then
  docker start "$DOCKER_NAME4"
fi

docker start $DOCKER_NAME

#######################################################
# Step6: Run backup rsync module
#./dockerbackup-rsync-module.sh $DATE_START $APP_NAME $BACKUP_DIR $BACKUP_DESTINATION_LOCATION $DOCKER_NAME $PORTAINER_STACK $RSYNC_DESTINATION $RSYNC_PATH $RESUME_DATE $RESUME_STEP
rsync-module
if [ $? -ne 0 ]; then
    read -p "Error: Press any key to exit the script..."
    exit 1
fi

#read -p "Press any key to resume..."

#######################################################
# Step7: backup complete cleanup module
#./dockerbackup-cleanup-module.sh $DATE_START $APP_NAME $BACKUP_DIR $BACKUP_DESTINATION_LOCATION $DOCKER_NAME $PORTAINER_STACK $RSYNC_DESTINATION $RSYNC_PATH $RESUME_DATE $RESUME_STEP
cleanup-module
if [ $? -ne 0 ]; then
    read -p "Error: Press any key to exit the script..."
    exit 1
fi

#read -p "Press any key to resume..."
