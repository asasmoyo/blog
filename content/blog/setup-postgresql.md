+++
date = "2017-03-14T21:33:58+07:00"
title = "Setup PostgreSQL on Ubuntu 16.04"
draft = false
+++

### Install PostgreSQL

By default, Ubuntu 16.04 instance has already `postgresql` package, but it is pretty out of date. You can still install latest version available (currently 9.6) by adding PostgreSQL repo into your ubuntu instance.

First create a file at `/etc/apt/sources.list.d/postgres.list` with this content

```bash
deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main
```

Then run these commands to install PostgreSQL signing key and also install PostgreSQL 9.6

```bash
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install postgresql-9.6
```

Now PostgreSQL should already running on your machine. To check it you can use

```bash
sudo systemctl status postgresql
```

### Create User and Database

Newly created PostgreSQL instance has a superuser called `postgres` without a password. Fortunately `postgres` user can only login from `localhost` so it should be secure by default. If you want to add password to `postgres` you can run

```bash
sudo su postgres -c psql

# after in PostgreSQL cli
\password
```

It is better to have it's own user and database for each applications. To create them you can use

```bash
# create user first
create user "user_name" with password 'please_change_me' login;

# then create database
create database "db_name" owner 'user_name';
```

### Allow Remote Connections

The PostgreSQL instance that have been installed will listen to `localhost` and only allow `postgres` user to connect inside the machine without password authentication. To enable remote connections, there are 2 things that need to be done.

First you must change PostgreSQL listen address to your machine ip, for example your machine private ip. Open `/etc/postgresql/9.6/main/postgresql.conf` and find this line

```bash
#listen='localhost'
```

Change it into

```bash
listen='your_private_ip'
```

Then you also need to allow remote connections to access your PostgreSQL instance. To do that open `/etc/postgresql/9.6/main/pg_hba.conf` and add this line to the end of the file

```bash
host db_name user_name 0.0.0.0/0 md5
```

It will allows remote connections from anywhere (notice `0.0.0.0/0`) to access `db_name` with user `user_name`. You can improve the security by changing `0.0.0.0/0` to specific address, like `192.168.1.20/32`. Restart the PostgreSQL instance by `sudo systemctl restart postgresql` then your remote clients should be able to connect to your PostgreSQL instance.
