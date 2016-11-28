# Spofford -- TRLN Ingest

Spofford is a Rails application for ingesting and enhancing bibliographic
records for the Triangle Research Libraries Network (TRLN).

Setup is currently handled via Vagrant, but here's at least a partial list
of what you'll need installed on the target system, other than Ruby, of course.

 * Postgres 9.5+ (for JSONB and "upsert" support) -- [Postgres yum
   repositories]((https://yum.postgresql.org/repopackages.php) is a good place
   to get the relevant packages for your system if you're not using a very
   recent distribution.
 * Redis (for Sidekiq)
 * Yajl (for JSON processing)
 * Node.js (for Typescript in the asset pipeline; we dont' have any functional JS yet though)

## Getting Started

### Vagrant

Use `vagrant` if you just need to get going; the `Vagrantfile` in this project
it will do what it can to set up all the parts for you.

Especially if you don't use vagrant, it's worth looking at the steps in the
`Vagrantfile` to see what packages and services you'll need. 

Vagrant is a tool for managing virtual machines; it doesn't itself contain
any 'virtualization' features, but it knows how to interact with VM providers (e.g Virtualbox, vmWare Fusion, things like that) and is intended to let you quickly set up a virtual environment.

Vagrant provides hooks to download 'boxes' which are images of various
operating systems; we use a plain Centos 7 image here, then use a
*provisioning* script (defined as part of the `Vagrantfile`) to install
necessary software, perform updates, etc., and generally get the virtual
machine into a 'ready-to-run' state as quickly as possible.

To provision a VM, once you've checked out this repository, change into its
directory.  Open a terminal and type

    $ vagrant up --provider virtualbox
    
I'll assume throughout you're using virtualbox as the 'provider', since that's
available for macOS, Windows, and Linux.  Other providers may work (e.g. this
has been tested under `libvirt` but that's Linux-only).

Before executing `vagrant up` for the first time, if you're using Virtualbox as your VM provider,  make sure you have installed the `vagrant-vbguest` plugin: 

    $ vagrant plugin install vagrant-vbguest

The plugin ensures that your VM will have the guest extension options, which
makes filesystem mirroring between the host and guest more robust.

Once the vagrant VM's downloaded, updated, provisioned, and running, you can
just type `vagrant ssh` in the working directory, and you'll be logged in as
the `vagrant` user; if you need to do any administration on your VM, this user
has passwordless `sudo` privileges.

`vagrant ssh` puts you in `/home/vagrant` on the guest VM.  The application
directory will be mounted under `$HOME/synced`, and any changes you make in the
guest VM will be made to the repository files.  This means you can edit the
files through the guest or through the host, so you can use your favourite
tools.

On first boot, you should have a `ruby` and `gem` executable on your PATH.  Execute

    $ synced/install.sh

(or)

    $ cd synced
    $ ./install.sh

And your environment should be ready to go -- all gems installed and database initialized.  Note you'll need to start sidekiq before you can start the application (see below).

One gem that might give you some trouble is the `pg` gem.  Check the
`Vagrantfile` for some more hints that can help if it doesn't 'just work'.

`bundle exec rake db:reset` may come in useful during development (clears databae and recreates tables).

### Application Notes

Vagrant setup forwards port 3000 to the localhost.  

`bundle exec passenger start` to get started.

The index page shows the most recent 'transactions' (ingest package
submissions).  Transaction pages have paths like `/transaction/:id`

Once documents are ingested, they can be viewed at
`http://localhost:3000/record/:id` where `:id` is the unique ID of the record, e.g. something like `NCCU1293879`.  This resulting page gives you a quick overview of the record's main characteristics and shows you the 'raw' Argot stored for it.  `/record` by itself will show you links to a bunch of recently updated records.

Ingest: you can POST 'Argot flavoured concatenated JSON' to `http://localhost:3000/ingest/[institution code]` and it 
will do some minimal pre-processing on your files, and stash them.  Before returning, it will kick off an asynchronous 
process that ingests your documents. These processes can be monitored via Sidekiq.

* Only adds/updates are currently supported when uploading JSON
* This is not hooked up to Solr yet either

You can also POST a `.zip` file containing multiple JSON files.  Files matching the pattern `add*.json` will be interpreted as containing Argot records to be updated, while files named `delete*.json` will be interpreted as JSON arrays containing IDs (in the form 'NCSU234098')  to be deleted.

See the [Spofford Client](https://github.com/trn/spofford-client`) for a tool that can handle many interactions with this service, including the assembly and ingest of ingest packages from the command line.

### Sidekiq

Ingests are handled by Sidekiq, so *you will need that running* before you start your Rails process.  Currently this is not set up as a system service, so you'll need to, in a separate VM session, execute the following:

```bash
cd synced
bundle exec sidekiq
```

If you don't, your uploads will get processed but nothing will happen with them.

For shared testing or production environments, you'll need to have Sidekiq
running as a system service.  The status of sidekiq and all its jobs is
available at `/sidekiq`.  This URL will need to be secured for production
purposes.

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

Currently, we are *not* indexing any of the fields, but ISBN would be a natural one to look at.

### Testing -- TODO 

Nothing's really been set up for testing yet.

### Sample Package Ingest Command
```
curl -v -H'Content-type: application/json' --data-binary @<file> http://localhost:3000/ingest/unc
```
Can change "application/json" to "application/zip" for zip file
