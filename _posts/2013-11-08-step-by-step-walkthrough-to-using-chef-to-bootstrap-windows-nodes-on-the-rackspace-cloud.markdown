---
layout: post
title: Step-by-step walkthrough to using Chef to bootstrap Windows nodes on the Rackspace Cloud
date: '2013-11-08 09:30'
comments: true
author: Nico Engelen
published: true
categories:
  - Chef
  - Configuration Management
  - Cloud Servers
---

If you are a frequent reader of this blog you will have seen Hart's posts about "Cooking with Chef":

* [Part one](http://devops.rackspace.com/cooking-with-chef.html): Introduction to Chef
* [Part two](http://devops.rackspace.com/cooking-with-chef2.html): Cookbooks and Deploying with Knife
* [Part three](http://devops.rackspace.com/cooking-with-chef3.html): Installing your own Open Source Chef

Further to these there are also a lot of tutorials on the internet. Most of
them seem to focus on using chef to deploy/manage Linux servers but you will
have a hard time to find a lot for doing the same on Windows Servers (Yes,
Windows as in Microsoft Windows).

I have therefore sat down and put together a detailed step-by-step walkthrough
that will guide you through installing your own Open Source Chef Server on a
Rackspace Cloud Server running CentOS 6.4, installing the knife-windows
plugin and then spinning up, bootstrapping and installing IIS on a Windows
Server 2012 Rackspace Cloud Server without logging on to it once.
Read on, if you dare...

<!-- more -->

### Acknowledgements

For the simplicity of this walkthrough, I am using a single CentOS server to
act as Chef Server and Chef Workstation at the same time. I have also used the
root account on this server to get the fiddling around with su and sudo out
of the way. I am well aware that this might not be following best practices
and in a perfect world you'd be using different servers for Chef Server and
Chef Workstation and of course never log on as the root user. Further, I have
partly sanitized the output as the IP of the chef server is still in use.

I have therefore replaced all occurences of it with <IP_ADDR>. Please just
replace that with the IP address that the nova show command is returning for
you. Having said that, let's get cracking.

### Prerequisites

You will obviously need a Rackspace Cloud Account for this. If you haven't
got one yet, go sign up for it [here](https://developer.rackspace.com/devtrial/),
which includes a 300$ developer discount.

Once you have an account, log into the Control Panel, spin up a Cloud Server
running the Linux distribution of your choice and install the novaclient on it
following these [instructions](http://www.rackspace.com/knowledge_center/article/installing-python-novaclient-on-linux-and-mac-os)
so you can spin up Cloud Servers from the command line. I called my server
nova-serv but feel free to call it whatever you like. Once that's done,
you're ready to go.

### Spin up the Cloud Server instance

First of all, let's spin up a new Rackspace Cloud Server, running CentOS 6.4
with 512MB of RAM. While we're at it, let's also inject our SSH RSA public key
into the list of authorized keys for the root user

    [nico@nova-serv ~]$ nova boot --image e0ed4adb-3a00-433e-a0ac-a51f1bc1ea3d --flavor 2 --file "/root/.ssh/authorized_keys=.ssh/id_rsa.pub" chef-serv
    +------------------------+--------------------------------------+
    | Property               | Value                                |
    +------------------------+--------------------------------------+
    | status                 | BUILD                                |
    | updated                | 2013-07-31T07:36:29Z                 |
    | hostId                 |                                      |
    | key_name               | None                                 |
    | image                  | CentOS 6.4                           |
    | OS-EXT-STS:task_state  | scheduling                           |
    | OS-EXT-STS:vm_state    | building                             |
    | flavor                 | 512MB Standard Instance              |
    | id                     | 7052aa1a-5714-47f2-abce-bd389d876d00 |
    | user_id                | 10017907                             |
    | name                   | chef-serv                            |
    | adminPass              | o4oviBbrDUmE                         |
    | tenant_id              | 10029688                             |
    | created                | 2013-07-31T07:36:29Z                 |
    | OS-DCF:diskConfig      | AUTO                                 |
    | accessIPv4             |                                      |
    | accessIPv6             |                                      |
    | progress               | 0                                    |
    | OS-EXT-STS:power_state | 0                                    |
    | metadata               | {}                                   |
    +------------------------+--------------------------------------+

Check back after a few minutes and the build process shoud have completed

    [nico@chef-serv ~]$ nova show 7052aa1a-5714-47f2-abce-bd389d876d00
    +---------------------------------------------------------------------+
    | Property               | Value                                      |
    +------------------------+--------------------------------------------+
    | status                 | ACTIVE                                     |
    | updated                | 2013-07-31T07:39:45Z                       |
    | hostId                 | 53ae616f8c649f7c6db25980e1b8a9827919bde4...|
    | private network        |                                            |
    | key_name               | None                                       |
    | image                  | CentOS 6.4                                 |
    | OS-EXT-STS:task_state  | None                                       |
    | OS-EXT-STS:vm_state    | active                                     |
    | public network         | <IP_ADDR>                                  |
    | flavor                 | 512MB Standard Instance (2)                |
    | id                     | 7052aa1a-5714-47f2-abce-bd389d876d00       |
    | user_id                | 10017907                                   |
    | name                   | chef-serv                                  |
    | created                | 2013-07-31T07:36:29Z                       |
    | tenant_id              | 10029688                                   |
    | OS-DCF:diskConfig      | AUTO                                       |
    | accessIPv4             | <IP_ADDR>                                  |
    | accessIPv6             |                                            |
    | progress               | 100                                        |
    | OS-EXT-STS:power_state | 1                                          |
    | metadata               | {}                                         |
    +------------------------+--------------------------------------------+

### Spin up the Windows Cloud Server we are bootstrapping later

Create a bootstrap.cmd in the current directory and make put the following
content in. Make sure to change the IP (<IP_ADDR>) and the hostname (chef-serv)
to reflect your values. Also note that there are only two lines in the file
(depending on you screen resolution the first line might wrap) with the first
line containing the two netsh command connected with an ampersand. We will
inject this file into our Windows Server so that it will be executed after the
first boot and accomplish the following things:

- Start the windows time service (w32time)
- Set the windows times service to sync time from the uk.pool.ntp..org time servers
- Sync the time (chef is very particular about the time being correct and only allows a couple of minutes of skew between the server and the node)
- Open port 5985 (winrm) on the firewal
- Add an entry to the hosts file of our Windows Server as chef-client will try and connect back to our chef-server via its name

```
    [nico@nova-serv ~]$ cat bootstrap.cmd
    net start w32time
    w32tm /config /manualpeerlist:"0.uk.pool.ntp.org 1.uk.pool.ntp.org 2.uk.pool.ntp.org 3.uk.pool.ntp.org" /syncfromflags:manual /reliable:yes /update
    w32tm /resync
    netsh advfirewall firewall set rule group="remote administration" new enable=yes & netsh advfirewall firewall add rule name="WinRM Port" dir=in action=allow protocol=TCP remoteip=<IP_ADDR> localport=5985
    echo <IP_ADDR> chef-serv >> C:\Windows\system32\drivers\etc\hosts
```

And now boot a Cloud Server from the Windows Server 2012 image injecting our bootstrap.cmd into the load point for files auto-executed after bootup (C:\cloud-automation\bootstrap.cmd). This will take a while longer to finish so we leave it running while we install Chef Server and Chef Client on our chef server. We will check back on the progress later. Don't forget to take a note of the `adminPass`

	[nico@nova-serv ~]$ nova boot --image f7f274f3-5d04-4a2c-9159-29b9d295cf76 --flavor 3 --file "C:\\cloud-automation\\bootstrap.cmd=bootstrap.cmd" chef-win
	+------------------------+--------------------------------------+
	| Property               | Value                                |
	+------------------------+--------------------------------------+
	| status                 | BUILD                                |
	| updated                | 2013-07-31T07:41:43Z                 |
	| hostId                 |                                      |
	| key_name               | None                                 |
	| image                  | Windows Server 2012                  |
	| OS-EXT-STS:task_state  | scheduling                           |
	| OS-EXT-STS:vm_state    | building                             |
	| flavor                 | 1GB Standard Instance                |
	| id                     | 7d4b6d0a-8b90-4f18-ad76-548f4a14d6d7 |
	| user_id                | 10017907                             |
	| name                   | chef-win                             |
	| adminPass              | A7not3si5ELo                         |
	| tenant_id              | 10029688                             |
	| created                | 2013-07-31T07:41:43Z                 |
	| OS-DCF:diskConfig      | MANUAL                               |
	| accessIPv4             |                                      |
	| accessIPv6             |                                      |
	| progress               | 0                                    |
	| OS-EXT-STS:power_state | 0                                    |
	| metadata               | {}                                   |
	+------------------------+--------------------------------------+

### Install Chef Server on our CentOS server

OK, let's get onto the CentOS server we spun up above, this should be trusting our SSH key so no need to enter a password.

    [nico@nova-serv ~]$ ssh root@<IP_ADDR>
    The authenticity of host '<IP_ADDR> (<IP_ADDR>)' can't be established.
    RSA key fingerprint is d2:40:af:96:47:fa:67:ec:5c:20:b0:d5:b9:14:ae:e0.
    Are you sure you want to continue connecting (yes/no)? yes
    Warning: Permanently added '<IP_ADDR>' (RSA) to the list of known hosts.

OK, first of all, let's install Ruby. The latest version available via yum is 1.8.7, however, the knife-windows plugin requires at least 1.9.1 so we are going to install rvm which will ask us to source /etc/profile.d/rvm.sh

    [root@chef-serv ~]# curl -L https://get.rvm.io | bash
    [root@chef-serv ~]# source /etc/profile.d/rvm.sh

Now use rvm to install the latest ruby version available (1.9.3 at the time of writing this)

    [root@chef-serv ~]# rvm install 1.9.3

Next, we will download the Chef Server rpm package from [here](http://www.opscode.com/chef/install/ "Opscode download link for chef open-source"), install it and do the initial server configuration

    [root@chef-serv ~]# wget https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/chef-server-11.0.8-1.el6.x86_64.rpm
    [root@chef-serv ~]# rpm --install ./chef-server-11.0.8-1.el6.x86_64.rpm
    [root@chef-serv ~]# chef-server-ctl reconfigure

Once that's all been done, we need to open ports 80 (http) and 443 (https) on the host firewall so we can actually connect to our Chef Server. Don't forget to save your iptables config so it persists a reboot

    [root@chef-serv ~]# iptables -I INPUT 1 -p tcp -m tcp --dport 80 -j ACCEPT
    [root@chef-serv ~]# iptables -I INPUT 1 -p tcp -m tcp --dport 443 -j ACCEPT
    [root@chef-serv ~]# service iptables save

**IMPORTANT: Log in to your server via https at this point (i.e. https://<IP_ADDR>) and change the default admin password (or someone else might do that for you)**

**NOTE: as an alternative to using the IP address you can also append the following line to your hosts file: `<IP_ADDR> chef-serv` which allows you to use the hostname in the browser rather than the IP.**

Next, use gem to install chef rather than following the instructions on opscode's website.

	[root@chef-serv ~]# gem install chef

We will also need git so install it as well. Straight after, clone the chef-repo into root's home dir

	[root@chef-serv ~]# yum install git -y
	[root@chef-serv ~]# git clone https://github.com/opscode/chef-repo

OK, let's do the initial configuration for knife. This will do a couple of things for us:

- it will generate a knife.rb file in /root/.chef/
- it will point the chef-repo to /root/chef-repo
- it will create an administrative user on the chef server with the same name as the currently logged on user
- it will place a pem file for that new administrative user containing the private key in /root/.chef/

Just run the below command and leave all default values as they are.

	[root@chef-serv ~]# knife configure -i -r ~/chef-repo/
	WARNING: No knife configuration file found
	Where should I put the config file? [/root/.chef/knife.rb]
	Please enter the chef server URL: [https://chef-serv:443]
	Please enter a name for the new user: [root]
	Please enter the existing admin name: [admin]
	Please enter the location of the existing admin's private key: [/etc/chef-server/admin.pem]
	Please enter the validation clientname: [chef-validator]
	Please enter the location of the validation key: [/etc/chef-server/chef-validator.pem]
	Creating initial API user...
	Please enter a password for the new user:
	Created user[root]
	Configuration file written to /home/root/.chef/knife.rb

Almost there, next up is installing knife-windows directly from the github repo it is on. For that, we will have to install a couple of necessary dependencies. After that, we'll clone the github repo for knife-windows, then checkout a specific commit (we're doing that because the current latest version of knife-windows - 0.5.14.rc.1 - seems broken), build a gem from that code using rake and then install the gem using gem.

	[root@chef-serv ~]# yum install ruby-devel libxml2-devel libxslt-devel -y
	[root@chef-serv knife-windows]# cd knife-windows
	[root@chef-serv knife-windows]# git clone https://github.com/opscode/knife-windows.git
	[root@chef-serv knife-windows]# git checkout 95d79e32eb47db95471726c1460cc561caaef6d7
	[root@chef-serv knife-windows]# rake build
	[root@chef-serv knife-windows]# gem install pkg/knife-windows-0.5.13.gem
	[root@chef-serv knife-windows]# cd ..

Done. You should now have a Chef Server running as well as the chef-client installed. On top of that, you will also have the knife windows commands. Let's quickly verify that. Note that the first command will actually throw an error but then list which Windows commands knife will understand.

	[root@chef-serv ~]# knife windows
	FATAL: Cannot find sub command for: 'windows'
	Available windows subcommands: (for details, knife SUB-COMMAND --help)

	** WINDOWS COMMANDS **
	knife bootstrap windows winrm FQDN (options)
	knife bootstrap windows ssh FQDN (options)
	knife winrm QUERY COMMAND (options)

	[root@chef-serv ~]# knife winrm --help
	knife winrm QUERY COMMAND (options)
	    -a, --attribute ATTR             The attribute to use for opening the connection - default is fqdn
	    -f CA_TRUST_FILE,                The Certificate Authority (CA) trust file used for SSL transport
	        --ca-trust-file
	    -s, --server-url URL             Chef Server URL
	    -k, --key KEY                    API Client Key
	        --[no-]color                 Use colored output, defaults to false on Windows, true otherwise
	    -c, --config CONFIG              The configuration file to use
	        --defaults                   Accept default values for all questions
	    -d, --disable-editing            Do not open EDITOR, just accept the data as is
	    -e, --editor EDITOR              Set the editor to use for interactive commands
	    -E, --environment ENVIRONMENT    Set the Chef environment
	    -F, --format FORMAT              Which format to use for output
	        --identity-file IDENTITY_FILE
	                                     The SSH identity file used for authentication
	    -i, --keytab-file KEYTAB_FILE    The Kerberos keytab file used for authentication
	    -R KERBEROS_REALM,               The Kerberos realm used for authentication
	        --kerberos-realm
	    -S KERBEROS_SERVICE,             The Kerberos service used for authentication
	        --kerberos-service
	    -m, --manual-list                QUERY is a space separated list of servers
	    -u, --user USER                  API Client Username
	        --print-after                Show the data after a destructive operation
	        --returns CODES              A comma delimited list of return codes which indicate success
	    -V, --verbose                    More verbose output. Use twice for max verbosity
	    -v, --version                    Show chef version
	    -P, --winrm-password PASSWORD    The WinRM password
	    -p, --winrm-port PORT            The WinRM port, by default this is 5985
	   -t, --winrm-transport TRANSPORT  The WinRM transport type.  valid choices are [ssl, plaintext]
	    -x, --winrm-user USERNAME        The WinRM username
	    -y, --yes                        Say yes to all prompts for confirmation
	    -h, --help                       Show this message


### Bootstrap our Windows Server with knife

Quickly log out to check on the status of our Cloud Windows Server build (I'll be back).

	[root@chef-serv ~]# logout
	Connection to <IP_ADDR> closed.

Ask nova if our Server has finished building. As stated above, Windows Server take considerably longer than Linux servers to build. Please also note, that even if nova reports completion, it will take another few minutes until the server is actually remotely accessible as there are quite a few post-build tasks being executed on the first boot.

	[nico@nova-serv ~]$ nova show 7d4b6d0a-8b90-4f18-ad76-548f4a14d6d7
	+------------------------+--------------------------------------------+
	| Property               | Value                                      |
	+------------------------+--------------------------------------------+
	| status                 | ACTIVE                                     |
	| updated                | 2013-07-31T07:55:39Z                       |
	| hostId                 | de04c82acafec8d224fe98d92a7f58049bf57d26...|
	| private network        | 10.178.197.5                               |
	| key_name               | None                                       |
	| image                  | Windows Server 2012                        |
	| OS-EXT-STS:task_state  | None                                       |
	| OS-EXT-STS:vm_state    | active                                     |
	| public network         | 95.138.188.93                              |
	| flavor                 | 1GB Standard Instance (3)                  |
	| id                     | 7d4b6d0a-8b90-4f18-ad76-548f4a14d6d7       |
	| user_id                | 10017907                                   |
	| name                   | chef-win                                   |
	| created                | 2013-07-31T07:41:56Z                       |
	| tenant_id              | 10029688                                   |
	| OS-DCF:diskConfig      | MANUAL                                     |
	| accessIPv4             | 95.138.188.93                              |
	| accessIPv6             | 2a00:1a48:7805:111:cf5e:1242:ff08:6b8e     |
	| progress               | 100                                        |
	| OS-EXT-STS:power_state | 1                                          |
	| metadata               | {}                                         |
	+------------------------+--------------------------------------------+

So back to our Chef Server...

	[nico@nova-serv ~]$ ssh root@<IP_ADDR>

Let's quickly check, if our Windows server is listening on 5985:

	[root@chef-serv3 ~]# telnet 95.138.188.93 5985
	Trying 95.138.188.93...
	Connected to 95.138.188.93.
	Escape character is '^]'.
	^]
	telnet> quit

...and straight into bootstrapping (with an empty run-list for now to keep things simple)

	[root@chef-serv ~]# knife bootstrap windows winrm 95.138.188.93 -x Administrator -P A7not3si5ELo
	Bootstrapping Chef on 95.138.188.93
	95.138.188.93 "Rendering 'C:\Users\ADMINI~1\AppData\Local\Temp\bootstrap-8463-1375259447.bat' chunk 1"
	95.138.188.93 "Rendering 'C:\Users\ADMINI~1\AppData\Local\Temp\bootstrap-8463-1375259447.bat' chunk 2"
	95.138.188.93 "Rendering 'C:\Users\ADMINI~1\AppData\Local\Temp\bootstrap-8463-1375259447.bat' chunk 3"
	95.138.188.93 "Rendering 'C:\Users\ADMINI~1\AppData\Local\Temp\bootstrap-8463-1375259447.bat' chunk 4"
	95.138.188.93 "Rendering 'C:\Users\ADMINI~1\AppData\Local\Temp\bootstrap-8463-1375259447.bat' chunk 5"
	95.138.188.93 "Rendering 'C:\Users\ADMINI~1\AppData\Local\Temp\bootstrap-8463-1375259447.bat' chunk 6"
	95.138.188.93 "Rendering 'C:\Users\ADMINI~1\AppData\Local\Temp\bootstrap-8463-1375259447.bat' chunk 7"
	95.138.188.93 "Rendering 'C:\Users\ADMINI~1\AppData\Local\Temp\bootstrap-8463-1375259447.bat' chunk 8"
	95.138.188.93 "Rendering 'C:\Users\ADMINI~1\AppData\Local\Temp\bootstrap-8463-1375259447.bat' chunk 9"
	95.138.188.93
	95.138.188.93 C:\Users\Administrator>
	95.138.188.93 mkdir C:\chef
	95.138.188.93
	95.138.188.93 C:\Users\Administrator>(
	95.138.188.93 echo.url = WScript.Arguments.Named("url")
	95.138.188.93  echo.path = WScript.Arguments.Named("path")
	95.138.188.93  echo.proxy = null
	95.138.188.93  echo.Set objXMLHTTP = CreateObject("MSXML2.ServerXMLHTTP")
	95.138.188.93  echo.Set wshShell = CreateObject( "WScript.Shell" )
	95.138.188.93  echo.Set objUserVariables = wshShell.Environment("USER")
	95.138.188.93  echo.
	95.138.188.93  echo.'http proxy is optional
	95.138.188.93  echo.'attempt to read from HTTP_PROXY env var first
	95.138.188.93  echo.On Error Resume Next
	95.138.188.93  echo.
	95.138.188.93  echo.If NOT (objUserVariables("HTTP_PROXY") = "") Then
	95.138.188.93  echo.proxy = objUserVariables("HTTP_PROXY")
	95.138.188.93  echo.
	95.138.188.93  echo.'fall back to named arg
	95.138.188.93  echo.ElseIf NOT (WScript.Arguments.Named("proxy") = "") Then
	95.138.188.93  echo.proxy = WScript.Arguments.Named("proxy")
	95.138.188.93  echo.End If
	95.138.188.93  echo.
	95.138.188.93  echo.If NOT isNull(proxy) Then
	95.138.188.93  echo.'setProxy method is only available on ServerXMLHTTP 6.0+
	95.138.188.93  echo.Set objXMLHTTP = CreateObject("MSXML2.ServerXMLHTTP.6.0")
	95.138.188.93  echo.objXMLHTTP.setProxy 2, proxy
	95.138.188.93
	95.138.188.93  echo.End If
	95.138.188.93  echo.
	95.138.188.93  echo.On Error Goto 0
	95.138.188.93  echo.
	95.138.188.93  echo.objXMLHTTP.open "GET", url, false
	95.138.188.93  echo.objXMLHTTP.send()
	95.138.188.93  echo.If objXMLHTTP.Status = 200 Then
	95.138.188.93  echo.Set objADOStream = CreateObject("ADODB.Stream")
	95.138.188.93  echo.objADOStream.Open
	95.138.188.93  echo.objADOStream.Type = 1
	95.138.188.93  echo.objADOStream.Write objXMLHTTP.ResponseBody
	95.138.188.93  echo.objADOStream.Position = 0
	95.138.188.93  echo.Set objFSO = Createobject("Scripting.FileSystemObject")
	95.138.188.93  echo.If objFSO.Fileexists(path) Then objFSO.DeleteFile path
	95.138.188.93  echo.Set objFSO = Nothing
	95.138.188.93  echo.objADOStream.SaveToFile path
	95.138.188.93  echo.objADOStream.Close
	95.138.188.93  echo.Set objADOStream = Nothing
	95.138.188.93  echo.End if
	95.138.188.93  echo.Set objXMLHTTP = Nothing
	95.138.188.93 ) 1>C:\chef\wget.vbs
	95.138.188.93
	95.138.188.93 C:\Users\Administrator>(
	95.138.188.93 echo.param(
	95.138.188.93  echo.   [String] $remoteUrl,
	95.138.188.93  echo.   [String] $localPath
	95.138.188.93  echo.)
	95.138.188.93  echo.
	95.138.188.93  echo.$webClient = new-object System.Net.WebClient;
	95.138.188.93  echo.
	95.138.188.93  echo.$webClient.DownloadFile($remoteUrl, $localPath);
	95.138.188.93 ) 1>C:\chef\wget.ps1
	95.138.188.93
	95.138.188.93 C:\Users\Administrator>FOR /F "tokens=1-8 delims=.[] " %A IN ('ver') DO (
	95.138.188.93
	95.138.188.93
	95.138.188.93
	95.138.188.93 )
	95.138.188.93
	95.138.188.93 C:\Users\Administrator>(
	95.138.188.93
	95.138.188.93
	95.138.188.93
	95.138.188.93 )
	95.138.188.93
	95.138.188.93 C:\Users\Administrator>goto Version6.2
	95.138.188.93
	95.138.188.93 C:\Users\Administrator>goto architecture
	95.138.188.93
	95.138.188.93 C:\Users\Administrator>goto ArchitectureAMD64
	95.138.188.93
	95.138.188.93 C:\Users\Administrator>goto install
	95.138.188.93
	95.138.188.93 C:\Users\Administrator>cscript /nologo C:\chef\wget.vbs /url:"https://www.opscode.com/chef/download?p=windows&pv=2012&m=x86_64" /path:"C:\Users\ADMINI~1\AppData\Local\Temp\chef-client-latest.msi"
	95.138.188.93 CScript Error: Execution of the Windows Script Host failed. (0x800A0007)
	95.138.188.93 Warning: Failed to download "https://www.opscode.com/chef/download?p=windows&pv=2012&m=x86_64" to "C:\Users\ADMINI~1\AppData\Local\Temp\chef-client-latest.msi"
	95.138.188.93 Warning: Retrying download with PowerShell if available
	95.138.188.93 Download succeeded
	95.138.188.93
	95.138.188.93 C:\Users\Administrator>msiexec /qb /i "C:\Users\ADMINI~1\AppData\Local\Temp\chef-client-latest.msi"
	95.138.188.93 Writing validation key...
	95.138.188.93 Validation key written.
	95.138.188.93
	95.138.188.93 C:\Users\Administrator>(
	95.138.188.93 echo.log_level        :info
	95.138.188.93  echo.log_location     STDOUT
	95.138.188.93  echo.
	95.138.188.93  echo.chef_server_url  "https://chef-serv:443"
	95.138.188.93  echo.validation_client_name "chef-validator"
	95.138.188.93  echo.client_key        "c:/chef/client.pem"
	95.138.188.93  echo.validation_key    "c:/chef/validation.pem"
	95.138.188.93  echo.
	95.138.188.93  echo.file_cache_path   "c:/chef/cache"
	95.138.188.93  echo.file_backup_path  "c:/chef/backup"
	95.138.188.93  echo.cache_options     ({:path => "c:/chef/cache/checksums", :skip_expires => true})
	95.138.188.93  echo.
	95.138.188.93  echo.# Using default node name (fqdn)
	95.138.188.93 ) 1>C:\chef\client.rb
	95.138.188.93
	95.138.188.93 C:\Users\Administrator>(echo.{"run_list":[]}) 1>C:\chef\first-boot.json
	95.138.188.93
	95.138.188.93 C:\Users\Administrator>SET "PATH=C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\opscode\chef\bin;C:\opscode\chef\embedded\bin;C:\ruby\bin;C:\opscode\chef\bin;C:\opscode\chef\embedded\bin"
	95.138.188.93
	95.138.188.93 C:\Users\Administrator>chef-client -c c:/chef/client.rb -j c:/chef/first-boot.json -E _default
	95.138.188.93 [2013-07-31T08:31:41+00:00] INFO: *** Chef 11.6.0 ***
	95.138.188.93 [2013-07-31T08:31:49+00:00] INFO: Client key c:/chef/client.pem is not present - registering
	95.138.188.93 [2013-07-31T08:31:59+00:00] INFO: Setting the run_list to [] from JSON
	95.138.188.93 [2013-07-31T08:31:59+00:00] INFO: Run List is []
	95.138.188.93 [2013-07-31T08:31:59+00:00] INFO: Run List expands to []
	95.138.188.93 [2013-07-31T08:31:59+00:00] INFO: Starting Chef Run for CHEF-WIN
	95.138.188.93 [2013-07-31T08:31:59+00:00] INFO: Running start handlers
	95.138.188.93 [2013-07-31T08:31:59+00:00] INFO: Start handlers complete.
	95.138.188.93 [2013-07-31T08:31:59+00:00] INFO: Loading cookbooks []
	95.138.188.93 [2013-07-31T08:31:59+00:00] WARN: Node CHEF-WIN has an empty run list.
	95.138.188.93 [2013-07-31T08:32:00+00:00] INFO: Chef Run complete in 1.466414 seconds
	95.138.188.93 [2013-07-31T08:32:00+00:00] INFO: Running report handlers
	95.138.188.93 [2013-07-31T08:32:00+00:00] INFO: Report handlers complete

That went through fine but as you can see, there is a warning about the empty run_list.
##Installing IIS
Time to do something useful now and install IIS.
First of all, download the cookbooks that are required for the iis cookbook (i.e. webpi, windows and chef_handler)

	[root@chef-serv ~]# knife cookbook site install webpi
	[root@chef-serv ~]# knife cookbook site install windows
	[root@chef-serv ~]# knife cookbook site install chef_handler

Download the iis community cookbook itself and upload all of the cookbooks just downloaded to our Chef Server so we can use them.

	[root@chef-serv ~]# knife cookbook site install iis
	[root@chef-serv ~]# knife cookbook upload iis windows webpi chef_handler

Let's define a role that we can add to our server's run-list which will then in turn install iis on the server. Just create a file in /root/chef-repo/roles/ called iis.rb and give it the following content. Don't forget to "accept the EULA" or iis won't install.

	[root@chef-serv ~]# cat chef-repo/roles/iis.rb
	name "iis"
	description "IIS Web Server"
	run_list(
	  "recipe[iis]",
	  "recipe[iis::mod_mvc3]",
	  "recipe[iis::mod_urlrewrite]"
	)
	default_attributes(
	  "iis" => {
	    "accept_eula" => true
	  }
	)

Then create a role from that file and check if it actually does what we want it to do.

	[root@chef-serv ~]# knife role from file chef-repo/roles/iis.rb
	Updated Role iis!
	[root@chef-serv ~]# knife role show iis
	chef_type:           role
	default_attributes:
	  iis:
	    accept_eula: true
	description:         IIS Web Server
	env_run_lists:
	json_class:          Chef::Role
	name:                iis
	override_attributes:
	run_list:
	  recipe[iis]
	  recipe[iis::mod_mvc3]
	  recipe[iis::mod_urlrewrite]

Add the role to our server's run-list and re-run the chef-client remotely using the knife winrm command. At this point we need to specify which attribute to use to connect to our server as the FQDN will most likely not resolve to anything (really depends on what you called your server though)

	[root@chef-serv ~]# knife node run_list add CHEF-WIN role[iis]
	[root@chef-serv ~]# knife winrm name:CHEF-WIN 'chef-client' -x ADministrator -P A7not3si5ELo -a ipaddress
	95.138.188.93 [2013-07-31T09:47:08+00:00] INFO: *** Chef 11.6.0 ***
	95.138.188.93 [2013-07-31T09:48:07+00:00] INFO: Run List is [role[iis]]
	95.138.188.93 [2013-07-31T09:48:07+00:00] INFO: Run List expands to [iis, iis::mod_mvc3, iis::mod_urlrewrite]
	95.138.188.93 [2013-07-31T09:48:07+00:00] INFO: Starting Chef Run for CHEF-WIN
	95.138.188.93 [2013-07-31T09:48:07+00:00] INFO: Running start handlers
	95.138.188.93 [2013-07-31T09:48:07+00:00] INFO: Start handlers complete.
	95.138.188.93 [2013-07-31T09:48:08+00:00] INFO: Loading cookbooks [chef_handler, iis, webpi, windows]
	95.138.188.93 [2013-07-31T09:48:08+00:00] INFO: Processing chef_gem[win32-api] action install (windows::default line 23)
	95.138.188.93 [2013-07-31T09:48:08+00:00] INFO: Processing chef_gem[win32-service] action install (windows::default line 23)
	95.138.188.93 [2013-07-31T09:48:08+00:00] INFO: Processing chef_gem[windows-api] action install (windows::default line 31)
	95.138.188.93 [2013-07-31T09:48:08+00:00] INFO: Processing chef_gem[windows-pr] action install (windows::default line 31)
	95.138.188.93 [2013-07-31T09:48:08+00:00] INFO: Processing chef_gem[win32-dir] action install (windows::default line 31)
	95.138.188.93 [2013-07-31T09:48:08+00:00] INFO: Processing chef_gem[win32-event] action install (windows::default line 31)
	95.138.188.93 [2013-07-31T09:48:08+00:00] INFO: Processing chef_gem[win32-mutex] action install (windows::default line 31)
	95.138.188.93 [2013-07-31T09:48:08+00:00] INFO: Processing remote_file[msi] action create (webpi::install-msi line 27)
	95.138.188.93 [2013-07-31T09:48:09+00:00] INFO: Processing windows_package[Microsoft Web Platform Installer 4.5] action install (webpi::install-msi line 33)
	95.138.188.93 [2013-07-31T09:48:09+00:00] INFO: Installing windows_package[Microsoft Web Platform Installer 4.5] version latest
	95.138.188.93 [2013-07-31T09:48:09+00:00] INFO: Starting installation...this could take awhile.
	95.138.188.93 [2013-07-31T09:48:09+00:00] INFO: Processing chef_gem[win32-api] action install (windows::default line 23)
	95.138.188.93 [2013-07-31T09:48:09+00:00] INFO: Processing chef_gem[win32-service] action install (windows::default line 23)
	95.138.188.93 [2013-07-31T09:48:09+00:00] INFO: Processing chef_gem[windows-api] action install (windows::default line 31)
	95.138.188.93 [2013-07-31T09:48:09+00:00] INFO: Processing chef_gem[windows-pr] action install (windows::default line 31)
	95.138.188.93 [2013-07-31T09:48:09+00:00] INFO: Processing chef_gem[win32-dir] action install (windows::default line 31)
	95.138.188.93 [2013-07-31T09:48:09+00:00] INFO: Processing chef_gem[win32-event] action install (windows::default line 31)
	95.138.188.93 [2013-07-31T09:48:09+00:00] INFO: Processing chef_gem[win32-mutex] action install (windows::default line 31)
	95.138.188.93 [2013-07-31T09:48:09+00:00] INFO: Processing remote_file[msi] action nothing (webpi::install-msi line 27)
	95.138.188.93 [2013-07-31T09:48:09+00:00] INFO: Processing windows_package[Microsoft Web Platform Installer 4.5] action nothing (webpi::install-msi line 33)
	95.138.188.93 [2013-07-31T09:48:09+00:00] INFO: Processing webpi_product[IIS7] action install (iis::default line 27)
	95.138.188.93 [2013-07-31T09:49:36+00:00] INFO: webpi_product[IIS7] added new product 'IIS7'
	95.138.188.93 [2013-07-31T09:49:36+00:00] INFO: webpi_product[IIS7] sending run action to execute[Register ASP.NET v4] (immediate)
	95.138.188.93 [2013-07-31T09:49:36+00:00] INFO: Processing execute[Register ASP.NET v4] action run (iis::default line 35)
	95.138.188.93 [2013-07-31T09:49:36+00:00] INFO: execute[Register ASP.NET v4] ran successfully
	95.138.188.93 [2013-07-31T09:49:36+00:00] INFO: webpi_product[IIS7] sending run action to execute[Register ASP.NET v4 (x64)] (immediate)
	95.138.188.93 [2013-07-31T09:49:36+00:00] INFO: Processing execute[Register ASP.NET v4 (x64)] action run (iis::default line 42)
	95.138.188.93 [2013-07-31T09:49:36+00:00] INFO: execute[Register ASP.NET v4 (x64)] ran successfully
	95.138.188.93 [2013-07-31T09:49:36+00:00] INFO: Processing execute[Register ASP.NET v4] action nothing (iis::default line 35)
	95.138.188.93 [2013-07-31T09:49:36+00:00] INFO: Processing execute[Register ASP.NET v4 (x64)] action nothing (iis::default line 42)
	95.138.188.93 [2013-07-31T09:49:36+00:00] INFO: Processing service[iis] action nothing (iis::default line 48)
	95.138.188.93 [2013-07-31T09:49:36+00:00] INFO: Processing webpi_product[MVC3] action install (iis::mod_mvc3 line 23)
	95.138.188.93 [2013-07-31T09:50:05+00:00] INFO: webpi_product[MVC3] added new product 'MVC3'
	95.138.188.93 [2013-07-31T09:50:05+00:00] INFO: Processing webpi_product[UrlRewrite2] action install (iis::mod_urlrewrite line 23)
	95.138.188.93 [2013-07-31T09:50:29+00:00] INFO: webpi_product[UrlRewrite2] added new product 'UrlRewrite2'
	95.138.188.93 [2013-07-31T09:50:29+00:00] INFO: Chef Run complete in 142.03902 seconds
	95.138.188.93 [2013-07-31T09:50:29+00:00] INFO: Running report handlers
	95.138.188.93 [2013-07-31T09:50:29+00:00] INFO: Report handlers complete


That was fairly quick. You now have a Windows Server 2012 server running up in the cloud with IIS installed on it serving web-content (to be fair only the default IIS 8 page, but it is serving content) without logging in to that server one single time. If you wanted you could have 20 servers in the same time.

Finally, if you want to reproduce this quickly and don't really want to scroll through this document and copy-paste each command one at a time, find below a list of commands arranged in blocks so there are breaks when user input or action is required. The easiest is to just copy that into a notepad/text editor of your choice and substitute the values as you go along and copy-paste.

	nova boot --image e0ed4adb-3a00-433e-a0ac-a51f1bc1ea3d --flavor 2 --file "/root/.ssh/authorized_keys=.ssh/id_rsa.pub" chef-serv

	echo 'net start w32time
	w32tm /config /manualpeerlist:"0.uk.pool.ntp.org 1.uk.pool.ntp.org 2.uk.pool.ntp.org 3.uk.pool.ntp.org" /syncfromflags:manual /reliable:yes /update
	w32tm /resync
	netsh advfirewall firewall set rule group="remote administration" new enable=yes & netsh advfirewall firewall add rule name="WinRM Port" dir=in action=allow protocol=TCP remoteip=<IP_ADDR> localport=5985
	echo <IP_ADDR> chef-serv >> C:\Windows\system32\drivers\etc\hosts' > bootstrap.cmd
	nova boot --image f7f274f3-5d04-4a2c-9159-29b9d295cf76 --flavor 3 --file "C:\\cloud-automation\\bootstrap.cmd=bootstrap.cmd" chef-win

	ssh root@<IP_ADDR>

	curl -L https://get.rvm.io | bash
	source /etc/profile.d/rvm.sh
	rvm install 1.9.3
	wget https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/chef-server-11.0.8-1.el6.x86_64.rpm
	rpm --install ./chef-server-11.0.8-1.el6.x86_64.rpm
	chef-server-ctl reconfigure
	iptables -I INPUT 1 -p tcp -m tcp --dport 80 -j ACCEPT
	iptables -I INPUT 1 -p tcp -m tcp --dport 443 -j ACCEPT
	service iptables save

	gem install rdoc
	gem install chef
	yum install git -y
	git clone https://github.com/opscode/chef-repo
	knife configure -i -r ~/chef-repo/

	yum install ruby-devel libxml2-devel libxslt-devel -y
	git clone https://github.com/opscode/knife-windows.git
	cd knife-windows
	git checkout 95d79e32eb47db95471726c1460cc561caaef6d7
	rake build
	gem install pkg/knife-windows-0.5.13.gem
	cd ..

	telnet 95.138.188.93 5985

	knife bootstrap windows winrm 95.138.188.93 -x Administrator -P A7not3si5ELo

	knife cookbook site install webpi
	knife cookbook site install windows
	knife cookbook site install chef_handler
	knife cookbook site install iis
	knife cookbook upload iis windows webpi chef_handler

	echo 'name "iis"
	description "IIS Web Server"
	run_list(
	  "recipe[iis]",
	  "recipe[iis::mod_mvc3]",
	  "recipe[iis::mod_urlrewrite]"
	)
	default_attributes(
	  "iis" => {
	    "accept_eula" => true
	  }
	)' > chef-repo/roles/iis.rb
	knife role from file chef-repo/roles/iis.rb
	knife node run_list add CHEF-WIN role[iis]

	knife winrm name:CHEF-WIN 'chef-client' -x ADministrator -P A7not3si5ELo -a ipaddress
