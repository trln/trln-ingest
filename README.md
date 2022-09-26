# Spofford -- TRLN Ingest

Spofford is a Rails application for ingesting and enhancing bibliographic
records for the Triangle Research Libraries Network (TRLN).

![Continuous Integration Status](https://github.com/trln/trln-ingest/workflows/CI/badge.svg)

Setup is currently handled via Vagrant or Docker Compose, but here's at least a
partial list of what you'll need installed on the target system, other than
Ruby, of course.

 * Postgres 9.5+ (for JSONB and "upsert" support) -- [Postgres yum
   repositories](https://yum.postgresql.org/repopackages.php) is a good place
   to get the relevant packages for your system if you're not using a very
   recent distribution.
 * Redis (for Sidekiq)
 * Yajl (for JSON processing)
 * Node.js (for the asset pipeline, not as a server)

## Getting Started

### Containers and Docker/Podman Compose

The Vagrant setup should do most of what's needed, but a somewhat
lighter-weight approach is available using `docker compose` (or
`podman-compose`), as defined in the `docker-compose.yml` and various
`Dockerfile`s in the project's directory.

Before running containers for all the services via compose, you will need
to run the `init.sh` script in the same directory as this file; this will
pull down the solr configuration from the working repository and, if needed, create a docker/podman secret for the PostgreSQL database password.

Read the comments in `init.sh` for more information.

From that point, `docker compose up` will start all the necessary services,
including the primary Rails application (in development mode, so editing files
in the Rails application directories will take effect immediately).

For more information, look at the `docker-compose.yml`, the `Dockerfile` in
this directory, and the one in in the `solr-docker` subdirectory. A little bit
of `depends_on` and `wait-for` fine-tuning is necessary to ensure that the Solr
plugin files (in `solr-docker/plugins`) and the Solr configuration are
correctly installed before the services services start. When the smoke clears
you should have a complete set of services.

The default exposed ports are:

| Port | Service |
|------| --------|
| 3000 | Rails |
| 2181 | Zookeeper |
| 8983 | solr |
| 6379 | Redis |
| 5432 | Postgres |


### Vagrant

If you don't want to use containers, you can use
[`vagrant`](https://www.vagrantup.com/) if you just need to get going.

Vagrant is a tool for managing virtual machines; it doesn't itself contain any
'virtualization' features, but it knows how to interact with several VM
providers (e.g Virtualbox, vmWare Fusion, things like that) and is intended to
let you quickly set up a virtual environment.

The `Vagrantfile` in this project does what it can to set up all the parts of
the application for you.   _Especially_ if you _don't_ use vagrant, it's worth
looking at the steps in this file to see what packages and services you'll
need.  It uses the `ansible-local` provisioner to do a lot of the work, but there is still a step or two that you need to do manually.

#### How Vagrant Works / a sort of glossary

Vagrant provides hooks to download 'boxes' which are images of various
operating systems; we use a plain Centos 7 image here, then use a
*provisioning* script (defined as part of the `Vagrantfile`) to pull down
updates, install various packages, and, generally get the virtual machine into
a 'ready-to-run' state as quickly as possible.

In this case, the provisioner used is `ansible-local`, which installs Ansible
into the VM and runs the playbook in the `ansible` directory.  This does not
require having Ansible installed on your machine.  The Ansible playbook will install Ruby (via RVM), PostgreSQL, Redis, and all the other stuff mentioned above.

It will also run `bundle install` on the Rails application and run the inital
database setup, including creating a default admin account (see below).

It will also install Solr and install the index configuration from TRLN's
github.

Since all of the above is quite a lot, some of which depends on external
services behaving as they're expected to, it doesn't always work entirely
smoothly.  The provisioner is intended to be re-runnable, so if something does fail due to external reasons, you can always re-run the provisioner (via `vagrant provision`).

For everything else, of if you want to install things outside of the confines of Vagrant, you can look at `ansible/playbook.yml` to get a sense of what
it's trying to do.

Before executing `vagrant up` for the first time, if you're using Virtualbox as
your VM provider,  make sure you have installed the `vagrant-vbguest` plugin: 

    $ vagrant plugin install vagrant-vbguest

The plugin ensures that your VM will have the guest extension options, which
makes filesystem mirroring between the host and guest more robust.

To bring up the VM and provision it, once you've checked out this repository,
change into its directory.  Open a terminal and type

    $ vagrant up --provider virtualbox

I'll assume throughout you're using virtualbox as the 'provider', since that's
available for macOS, Windows, and Linux.  Other providers may work (e.g. this
has been tested under `libvirt` but that's Linux-only, and requires a tweak to the `Vagrantfile`).

Once the vagrant VM's downloaded, updated, provisioned, and running, you can
just type `vagrant ssh` in the working directory, and you'll be logged in as
the `vagrant` user; if you need to do any administration on your VM, this user
has passwordless `sudo` privileges.

Other vagrant commands you may find useful:

    $ vagrant halt # shuts down the VM (power off)
    $ vagrant suspend # save current state of VM and stop running it
    $ vagrant resume # re-start a suspended VM
    $ vagrant ssh # log in to the VM
    $ vagrant destroy # stops the VM (if running) and deletes it 
    $ vagrant status # see which VMS are running

`vagrant ssh` puts you in `/vagrant` on the guest VM, which is mounted at the root of this repository.  This means you can edit files on the host machine using your favourite editor, and they will be made available 'inside' the VM.

Once the provisioner is finished, you should be able to execute `./start.sh` to start the Rails application.

One gem that might give you some trouble is the `pg` gem.  Check the
`Vagrantfile` for some more hints that can help if it doesn't 'just work'.

`bundle exec rake db:reset` may come in useful during development (clears databae and recreates tables).

### Installing Solr

The bundled Ansible playbook should install Solr with the necessary
libraries to use TRLN Discovvery's solr configuration.  It should also install
the *public* configset (which should normally be in sync with the one in actual
use) from `trln/argon-solr-config`.  These operations might fail due to external circumstances, but usually re-running the provisioner will work.

### Accessing your VM via a web browser

Vagrant setup forwards port 3000 to port 3001 on the host, so opening your
browser to http://localhost:3001 will let you interact with
Spofford.   In addition, the Solr instance will be forwarded to 8985 on the host, i.e. http://localhost:8985/solr

### Logging In

(the below are run during VM provisioning)

If you are running under Vagrant, and you have already created your database with 

    $ bundle exec rake db:migrate

You will be able to create an initial admin user (this is disabled for other
contexts for security reasons) by running the custom task:

    $ bundle exec rake user:admin

This will create a user `admin@localhost` with the password you can see by
looking in `lib/tasks/user.rake`; it will have admin privileges and be approved to use the application.

#### Running Spofford 

    $ cd /vagrant && ./start.sh

Use of the `start.sh` script is only for use during development.  Production
deployments will need to separate out Sidekiq and Rails services.

#### Spofford endpoints

The index page shows the most recent 'transactions' (ingest package
submissions).  Transaction pages have paths like `/transaction/:id`; 

Once documents are ingested, they can be viewed at
`http://localhost:3001/record/:id` where `:id` is the unique ID of the record, e.g. something like `NCCU1293879`.  This resulting page gives you a quick overview of the record's main characteristics and shows you the 'raw' Argot stored for it.  `/record` by itself will show you links to a bunch of recently updated records.

Any of the above URLs can also be fetched as JSON via appending `.json` to them.

#### Ingest 

You can POST Argot flavoured concatenated JSON' to
`http://localhost:3001/ingest/[institution code]` and it will do some minimal
pre-processing on your files, and stash them.  You can also POST a `.zip` file
containing multiple JSON files and it will be processed as a unified ingest
package ("transaction").

ZIP entries matching the pattern `add*.json`
will be interpreted as containing Argot records to be updated, while files
named `delete*.json` will be interpreted as JSON arrays containing IDs (in the
form 'NCSU234098')  to be deleted.

Before returning, it will kick off an asynchronous process (via sidekiq) that ingests your documents.  You can monitor the progress of these jobs via Sidekiq.

See the [Spofford Client](https://github.com/trn/spofford-client`) for a tool that can handle many interactions with this service, including the assembly and ingest of ingest packages from the command line.

### Sidekiq

Sidekiq must be running before you start your Rails process, if you want to
process ingest packages.

    $ cd /vagrant
    $ bundle exec sidekiq

(this is done in the start script)  If you don't, your uploads will get stored,
but the records won't be ingested into the databse and nothing will get put into Solr.

The status of sidekiq and all its jobs is
available at `http://localhost:3001/sidekiq`.  This URL will need to be secured for production purposes.

During development, you may find the custom rake task `util:clear_sidekiq`
useful; Sidekiq has a 'retry' feature which will try to re-run any failed jobs,
and if you've cleaned out your database, you can get a lot of errors.  Running 
this *will* wipe out sidekiq's data store (a redis instance, which sidekiq starts for you automatically).

Sidekiq worker tasks are defined in `workers/` directory, and may make use of
services which will be located in `services/` directory.  

See `services/transaction_processor.rb` for the logic that manages the JSON->database data flow.

### Postgres and JSONB

The content of records is stored as JSONB in a Postgres database.  Storage
requirements (irrespective of indexes!) appear to be slightly smaller than the
amount of disk space taken up by JSON files themselves.  Use of Postgres allows
us to create indexes on and query into the JSON content itself, e.g. to look
for a document with a certain ISBN, you can run something like

```sql
SELECT 
  id, content#>'{title,main,value}' 
FROM
  documents 
WHERE 
  content->'isbn' ? '9251021511';
```

(roughly, give me the ID and the text content at the path `title.main.value` in
the (JSON-typed) 'content' field  for all documents where \[this isbn\] is in
the array of the `isbn` field).  

Currently, we are *not* indexing any of the fields inside Postgres, but ISBN
would be a natural one to look at.

### Environment Setup

When running under Vagrant, things should Just Work, but there are a number of
environment variables that impact how this application works:

|Variable  | Default   | Used in File | Notes
|----------|:---------:|------|------|
| `DB_ADAPTER` | `postgres` |  `config/database.yml` | see above
| `DB_HOST`   | (not set)   | `config/databse.yml` | hostname to connect to (assumes standard port 5432);  if not set, assumes connection to DB running on the same machine via UNIX socket | 
| `DB_NAME` | `shrindex` | `config/database.yml` | the database name
| `DB_USER` | `set_env_vars` | `config/database.yml` | username
| `DB_PASSWORD` | (not set) | `config/database.yml` | default PostgreSQL setup uses 'ident' auth from localhost, which requires this to not be set.
| `TRANSACTION_FILES_BASE` | (not set) | `config/initializers/spofford.yml` | base directory for ingest packages and error messages for any given ingest package.  Will be created if it does not exist. |
| `SECRET_KEY_BASE` | (not set)  | n/a | Used to secure sessions, and also by Devise |

The Vagrant provisioner will create `.vagrant_rails_env`, which will be read by
`start.sh`, providing defaults for all necessary variable

The default `start.sh` script sets the variables to appropriate values when
running under Vagrant (no hostname, user 'shrindex' , no password).

Production or shared deployments will need to set these variables
elsewhere, e.g. if you plan to run the application via `systemd` unit files,
you would typically store the values in `/etc/default/[service name]` and then
make sure that your unit file has the following two lines in the `[Service]`
stanza:

```
# assuming service name == 'trln-ingest'
EnvironmentFile=/etc/default/trln-ingest 
PassEnvironment=DB_HOST DB_USER DB_PASSWORD DB_ADAPTER DB_NAME RAILS_ENV TRANSACTION_FILES_BASE_
```

You may also want to create a `config/database.yml` and `config/solr.yml` for
your deployment environment and copy those into your deployment directory
(capistrano, the tool we are using, has facilities for doing this).

### Testing

Tests (`bundle exec rake test`) should be run from inside the VM, if possible,
largely because some of them depend on the database being available at
`localhost`   If youare willing to set up PostgreSQL in the right way (see the
provisioning steps in `ansible/playbook.yml` relating to `pg_hba.conf` and
`postgresql.conf`) on your machine, you can run them from outside.

The bundled `.travis-ci.yml` ensures that Postgres is installed when running
the continuous integration builds that happen when you create a pull request in
GitHub.

Testing creates a database called `shrindex_testing` which will be deleted at
the end of the run.  Ensure that the database user in the `test` environment
has the requisite permissions.

    $ bundle exec rake test

### Sample Package Ingest Command

Install [spofford-client](/trln/spofford-client), or if you like to do things
manually:

    $ curl -v -H'Content-type: application/json' --data-binary @<file> http://localhost:3001/ingest/unc

Replace `unc` with the name of your institution; `-v` is optional, but can help to read what's going on in case anything fails.

If you have a `.zip` file, change "application/json" to "application/zip".
