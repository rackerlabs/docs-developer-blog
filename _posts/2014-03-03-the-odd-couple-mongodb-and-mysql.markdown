---
layout: post
title: 'The odd couple: MongoDB and MySQL'
date: '2014-03-03 14:10'
comments: true
author: Alex Brandt
published: true
categories:
  - Database
---

The choices and combinations we have available during datastore selection
prove that we're no longer in the one-size-fits-all datastore world.

Today, there are compelling reasons to mix and match your SQL datastores
(such as MySQL, PostgreSQL, Oracle or SQLServer) with your NoSQL datastores
(MongoDB, CouchDB, and Neo4J among others).
While Oracle may still be the preferred system of record for enterprises, it's
no longer the only game in town.

Developers are starting to use combinations of SQL and NoSQL to solve their
problems—sometimes against the wishes of DBAs or IT Departments.

<!-- more -->

### Choosing the right tool for the job

There are five broad categories of datastores in today's world: column-family, document, graph, key-value and relational.  Polyglot persistence literally means using many languages to store or persist your data.
In more practical terms this means we might use Cypher, JSON, SQL or a number of other query languages to access our data from within the same application.
Using these different datastores and their different languages is becoming more prominent as developers look for better tools to laser in solutions to their persistence needs.

Sadalage and Fowler note the necessity of polyglot persistence in [NoSQL Distilled](http://books.google.com/books/about/NoSQL_Distilled.html?id=AyY1a6-k3PIC&hl=en) by saying:

> Different databases are designed to solve different problems.
> Using a single database engine for all of the requirements usually leads to non-performant solutions; storing transactional data, caching session information, traversing graph [sic] of customers and the products their friends bought are essentially different problems.

> Let's think of data relationships.
> RDBMS solutions are good at enforcing that relationships exist.
> If we want to discover relationships, or have to find data from different tables that belong to the same object, then the use of RDBMS starts being difficult.

Datastore choice comes down to two criteria:

1. The structure of the data being stored
2. The queries being used to interact with the data

The way we query data changes the way we structure it.
As Sadalage and Fowler state above, relational datastores excel at enforcing related entities; however, they get in the way as soon as we need to discover other relationships between those entities.

Below, I discuss one use case, CraigsList data archival with MongoDB, and speculate about how they may have accomplished this.

### The players: MongoDB, MySQL and CraigsList

#### MongoDB

MongoDB has become a favored NoSQL alternative to MySQL.
Its many benefits include scalability, auto-sharding and availability of native bindings for today’s popular programming languages.
The core differentiator between MongoDB and relational datastores is the way MongoDB thinks about and stores data.
Rather than using a collection of tables with foreign key constraints to enforce relationships, data in MongoDB is represented as a collection of documents.

The documents are analogous (not identical) to rows or tuples in relational data structures.
The categorization and nomenclature of a document datastore comes directly from the data being stored as JSON documents grouped into collections.
The depth of these documents is unlimited and fully inspectable with queries or indexes.
Usually a good representation of data for MongoDB can be arrived at by denormalizing data that would be appropriate for a relational database.
Of course, the particular queries you want to make should guide this process.

More information about the nuances of MongoDB can be found on [MongoDB's website](http://www.mongodb.org/).

#### MySQL

The classic that everyone knows and loves, MySQL has been around since the dawn of time (in computing timescales) and is easily the most widely used DBMS.
The functionality it provides has allowed applications to model data for nearly a decade and act as a system of record around many business purposes.
These days when people think of a relational database they probably think of MySQL.

MySQL provides us with an implementation of the classic relational data model.
Using type theory and set theory, it was developed in the 1970s by E.F. Codd.
Being able to be programmatically normalized, planned or introspected, make relational data systems extremely popular.
In fact, these datastores continue to be favored as they solve the problem of modeling data in a general manner.

#### CraigsList

One well-known online business that employs both a MongoDB and MySQL datastore is CraigsList.
Their side-by-side adoption of the two datastores is outlined in a [MongoDB Case Study](http://www.mongodb.com/customers/craigslist), but below is a thumbnail sketch.

Due to regulatory requirements, Craigslist has to retain digital records of its classifieds.
With over a million new classifieds per day, that's a significant amount of data for CraigsList to retain.
It uses a MySQL datastore to hold all the active information about classifieds, while MongoDB is used to store the archived data—possibly anything over 30 days.
As part of normal business changes, the data schema of stored data changes.
By using MongoDB for archived data, CraigsList was able to effectively segment its data and mitigate problems due to schema migrations.

As a thought experiment, I want to speculate about one possible implementation for using MongoDB and MySQL side-by-side in a CraigsList-esque application.
It highly unlikely that this is how CraigsList is actually doing their data storage, but it is an interesting way to look at how multiple datastores could work together for a familiar, highly transactional, website.

### How is it done?

Developers and engineers inevitably run into problems when they perform a schema update on a bulky SQL database.
This can be avoided by simply having less data to "fix up" after the schema update is applied.
The pain of these migrations or schema updates typically increases proportionally to the amount of data.

In our example, let's imagine CraigsList requires a new piece of information from users selling an item.
Because the schema must be updated, CraigsList would want to reduce the size of the affected data to minimize the pain of the update.

After a few of these archival and migration cycles, CraigsList will have built a hefty collection of heterogeneous data that requires a schemaless datastore if it is to reside in a single location.
MongoDB fits this bill very well.

An example schema for classifieds would look something like the following (shamelessly re-implemented from [craigslist-clone](https://github.com/railslist/craigslist-clone)):

```sql
CREATE TABLE `classifieds` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(75) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `location` varchar(75) COLLATE utf8_unicode_ci DEFAULT NULL,
  `adtype` varchar(1) COLLATE utf8_unicode_ci DEFAULT 'O',
  `email` varchar(75) COLLATE utf8_unicode_ci DEFAULT NULL,
  `phone` varchar(75) COLLATE utf8_unicode_ci DEFAULT NULL,
  `activation_code` varchar(40) COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` tinyint(4) DEFAULT '0',
  `category_id` int(11) DEFAULT NULL,
  `subcategory_id` int(11) DEFAULT NULL,
  `city_id` int(11) DEFAULT NULL,
  `permalink` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `image_file_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `image_content_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `image_file_size` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
```

Of course, CraigsList most likely has a different schema and at the very least discovered their current schema after several iterations.
Also, they may decide to change how their data is organized and change their schema again in the future.
We want to use the ``created_at`` and ``updated_at`` fields to decide when we're going to archive the data contained in MySQL.

Let's pretend Craigslist's classifieds policy states that a classified will remain available on the website for two weeks.
After this time, they want the classified to still be available but not necessarily active (in MySQL).
To accomplish this we can use a combination of [SQLAlchemy](http://www.sqlalchemy.org/) and [pymongo](https://github.com/mongodb/mongo-python-driver):

First, we need to get the data out of our MySQL instance.
We will utilize SQLAlchemy to accomplish this and have it introspect our schema (making this code far more re-usable for this purpose).

```python
import sqlalchemy.schema

m = sqlalchemy.schema.MetaData("mysql://root:I'm required why?@192.0.2.3/craigslist")
m.reflect()

print m.tables.keys()
```

If you're successfully connecting to your database, you'll see your keys (column names) printed out in standard python fashion: ``[u'classifieds', u'cities', u'subcategories', u'categories']``.
We still need to get the individual data items out of these tables.
Not only can we see them, but SQLAlchemy also provides an elegant interface to make this a lot easier.

We now have our table definitions from the introspection.
It is time to either create object maps or query those tables to get the data items they contain.
The query below will extract our classifieds from the datastore (the other tables are left as an exercise to the reader).

```python
import sqlalchemy.sql

connection = m.bind.connect()

classifieds = m.tables['classifieds']

query = classifieds.select()

result = connection.execute(query)

for row in result:
    print dict(row.items())
```

This snippet uses our MySQL connection to query for all of the classifieds.
It could easily be expanded to handle all tables, denormalizing the data to better fit the document style of MongoDB.
But for the purpose of this demonstration, we'll only be focusing on the classifieds table. At this point, we've converted every individual item in the classifieds table into a dictionary, which is exactly what we'll need to insert it into MongoDB via pymongo.

The next sample shows how to connect to and insert a dictionary into pymongo:

```python
import pymongo

client = pymongo.MongoClient('mongodb://192.0.2.2')

db = client['craigslist']
collection = db['classifieds']
collection.insert({'_id': 1})
```

The only problem now is how SQLAlchemy and MongoDB specify their IDs.
SQLAlchemy uses a key of `id` whereas MongoDB uses a key of `_id`.
Thus, we need to translate that key (quite a simple process): ``classified['_id'] = classified.pop('id')``.

### Conclusion

While SQL and NoSQL datastores are often portrayed as an all or nothing proposition, it turns out that they can be used together to solve complex problems.
Through this example, we saw that very little code is required for a system that utilizes both a MongoDB and MySQL datastore.
In fact, this could be driven by cron rather than being daemonized.

The difficulty in utilizing multiple datastores doesn't necessarily lie in the development of translation code or migration code, but the administration of the additional systems does increase the difficulty.
Maintaining one datastore already requires expertise (DBAs or admins with datastore knowledge), and this demand for expertise increases as you introduce more datastores.

The business must decide if running multiple datastores is valuable.
There are technologies that will help mitigate these challenges.

In addition to automation techonolgies such as Chef and Salt, this challenge can be mitigated by taking advantage of service vendors such as [ObjectRocket](http://objectrocket.com), the managed MongoDB service by Rackspace.
Regardless of the increased complexity, if a problem would benefit from the use of multiple datastores, don't let assumptions stop you from exploring those solutions.
