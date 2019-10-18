---
layout: post
title: Better Builders with jclouds
date: '2014-08-05 23:59'
comments: true
author: Zack Shoylev
published: true
categories:
  - jclouds
  - developers
  - sdk
bio: >
  Zack Shoylev is a committer on the Apache jclouds project and a Software
  Developer for Rackspace. He is currently working on   open source cloud SDK
  development. Zack’s technical interests focus on open source development, cloud
  computing, and big data  processing with Java. Zack's twitter handle:
  @zackshoylev and Freenode nick: zacksh
---
# Better Builders with jclouds

If you are a new [jclouds](https://developer.rackspace.com/sdks/java/) developer, or even if you are already developing jclouds support for any of the OpenStack or Rackspace APIs, you have likely seen the domain classes that are used throughout the the jclouds codebase.
These classes are used to represent OpenStack resources, particularly the JSON structures supported by OpenStack APIs.

For example, when listing database users in openstack-trove (the OpenStack database API), the service returns a JSON response body describing the existing users. This JSON might look something like this:

{% highlight JSON %}
{
    "users": [
        {
            "databases": [],
            "host": "%",
            "name": "dbuser1"
        },
        {
            "databases": [
                {
                    "name": "databaseB"
                },
                {
                    "name": "databaseC"
                }
            ],
            "host": "%",
            "name": "dbuser2"
        },
        {
            "databases": [],
            "name": "dbuser3",
            "host": "%"
        },
        {
            "databases": [
                {
                    "name": "sampledb"
                }
            ],
            "host": "%",
            "name": "demouser"
        }
    ]
}
{% endhighlight %}

To parse the response, jclouds uses [domain classes](https://github.com/jclouds/jclouds/blob/master/apis/openstack-trove/src/main/java/org/jclouds/openstack/trove/v1/domain/User.java) to represent the JSON data returned by the service. The array of "users" is unwrapped into individual User domain objects. Conversely, when creating users, domain objects are transformed into a JSON request body.

Because of the relative simplicity of user creation in trove, jclouds developers can use a create method in the features package without having to build an instance of the User class. For example, the developer might use a method such as

{% highlight Java %}
boolean create(String userName, String password,  String databaseName);
{% endhighlight %}

In this case, it was easy to add support for this call by using a [map binder](https://github.com/jclouds/jclouds/blob/master/apis/openstack-trove/src/main/java/org/jclouds/openstack/trove/v1/binders/BindCreateUserToJson.java).

However, some APIs send or receive significantly more complex JSON structures. Recent work on Neutron has shown that there are benefits to increased consistency among the domain classes and the OpenStack API calls that use them.

Current implementations have the following two issues :

1. Heavy use of map-binders and parsers to transform JSON. Map-binders use  annotation-selected classes to map method data (such as the data in the create-user call above) to the JSON required by the service. The [parsers](https://github.com/jclouds/jclouds-labs-openstack/blob/master/openstack-neutron/src/main/java/org/jclouds/openstack/neutron/v2_0/functions/ParseNetworkDetails.java) apply the reverse transformation: from JSON to domain objects.
2. Lack of consistent, concise, and user-friendly way to use domain objects in create/update/list methods.

In addition to fixing these issues, jclouds wants to provide developers with some compiler checks and other syntactic sugar (fluent builders), while also supporting different updating, creating, or listing validation strategies.

We want to

1. Ensure object immutability.
2. Utilize the fluent builder pattern.
3. Ensure that "create" objects can only be used for create; update for update; and listed resources cannot be directly sent back to the service.
4. Reuse code and keep domain classes [DRY](https://en.wikipedia.org/wiki/Don't_repeat_yourself).
5. Allow using different validation strategies (for example, create vs update).

We have been able to identify a pattern that addresses these issues. Here is some [sample code](https://github.com/jclouds/jclouds-labs-openstack/blob/master/openstack-neutron/src/main/java/org/jclouds/openstack/neutron/v2/domain/Router.java).

This approach reuses code by having [GSON](https://code.google.com/p/google-gson/) handle the domain objects directly, as much as possible, both for serialization and deserialization, thus eliminating map-binders and parsers in most cases. The domain classes annotate their member variables using the @Named (for serialization) and @ConstructorProperties (for deserialization) annotations.

Many of the JSON attributes in Neutron are optional. GSON's jclouds configuration supports such optional values by using @Nullable and boxed types. An alternate supported method, more convoluted, implements Optional<T> private member variables and getter return types.

To ensure immutability, users have no access to a constructor or setters, and instead they must instantiate domain objects by using a slightly modified Builder pattern. The builder pattern also provides proper validation and user-friendliness.

Some [simpler classes](https://github.com/jclouds/jclouds-labs-openstack/blob/master/openstack-neutron/src/main/java/org/jclouds/openstack/neutron/v2/domain/AddressPair.java) implement the regular fluent builder pattern.

In [other cases](https://github.com/jclouds/jclouds-labs-openstack/blob/master/openstack-neutron/src/main/java/org/jclouds/openstack/neutron/v2/features/NetworkApi.java), the same domain class has several different purposes, such as making sure users have different Network-subtype object instances for updating, creating, and listing networks:

1. Listing networks returns a Network or a list of Networks.
2. Updating a network requires Network.UpdateOptions.
3. Creating a network requires Network.CreateOptions.

CreateOptions and UpdateOptions extend Network and implement their own copy constructors, with custom validation, if needed.

To instantiate these create or update-specific objects, developers have access to CreateBuilder and UpdateBuilder, which both extend the regular Network builder abstract class. The only code these special builders implement: the constructor (taking as parameters any required properties), a build() method returning the create or update object, and also self(). The self method is needed to make sure we can reuse most of the Builder code, but still be able to chain the fluent builder methods.

This is how it all works out from the developer's perspective:

{% highlight Java %}
Network.CreateOptions createNetwork = Network.createOptions("jclouds-wibble")
           .networkType(NetworkType.LOCAL)
           .build();

Network network = networkApi.create(createNetwork);

Network.UpdateOptions updateNetwork = Network.updateOptions()
           .name("jclouds-wibble-updated")
           .networkType(NetworkType.LOCAL)
           .build();

networkApi.update("some id", updateNetwork);
{% endhighlight %}

This ensures developers get an easy to understand interface, with validation and compiler checks. It also allows jclouds developers to use significantly less code when developing complex domain classes that need to be reused in list/create/update API calls.
