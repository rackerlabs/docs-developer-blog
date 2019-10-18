---
layout: post
title: Cloud Files directory listing
date: '2014-01-22 14:21'
comments: true
author: Louwrens Boonstra
published: true
categories:
  - Cloud Files
---

My last holiday took me to Morocco, where me and a couple of friends used
motorbikes to travel through the country. To have something to show off back
home, we used small cameras mounted on the bikes to film everything. At the
end of the trip, our group had filmed about 10 gigabytes of footage and I was
put in charge to gather and distribute these files amongst ourselves.

I uploaded all the footage - roughly 55 videos - to a Cloud Files container, b
ut obviously I didn't want to give my portal username and password to my
friends. Also, there is no option to generate an index file within Cloud Files,
so the only option left to me was to send everyone the 55 video URLs
separately. Clearly, a different solution was needed. And so I built one myself.

<!-- more -->

The script below will retrieve a list of files within a container, convert that list into an HTML filelist and then upload that HTML-file into your Cloud Files container. You just have to make sure that you enable the `Static Website` option in the container settings in Cloud Files and you're set.

The script is written in Bash and depends on httpie and jq, both which are available as packages on Ubuntu.

To install httpie and jq, please type the following:

        apt-get install httpie jq

After `httpie` and `jq` have been installed, copy the code below and save it as `cfindex.sh` on your (Linux) server:

        #!/bin/bash

        [[ -n "$3" ]] || { echo "Usage: $0 username apikey container"; exit 0 ; }

        ENDPOINT='lon.identity.api.rackspacecloud.com'

        AUTH='{ "auth": { "RAX-KSKEY:apiKeyCredentials": { "username": "'${1}'", "apiKey": "'${2}'" } } }'

        TOKENS=`echo ${AUTH} | http POST https://${ENDPOINT}/v2.0/tokens`

        AUTHTOKEN=`echo ${TOKENS} | jq -r '.access.token.id'`
        PUBLICURL=`echo ${TOKENS} | jq -r '.access.serviceCatalog[] | select(.name == "cloudFiles").endpoints[].publicURL'`

        HTML="<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"https://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n"
        HTML+="<html xmlns=\"https://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">\n"
        HTML+="\t<head>\n"
        HTML+="\t\t<meta http-equiv=\"Content-Type\" content=\"text/html;charset=utf-8\" />\n"
        HTML+="\t\t<title>Container index</title>\n"
        HTML+="\t</head>\n"
        HTML+="\t<body>\n"
        HTML+="\t\t<table>\n"
        HTML+="\t\t\t<tr><th>Name</th><th>Content-type</th><th>Bytes</th><th>Last modified</th></tr>\n"

        while read line
        do
                content_type=`echo ${line} | jq -r .content_type`
                name=`echo ${line} | jq -r .name`
                bytes=`echo ${line} | jq -r .bytes`
                last_modified=`echo ${line} | jq -r .last_modified`
                if [ ${name} != "index.html" ]
                then
                        HTML+="\t\t\t<tr><td><a href=\"${name}\">${name}</a></td><td>${content_type}</td><td>${bytes}</td><td>${last_modified}</td></tr>\n"
                fi
        done < <( http GET ${PUBLICURL}/${3}?format=json X-Auth-Token:${AUTHTOKEN} | jq -c .[] )

        HTML+="\t\t</table>\n"
        HTML+="\t\t<div><br /><i>Generated on `date`</i></div>\n"
        HTML+="\t</body>\n"
        HTML+="</html>"

        echo -e ${HTML} | http PUT ${PUBLICURL}/${3}/index.html X-Auth-Token:${AUTHTOKEN} Content-Type:text/html


Invoke the script using your cloud account username, the API-Key provided under your account details and the name of the container

        $ ./cfindex.sh
        Usage: ./cfindex.sh username apikey containername

Now just point your browser to your Cloud Files container URL to view a public list of all your files!
