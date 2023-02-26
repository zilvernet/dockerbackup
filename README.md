# DockerBackup

DockerBackup is an easy-to-use script for backing up your Docker containers on-demand, both locally and remotely using rsync. The script features the following:

- **INI configuration file** - Customizable backup settings per container via an ini configuration file, making it easy to tailor your backups to your specific needs.
- **Find Current image tag** - Identifies the current image version tag for the source container.
- **Version file** - It includes image repository information, specified tag, and matches for version tags.
- **Portainer stack config** - It backs up container docker-compose.yml and .env files, making it easy to restore your stack configuration in the event of a disaster.
- **Send to a Remote Location** - It uses rsync protocol, making it a great option for disaster recovery and offsite backup.
- **Restore script** - It provides a shell script command per image backup to easily restore containers and stacks from backups.
## Requirements:
Before using DockerBackup, please make sure you have done the following:

- Add all your container sources for the backup to the dockerbackup.ini file and filled in all the necessary parameters.
- Installed the external script called docker-script-find-latest-image-tag. This script will be downloaded automatically and placed in the appropriate directory.

To find more information about this script, you can check it out on GitHub:
https://github.com/ryandaniels/docker-script-find-latest-image-tag/blob/master/docker_image_find_tag.sh

## Usage:
```
./dockerbackup.sh containername
```

Whether you're a developer or a system administrator, DockerBackup makes it easy to keep your Docker infrastructure running smoothly and your data protected.
