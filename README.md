# mysql-backup
Back up mysql databases to... anywhere!

## Overview
mysql-backup is a simple way to do MySQL database backups when the database is running in a container.

It has the following features:

* dump to S3 and Google Cloud Storage
* select database user and password
* connect to any container running on the same system

Please see [CONTRIBUTORS.md](./CONTRIBUTORS.md) for a list of contributors.

## Backup
To run a backup, launch `mysql-backup` image as a container with the correct parameters. Everything is controlled by environment variables passed to the container.

For example:

````bash
docker run -d --restart=always -e DB_DUMP_FREQ=60 -e DB_DUMP_BEGIN=2330 -e DB_DUMP_TARGET=/db -e DB_SERVER=my-db-container -v /local/file/path:/db databack/mysql-backup
````

The above will run a dump every 60 minutes, beginning at the next 2330 local time, from the database accessible in the container `my-db-container`.

The following are the environment variables for a backup:

__You should consider the [use of `--env-file=`](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables-e-env-env-file), [docker secrets](https://docs.docker.com/engine/swarm/secrets/) to keep your secrets out of your shell history__

* `DB_SERVER`: hostname to connect to database. Required.
* `DB_PORT`: port to use to connect to database. Optional, defaults to `3306`
* `DB_USER`: username for the database
* `DB_PASS`: password for the database
* `DB_NAMES`: names of databases to dump; defaults to all databases in the database server
* `DB_DUMP_DEBUG`: If set to `true`, print copious shell script messages to the container log. Otherwise only basic messages are printed.
* `DB_DUMP_TARGET`: Where to put the dump file, should be a directory.
    * S3: If the value of `DB_DUMP_TARGET` is a URL of the format `s3://bucketname/path` then it will connect via awscli.
* `AWS_ACCESS_KEY_ID`: AWS Key ID
* `AWS_SECRET_ACCESS_KEY`: AWS Secret Access Key
* `AWS_DEFAULT_REGION`: Region in which the bucket resides
* `AWS_ENDPOINT_URL`: Specify an alternative endpoint for s3 interopable systems e.g. Digitalocean 
* `MYSQLDUMP_OPTS`: A string of options to pass to `mysqldump`, e.g. `MYSQLDUMP_OPTS="--opt abc --param def --max_allowed_packet=123455678"` will run `mysqldump --opt abc --param def --max_allowed_packet=123455678`


### Permissions
By default, the backup/restore process does **not** run as root (UID O). Whenever possible, you should run processes (not just in containers) as users other than root. In this case, it runs as username `appuser` with UID/GID `1005`.

### Database Container
In order to perform the actual dump, `mysql-backup` needs to connect to the database container. You **must** pass the database hostname - which can be another container or any database process accessible from the backup container - by passing the environment variable `DB_SERVER` with the hostname or IP address of the database. You **may** override the default port of `3306` by passing the environment variable `DB_PORT`.

````bash
docker run -d --restart=always -e DB_USER=user123 -e DB_PASS=pass123 -e DB_DUMP_TARGET=s3://my-bucket -e DB_SERVER=my-db-container
````

### Dump Target
The dump target is where you want the backup files to be saved. The backup file *always* is a compressed file the following format:

`YYYYMMDD_HHmm_db_name_.sql.tar.gz`

Where:

* YYYY = year in 4 digits
* MM = month number from 01-12
* DD = date for 01-31
* HH = hour from 00-23
* mm = minute from 00-59

The time used is UTC time at the moment the dump begins.

You'll need to specify your AWS credentials and default AWS region via `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and `AWS_DEFAULT_REGION`

Also note that if you are using an s3 interopable storage system like DigitalOcean you can use that as the target by setting `AWS_ENDPOINT_URL` to `${REGION_NAME}.digitaloceanspaces.com` and setting `DB_DUMP_TARGET` to `s3://bucketname/path`.   


## License
Released under the MIT License.
- Copyright Avi Deitcher https://github.com/deitch



