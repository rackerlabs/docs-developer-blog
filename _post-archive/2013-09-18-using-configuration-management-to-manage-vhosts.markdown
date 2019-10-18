---
layout: post
title: Using configuration management to manage Vhosts
date: '2013-09-18 09:00'
comments: true
author: Welby McRoberts
published: true
categories:
  - Automation
---

One of the challenges that someone maintaining a group of webservers is faced with is keeping the vhost configuration in sync accross all machines. Much like maitaining [hosts files](https://developer.rackspace.com/blog/chef-creating-dynamic-host-files.html) this can be solved with configuration management. There are ofcourse the usual caveats, changes made outwith of the configruation management will either be overwritern, or not syncronised between hosts, so it's imperative that those "quick changes" are actually done via the configuration management system!

If we look at the main webserver platforms in use today and look at the various CM systems, we're going to see a huge number of examples for Apache, similar for nginx, but IIS is rather thin on the ground. Lets change this!

I'm going to use [SaltStack](http://www.saltstack.com/) in this example, as its my Configuration Management system of choice, however the same should be able to be done for Chef, Puppet or any other system.<!-- more -->

Our first step is going to create a state file for this. By default this is going to be in 

	/srv/salt/

If we don't already have a top.sls created lets create one. This is going match any host, usually we'd use a regex based on the name, or a grain to match, but lets keep it simple for this example. If we already have a top.sls add the vhosts state that we're going to create to the appropriate section:

	/srv/salt/top.sls

	---
	base:
	  '*':
	    - vhosts



We now need to create the vhosts state. This is to be added to /srv/salt/vhosts/init.sls
{% raw %}
	/srv/salt/top.sls

	---
	{% for id, site in salt['pillar.get']('vhosts:sites',{}).items() %}
	
	{# Apache #}
	{% if site.get('Platform') == "Apache" %}
        /var/www/{{id}}:
          file.directory:
	    - makedirs: true
	graceful-down-{{id}}:
	  cmd.run:
	    - name: service httpd graceful
	{{ id }}:
	  file:
	    - managed
	    - name: /etc/httpd/conf.d/{{ id }}
	    - source: salt://vhosts/apache.tmpl
	    - template: jinja
	    - context:
	       id: {{ id }}
	       site: {{ site }}
	    - watch_in:
	      - cmd: graceful-down-{{id}}
	{% endif %}
	
	{# IIS #}
	{% if site.get('Platform') == "IIS" %}
	c:\vhosts\{{id}}:
	  file.directory:
	    - makedirs: true
	create-apppool-{{id}}:
	  cmd.run:
	    - shell: powershell
	    - name: Set-ExecutionPolicy RemoteSigned Process -force; Import-Module WebAdministration ; New-WebAppPool -name AppPool-{{id}}; Get-WebAppPoolState AppPool-{{id}}
	    - unless: Set-ExecutionPolicy RemoteSigned Process -force; Import-Module WebAdministration ; Get-WebAppPoolState AppPool-{{id}}
	    - require:
	      - file: c:\vhosts\{{id}}
	create-vhost-{{id}}:
	  cmd.run:
	    - shell: powershell
	    - name: Set-ExecutionPolicy RemoteSigned Process -force; Import-Module WebAdministration; New-WebSite -name {{id}} -Port 80 -HostHeader {{id}} -PhysicalPath c:\vhosts\{{id}} -ApplicationPool AppPool-{{id}}
	    - require:
	      - cmd: create-apppool-{{id}}
	      - file: c:\vhosts\{{id}}
	    - unless: Set-ExecutionPolicy RemoteSigned Process -force; Import-Module WebAdministration ; Get-WebSiteState {{id}}
	{% if site.get('ServerAlias') %}
	{% for hostheader in site.get('ServerAlias') %}
	create-vhost-{{id}}-{{hostheader}}:
	  cmd.run:
	    - shell: powershell
	    - name: Set-ExecutionPolicy RemoteSigned Process -force; Import-Module WebAdministration; New-WebBinding -Name {{id}} -IP "*" -Port 80 -Protocol http -HostHeader 	{{hostheader}}
	    - require:
	      - cmd: create-vhost-{{id}}
	    - unless: Set-ExecutionPolicy RemoteSigned Process -force; Import-Module WebAdministration; Get-WebBinding {{id}} \| select-string {{hostheader}}
	{% endfor %}
	{% endif %}
	{% endif %}
	{% endfor %}
{% endraw %}



The next step will be to create the templatefile used for Apache VHosts
	/srv/salt/vhosts/apache.tmpl

	---
        {% raw %}
	{# Default values here, so the template looks nicer! #}
	{% set sitename = site.get('ServerName', id) %}
	{% set vals = {
	    'interface': site.get('interface', '*'),
	    'port': site.get('port', '80'),
	    'ServerName': sitename,
	    'ServerAdmin': site.get('ServerAdmin', 'webmaster@{0}'.format(sitename)),
	    'LogLevel': site.get('LogLevel', 'warn'),
	    'ErrorLog': site.get('ErrorLog', '/var/log/httpd/{0}-error.log'.format(sitename)),
	    'CustomLog': site.get('ErrorLog', '/var/log/httpd/{0}-access.log'.format(sitename)),
	    'DocumentRoot': site.get('DocumentRoot', '/var/www/{0}'.format(sitename)),
	    'Directory_default': '/var/www/{0}'.format(sitename),
	    'Directory': {
	        'Options': '-Indexes FollowSymLinks',
	        'Order': 'allow,deny',
	        'Allow': 'from all',
	        'AllowOverride': 'None',
	    },
	} %}
	
	<VirtualHost {{ vals.interface }}:{{ vals.port }}>
	    ServerName {{ vals.ServerName }}
	    ServerAlias {% for ServerAlias in site.get('ServerAlias', {}).items() %} {{ServerAlias}} www.{{ServerAlias}}{% endfor %}
	    ServerAdmin {{ vals.ServerAdmin }}
	    LogLevel {{ vals.LogLevel }}
	    ErrorLog {{ vals.ErrorLog }}
	    CustomLog {{ vals.CustomLog }}
	
	    DocumentRoot {{ vals.DocumentRoot }}
	
	    {% for path, dir in site.get('Directory', {}).items() %}
	    {% set dvals = {
	        'Options': dir.get('Options', vals.Directory.Options),
	        'Order': dir.get('Order', vals.Directory.Order),
	        'Allow': dir.get('Order', vals.Directory.Allow),
	        'AllowOverride': dir.get('Order', vals.Directory.AllowOverride),
	    } %}
	
	    {% if path == 'default' %}{% set path = vals.Directory_default %}{% endif %}
	
	    <Directory "{{ path }}">
	        Options {{ dvals.Options }}
	        Order {{ dvals.Order }}
	        Allow {{ dvals.Allow }}
	        AllowOverride {{ dvals.AllowOverride }}
	
	    </Directory>
	    {% endfor %}
	
	</VirtualHost>
        {% endraw %}

At this point, you now have a way of deploying vhosts to all servers, however there are no vhosts configured! In Salt we have the ability to have the minion collect data from  a "pillar". For this example i'm going to do this with a simple yaml file on the salt master, however this can be collected in a multitude of ways, mongodb collections, ldap or indeed anyway in which you write a ext_pillar. I've recently written one to get information from a external webservice for example. The below is an example of a configuration, but is not using all of the values avaialble in the state above

        {% raw %}
	/srv/pillar/top.sls
        --------
        base:
          '*':
            - vhost

	/srv/pillar/vhost.sls
        --------
	vhosts:
	  sites:
	    example.com:
	      ServerAlias:
	        - test
	        - test2
	      Platform: IIS
	    example.net:
	      Platform: Apache
	    whmcr.com:
	      Platform: Apache
        {% endraw %}

Now that we have the pillar returning the data to the minion, the last thing we'll need to do is actually apply this configuration! As this is being handled in a state this can easily be applied with the salt command

	salt '*' state.highstate


After this has completed, you're webservers will now be configured with the same vhosts!

###About the Author

Welby has worked at Rackspace in the UK as a Lead Infrastructure Engineer since 2009. Previously he's worked in a variety of roles within the UK ranging from Web Development to Systems Administration to Systems Engineering. You can find him on [Google+](https://plus.google.com/116366454309947618934/) or follow him on twitter [@welbymcroberts](https://twitter.com/welbymcroberts)
