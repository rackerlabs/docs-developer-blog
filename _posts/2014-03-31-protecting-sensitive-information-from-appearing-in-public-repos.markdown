---
layout: post
title: Protecting sensitive information from appearing in public repos
date: '2014-04-15 10:30'
comments: true
author: Sri Rajan
published: true
categories:
  - Security
---


In the last several years and with the advent of social coding sites like
GitHub, there has been an increasing openness in code sharing. This is great
on so many levels as it promotes the open source model, and in general is a
nice thing.

One security side effect has been the accidental disclosure of sensitive
information in the code that is shared publically.  This problem existed
before with things like database or SMTP passwords in configuration files
but in the world of cloud and API keys this problem increases in its severity.

Whereas database servers were generally well protected and so even accidentally
revealing the password was not the worst thing to happen, exposing API keys on
public repositories has serious consequences. You have given someone the keys
to your whole cloud kingdom. With these keys one can spin up servers, view
your data, upload illegal data and the list goes on. Hackers are most likely
searching on these repositories for such information.

We recently had a good debate in the Rackspace tech community on this topic
and this post tries to present some best practices and also some ways to
clean up should it happen.

<!-- more -->

### Prevention is better than cure


With a bit of discipline you can avoid this in the first place. Commits to public version control sites are VERY difficult, if not impossible to ever remove.

 * __Separate files__


Define a strict naming convention for sensitive files and use global git ignore to avoid them being included. Separate your global configuration file from the file that contains sensitive info like API keys. In terms of convention, you can also define a variable naming convention for such values. This would allow you to do simple searches for them and weed them out. The method requires discipline and so you need to get your team fully on board with the idea and get into the habit of doing it.  You could also use pre-commit scripts to enforce your naming convention.


 * __Use environment variables__

Never store the values in a variable. Just get your programming language to pull it off system variables.

For e.g. in Python you can do this

{% codeblock lang:python %}
# cloud auth data will be pulled from environment
cloud_user = os.environ['OS_USERNAME']
cloud_api_key = os.environ['OS_PASSWORD']
cloud_region = os.environ['OS_REGION_NAME'].upper()
cloud_tenant = os.environ['OS_TENANT_NAME']

pyrax.set_setting("identity_type", "rackspace")
pyrax.set_setting("region", cloud_region)
try:
    pyrax.set_credentials(cloud_user,
                          cloud_api_key,
                          region=cloud_region)
except pyrax.exc.AuthenticationFailed:
    print "Pyrax auth failed"
{% endcodeblock %}

This is possible in all modern day languages.  The only places where this cannot be done is things like Yaml files which are more static. Even with Yaml you could create a wrapper that read environment variable and generates the Yaml file. The key here would be to *make sure* that the Yaml file is your public repository otherwise it defeats the purpose.

As a further protection you can use the OS level keyrings to store these environment variables. Linux has [Gnome Keyring](https://wiki.gnome.org/Projects/GnomeKeyring/KeyringIntro) , Mac OSX has an equivalent [KeyChain](https://developer.apple.com/library/mac/documentation/security/Conceptual/keychainServConcepts/01introduction/introduction.html) option and for Windows environments, you can use [Credentials Management Functions](http://msdn.microsoft.com/en-us/library/aa374731%28v=VS.85%29.aspx#credentials_management_functions) from within your code. The keyrings provide an additional level of security in protecting the information.


  * **Stay private**

Use private Git Hub repositories or Bit Bucket and keep repos private. This is probably the least secure because that means the file is living in clear text somewhere and you never know when this repo or file gets exposed to the public. Even if you are operating in private or company only repository it is still good to avoid storing such data in clear text.


  * **Use git-crypt**

git-crypt enables transparent encryption and decryption of files in a git repository. Files that you choose to protect are encrypted when committed, and decrypted when checked out. git-crypt lets you freely share a repository containing a mix of public and private content. See ([Git Crypt](https://www.agwa.name/projects/git-crypt/))

git-crypt is not designed to encrypt an entire repository. Also note that git-crypt usese git's smudge and clean features (ref ([Git Attributes](http://git-scm.com/docs/gitattributes)), which was not the original intent of those features.  git-crypt does not itself provide any authentication. It assumes that either the master copy of your repository is stored securely, or that you are using git's existing facilities to ensure integrity (signed tags, remembering commit hashes, etc.). It maybe worth noting that git-crypt uses deterministic encryption which is something that should be taken into consideration.


### Accidents happen


There will always be cases where you accidentally commit a file with such information or you find that in an audit. There are few things you can do here


 * Change the exposed passwords or keys. This is a must do, must be done immediately and the best way to ensure the security.
 * If your internal policy requires notification of such incidents to the security team, make sure you do that. Often these teams have additional tools and know-how on how to tackle the incident and limit damage.
 * Fix the problem that caused it. Implement or follow one of the best practices above.
 * Cleaning up from git - If using Git remove the file from history and add it to the. gitignore to ensure it is not accidentally re-committed. Here's a step by step guide from GitHub on [Removing Sensitive Data](https://help.github.com/articles/remove-sensitive-data)

### Auditing

It would be nice to implement a scanner of sorts to actively look for these in your code repositories. At the least, you can run searches on GitHub to look for known patterns.

Here's an example of searching for the string rackspace_api_key on GitHub.

[Git Search Example](https://github.com/search?p=2&q=rackspace_api_key&ref=searchresults&type=Code) is a good such example.

A pre-commit scanner that checks for these things and possibly has a list of the keys and passwords to check as well will be a good add-on. An importantly don't check in the code for the scanner/hook on a public site as this has the very keys you need to protect :-)


### Authors and credits

* Sriram(Sri) Rajan - Principal Engineer, Rackspace
* Christian Ashby- Senior Solutions Engineer, Rackspace
* Greg Anderson - Software Security Engineer, Rackspace


