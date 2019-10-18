---
layout: post
title: Python magic and remote APIs
date: '2013-02-18 08:00'
comments: true
author: Jesse Keating
categories:
  - Python
  - Developers
---
_This is a guest post by Jesse Keating, a Racker working on DevOps for Rackspace's Cloud Server products. You can read his blog at [https://raxcloud.blogspot.com/](https://raxcloud.blogspot.com) or follow _[@iamjkeating](https://twitter.com/iamjkeating)_ on Twitter._

I'm a pretty big fan of Python as a programming language. It allows me to
program by discovery, that is poke and prod at things until the work. Not
having to compile an entire program every time I change something is pretty
fantastic, as is the ability to insert a debug statement and be able to
break a program at that point, then run arbitrary python code within that
context. Pretty indispensable to how I write software.

Another thing I like about Python, which some may not, is the ability to do
magic things. Not quite so magic as [xkcd](https://xkcd.com/353/) would like
us to believe, but fun stuff indeed.
<!-- more -->
Recently one of the services at work grew a json API to bang against, and
for fun I thought I'd whip up some python to play with it. My team had a few
utility scripts that would bang on the old xmlrpc interface to get some
data, I wanted to see how much faster it was with json.

First, if you have to do anything web stuff, you really should be using the
[Requests](https://docs.python-requests.org/en/latest/) module. It is so, so
much better than using urllib(2) directly.

The API I wanted to program against had an Auth end point that would return
to you a token string. This string could be included with later API calls to
provide authentication. Requests lets you create a session object that can
have attributes that carry on to all web calls, such as a custom auth header
with a token.

```python
    resp = requests.get('https://URL/api/auth/USERNAME?password=DATA')
    resp.json()
      u'LONGSTRING'
    token = resp.json()
    session = requests.Session()
    session.headers.update({'X-Auth': token})
```

Now the session object can be used just like requests itself, and it'll
include the new header we've added. While this was neat at first, I quickly
realized that I wanted to make this session object an attribute of a more
generic object for working with the API. Each time you use session or
requests you have to fill in a url and that's tedious, so I made a python
class to handle that for me. One bit of magic I used here was a python
property.

A python property is a way populate a class attribute on the fly / as needed
without the code using your object needing to know that it's happening
behind the scenes. It's a getter/setter without having to get and set, and
it caches the value for future getting.  My class sets some data during the
init process, and creates a property for the session attribute, which can
then be used in later functions, like a login or query function.

```python
    class CServ(object):
        """A cservice object that we will interact with."""

        def __init__(self):
            self.API = 'URL'
            self.SessURL = self.API + 'session/'
            self.QAPI = self.API + 'query/'
            self._session = None

        def _login(self):
            username = myuser
            password = mypass

            data = {'password': password}
            r = requests.get('%sauth/%s' % (self.API, username), params=data)
            return r.json()

        @property
        def session(self):
            if not self._session:
                self._auth()
            return self._session

        def _auth(self):
            token = self._login()
            # Build up a session object with the token
            s = requests.Session()
            s.headers.update({'X-Auth': token})
            self._session = s

        def query(self, classname, load_arg, attributes=None):
            """Wrangle a query into the json interface.

            classname -- The name of the cserv api class to query against
            load_arg -- The argument to query for (can be a list)
            attributes -- an optional list of what to return

            returns jsonified results
            """

            # See if we have a list of load args to go through
            if type(load_arg) == list:
                # Build up a dict of the bits we need to pass in
                bits = []
                for arg in load_arg:
                    qdict = {'class': classname, 'load_arg': arg}
                    if attributes:
                        qdict['attributes'] = attributes
                    bits.append(qdict)
            else:
                bits = {'class': classname, 'load_arg': load_arg}
                if attributes:
                    bits['attributes'] = attributes

            data = self.session.post(self.QAPI, json.dumps(bits))
            return data.json()
```

With this structure we can do things like:

```python
    cserv = CServ()
    cserv.query('Computer.Computer', 432807, attributes=['name'])
      [{u'count': 1, u'load_arg': 432807, u'limit': 1, u'result':

      [{u'name': u'silly.hostname.here.com'}], u'offset': 0,

      u'class': u'Computer.Computer'}]
```

We get back a json blob that has what the API returned to us. What happened
was that the query function built up the information for the requests bit,
which was passed into `self.session.post()`. Since this was the first time
trying to access `self.session` we went through the @property tagged
`session()` function. That function determined that `self._session` was not
populated yet and called `_auth()`. `_auth()` in turn did the login dance to
generate the token, built up a requests.Session object, tweaked the header
and stuffed it into `self._session`. `session()` then returned that to the
caller thus delivering the actual session object. Magic!  The next time
session is accessed it will quickly return the value of `self._session`.
Properties are awesome and useful.

A CServ() object is okay, but not useful on its own. If I wanted to get a
bit of data about a computer and use that data numerous times I'd either
have to store a copy of the data in a local variable, or do queries each
time I wanted the data. Neither are efficient. What I really want is to be
able to create a Computer object, and from that object access attributes
directly, like say Computer.name. Here is where some more magic comes in. We
already know we can create properties to back attributes. We could go find
out what all possible things we could look up about a computer in our CServ
service, then write out properties for each of those. That... doesn't sound
fun. Particularly if you think about this CServ having Computer items,
Switch items, Account items, etc... That would be a lot of typing!

What if instead there was a way to do dynamic properties?  What if when we
tried to access `Computer.primary_ip` the code would just know to do a query
to look up the `primary_ip` attribute of a `Computer.Computer` cserv API
class?  Well we're in luck, because there is a way!

First we're going to create a subclass of CServ, CServOBJ. This class will
be a base class for any number of objects, like Computers, Accounts, etc..
We can save a lot of code duplication by putting the shared bits in
CServOBJ.

```python
    class CServOBJ(CServ):
        """A base CServ object class to build from"""
```

Right now we don't need to overload the `__init__` method, so we can dive
right into the magic. In python, when you attempt to access an object's
attribute, behind the scenes an object's `__getattr__(attribute)` method is
called. Normally you don't see it because it's all built in, but we can
override it to make attribute access do something different. In our case, we
want to do an API look up to get the value if we don't already have it, so
we'll overload the function:

```python
        def __getattr__(self, name):
            try:
                return self.__dict__[name]
            except KeyError:
                self._setAttrib(name)
                return self.__dict__[name]

        def _setAttrib(self, name):
            resp = self.session.get('%sattribute/%s/%s/%s' %
                                    (self.API, self._qclass, self._qval, name))
            resp.raise_for_status()
            setattr(self, name, resp.json())
```

Objects in python also have a built in `__dict__` that keeps track of all
the attributes. Our simple little bit of code will try to return the value
for the name of the attribute the function gets. If that attribute doesn't
exist in the built in dict, a keyerror would happen. We catch that error and
call our `_setAttrib()` function. This function is where the look up is
built up using some other class attributes we'll get to later. A session
call is made and the value is fed into the setattr python built-in. All this
work happens behind the scenes to the bit of code just trying to access the
attribute, and the lookup only happens once.  That's all we really need for
now in the base class, lets create a Computer class.

```python
    class Computer(CServOBJ):
        """A class to represent the Computer.Computer CServ API class"""

        _qclass = 'Computer.Computer'
        def __init__(self, number):
            self.number = number
            self._qval = self.number

            super(Computer, self).__init__()
```

That's all there is to it.  `_qclass` is defined as a class attribute, it
does not change per-object.  It is the class name passed into the remote
API.  The object creation takes a number, which is the identifier for
computers in our system.  It assigns that to the number attribute so that if
we reference computer.number we don't make another API call.  `_qval` is the
place holder that will be common across all the objects for what do use as a
look up key.  The parent class's init is called (which skips all the way up
to CServ) to complete the object creation.

With this setup, we can program against it very easily to access and cache
data:

    comp = Computer(432888)
    print(comp.number)
      432888
    print(comp.primary_ip)
      10.14.232.158

MAGIC!

Now if you are like me, you spend a lot of time in things like ipython or
bpython to interactively program stuff and play with objects and whatnot.
These environments provide tab completion, help functions, etc...  With our
current code though, we couldn't tab complete the available attributes.
Only the name attribute and the functions we've created would show up.  To
fix that, we need to overload the built in `__dir__` function.  This
function is used when getting a listing of what is available to an object,
`dir(object)`.  A useful exploratory tool.  ipython/bpython use this method
to see what tab completion options to provide you.  Luckily our internal
service provides an API call to get a listing of possible attributes, so we
can hook that into `__dir__`.  But of course we only want to do this API
call once (per object) so we will want to make it a property.  Since there
is nothing API class specific we can put the code into the CServOBJ class:

```python
        def __init__(self):
            self._attributes = None
            super(CServOBJ, self).__init__()

        @property
        def attribs(self):
            if not self._attribs:
                self._attribs = []
                resp = self.session.get('%sattributes/%s' %
                                        (self.API, self._qclass))
                for att in resp.json():
                    self._attribs.append(att[0])
            return self._attribs

        def __dir__(self):
            return sorted(dir(type(self)) + list(self.__dict__) + self.attribs)
```

Since we are creating a property at this level we will grow an `__init__`
function to prep for that. Then we define the attribs() function. A
short-cut is taken here, instead of calling out to some other function to
load the attributes the load is done directly.  Any time a Computer object
gets a `dir()` call our overloaded function will return a sorted list that
is the combination of the built in functions/attributes, anything that has
been added to the specific object, and the available API attributes.
Tab-completion achieved!

This has been a quick look into some of the magic you can do with Python.
It's not quite antigravity, but it is useful, and food for thought for
anybody that's programming against remote APIs.  Objects are good, objects
with dynamic attributes are better, and tab completion is icing on the cake.
Enjoy!
