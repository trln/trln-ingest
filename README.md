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

I recommend vagrant if you just need to get going; it will do what it can to set up all the parts for you.  I am working on automating the postgres install, but that will take a bit of time.  It's worth looking at the steps in the `Vagrantfile` to see what packages and services you'll need. 
If you're using Vagrant, the application directory will be mounted under `$HOME/synced/trln-ingest'

```shell
bundle install
```

Will install all the necessary gems. The `pg` gem is used to access Postgres,
and this can be a bit difficult to get installed.  See the included `Vagrantfile` for some hints that should help with 
RHEL/Centos at least.
 
**TODO** - fully automate the database setup -- the provisioner (see
Vagrantfile) generates a random database password, but it's turned out to be
hard to get the database to work with a password in this context.  So, for now
before you run any of your rake database tasks, you'll have to do a bit of work.

One thing you *will* need to do is edit `/var/lib/pgsql/9.5/data/pg_hba.conf`, look for the line
 
`# TYPE  DATABASE        USER            ADDRESS                 METHOD`

and make sure the first non-comment looks like

`local   all             all                                     trust`

(basically, says anybody on the same machine as the postgres server can log in without a password).

During development, this is pretty handy, as it turns out (`psql -U shrindex` to log into the database and poke around), but it's not very secure.

`bundle exec rake db:reset` may come in useful during development (clears databae and recreates tables).

### Application Notes

Vagrant setup forwards port 3000 to the localhost.  

`bundle exec passenger start` to get started.

The index page shows the most recent 'transactions' (ingest package submissions).  Transaction pages have paths like `/transaction/:id`

Once documents are ingested, they can be viewed at `http://localhost:3000/record/:id` where `:id` is the unique ID
of the record, e.g. something like `NCCU1293879`.  This resulting page gives you a quick overview of the record's main
characteristics and shows you the 'raw' Argot stored for it.

`/record` by itself will show you links to a bunch of recently updated records.

Ingest: you can POST 'Argot flavoured concatenated JSON' to `http://localhost:3000/ingest/[institution code]` and it 
will do some minimal pre-processing on your files, and stash them.  Before returning, it will kick off an asynchronous 
process that ingests your documents. These processes can be monitored via Sidekiq.

* Only adds/updates are currently supported when uploading JSON
* This is not hooked up to Solr yet either

You can also POST a `.zip` file containing multiple JSON files.  Files matching the pattern `add*.json` will be interpreted as containing Argot records to be updated, while files named `delete*.json` will be interpreted as JSON arrays containing IDs (in the form 'NCSU234098')  to be deleted.

Ingests are handled by Sidekiq, so *you will need that running* before you start your Rails process:

```bash
cd /path/to/spofford
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
