# DockerBackup

DockerBackup is an easy-to-use script for backing up your Docker containers on-demand, both locally and remotely using rsync. The script features the following:

- Customizable backup settings per container via an ini configuration file, making it easy to tailor your backups to your specific needs.
- Current image tag feature that identifies the current image version tag for the source container.
- Version file that includes image repository information, specified tag, and matches for version tags.
- Portainer stack config backup that contains docker-compose.yml and .env files, making it easy to restore your stack configuration in the event of a disaster.
- Remote backup using rsync protocol, making it a great option for disaster recovery and offsite backup.
- Restore script command to easily restore containers and stacks from backups.

Whether you're a developer or a system administrator, DockerBackup makes it easy to keep your Docker infrastructure running smoothly and your data protected.
