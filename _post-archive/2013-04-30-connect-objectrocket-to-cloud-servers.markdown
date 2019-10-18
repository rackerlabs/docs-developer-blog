---
layout: post
title: Connect ObjectRocket to Cloud Servers
date: '2013-04-30 07:51'
comments: true
author: Hart Hoover
published: true
categories:
  - Cloud Servers
---
ObjectRocket, the industrial strength MongoDB database-as-a-service company that Rackspace acquired in February, is now available in our Chicago data center. This means that you can now use ObjectRocket as part of your Rackspace deployments. You can read about the new data center here and a recent performance benchmark study that we did [here](https://devops.rackspace.com/benchmarking-hosted-mongodb-services.html).

Now that you can use a lightning fast (and automatically scalable and redundant) MongoDB-as-a-service right next to the rest of the app infrastructure, we thought it would be helpful to post a tutorial about how to connect MongoDB to your application running on the Rackspace Cloud using ObjectRocket.<!-- more -->

##Creating your first MongoDB application on ObjectRocket

###Signup

The first thing you'll need to do is [signup for an ObjectRocket plan](https://www.objectrocket.com/pricing). Plans start at as little as $29 per month for a 1GB shard and there's a 30-day free trial, so you can try it out without any risk. Please note that bandwidth charges will incur for communications between Cloud Servers and ObjectRocket.

###Billing

Yes we need to get that out of the way before an instance can be created, the account must be updated with current credit card information. To add a card, go to the [account page](https://app.objectrocket.com/account) and enter a credit card - it’s secure and easy.

###Create your redundant instance

Next you need to create your instance. First, go to the [instances page](https://app.objectrocket.com/instances) and select “add instance.” The add instance dialog will pop up. Add a name for the instance - any alphanumerical string is fine, no spaces. Also choose a plan and instance size in the plan selector box. Click submit. You have just provisioned a fully redundant, highly performant, sharded instance.

{% img center 2013-04-30-connect-objectrocket/cp.png 400 400 %}

###Adding a Database

Database(s) - Now add your database (or as many databases as you’d like for that matter) through the ObjectRocket API or Control Panel. Adding a database through the API is super simple. Here is the curl command to add a database and the returned status:

```bash
$ curl --data 'api_key=<your-api-key>&doc={"username":"<password>"}' \
'https://api.objectrocket.com/db/my-db-name/add'
```

All we had to do is supply:

* an API key (which you can get from the ObjectRocket Control Panel)
* a username and password for the new database 
* a database name


And when we run the command, we get a confirmation that the database was successfully created.

```json
{
    "data":"OK", 
    "rc":0
}
```

##Security

We’re security conscious, so you need to be too! Before connecting you need to add an ACL (Access Control List). An ACL allows access from an outside network into the ObjectRocket system. It's based on an [CIDR](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing) type IP address mask. ObjectRocket makes it easy to manage your ACL lists. Head to the [instances page](https://app.objectrocket.com/instances) then click on the instance you would like to add an ACL to. Select the ACL tab and the add ACL button. ACLs are granted to an instance, so they allow access to every database in that instance. Enter the IP address of your client and a brief description.

Congrats you’re ready to go!

Connecting your new Mongo database to your Rackspace Cloud infrastructure
Once you have your database, you need to connect it to your infrastructure, most likely your Cloud Servers.  

ObjectRocket allows for access via native MongoDB drivers just like any other MongoDB database. Each instance has its own unique connect string. The connect string assigned to the instance can be found in the “driver” column at <https://app.objectrocket.com/instances/>. Click on the icon. A unique port is assigned for the plain text and SSL drivers.    

Ok, enough talk. Everyone loves code, so here’s a simple Python example:

```python
import bson
import pprint
import pymongo, pymongo.objectid
import sys

## Connect string 
## Server: "localhost:27017", 
## Database: "users"
## Write concern: 1 (acknowledge writes)
db = 'mongodb://rocketuser:rocketpass@localhost:27017/users?w=1'

## Connect to MongoDB, create a handle for the "users" database
try:
    connection = pymongo.Connection(db)
    db = connection['users']
except Exception, ex:
    print "Couldn't connect, exception is: %s" % ex
    sys.exit(1)

## Define a simple document
doc = {'login': 'bob', 
       'password': 'secret'}

## Insert this document into the "accounts" collection
try:
  db.accounts.insert(doc)
except Exception, ex:
  print "Unable to insert, exception is: %s" % ex

## Update the user's password
db.accounts.update({'login': 'bob'}, 
                   {"$set": {'password': 'notsosecret'}})

## Find our user and store the returned document to variable "a"
user = db.accounts.find_one({'login': 'bob'})

## Pretty-print JSON document returned from MongoDB
pprint.pprint(user)

## Remove our user's document by _id
db.accounts.remove({"_id": pymongo.objectid.ObjectId(user['_id'])})
```

You can find this example and a simple Node.js example [here](https://docs.objectrocket.com/native).
 
That’s it. Now you can use MongoDB as part of your Rackspace infrastructure. You can learn more about ObjectRocket at our [website](https://www.objectrocket.com) and in our [docs](https://docs.objectrocket.com), or drop a line to <support@objectrocket.com>. We’re happy to chat.
