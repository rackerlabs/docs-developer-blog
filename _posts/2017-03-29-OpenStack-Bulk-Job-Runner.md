---
layout: post
title: OpenStack bulk job runner
date: 2017-03-29 00:00
comments: false
author: Kevin Carter
published: true
authorIsRacker: true
categories:
    - OpenStack
---

As OpenStack projects grow its likely that a given project will spawn
several repositories and will share code snippets across them.

<!-- more -->

If you're ever in need of updating a mess of repositories all at the
same time these steps, and linked script, can help you
identify all repositories governed under a single project and run some
type of bulk job(s) across them.

### Getting a list of all repositories under a given project's governance

First, clone OpenStack Infra's **project-config** repository.

``` bash
git clone https://github.com/openstack-infra/project-config project-config
```

Next, change directory to ``project-config``, this was just created when
you cloned the repository, and use the following bit of python to parse
the ``projects.yaml`` file and print all of the known repositories.

``` python
PROJECT_GROUP='openstack-ansible'  # This should be set to your project group.

import yaml  # Note this will need to be present on the system.

with open('gerrit/projects.yaml') as f:
    projects = yaml.load(f.read())

for project in projects:
    pgs = project.get('groups', list())
    dig = project.get('docimpact-group', 'unknown')
    if PROJECT_GROUP in pgs or PROJECT_GROUP in dig:
        project_entry = project['project']
        project_github = 'https://github.com/%s' % project['project']
        print(project_github)
```

The previous snippet prints the github URL for all of the repositories. If
this was fed into a bash variable using a [here document](http://tldp.org/LDP/abs/html/here-docs.html),
you could simply loop over the results and clone the repositories.

``` bash
PROJECTS=$(
python <<EOR
PROJECT_GROUP="${PROJECT_GROUP_NAME}"  # This should be set to your project group.
import yaml  # Note this will need to be present on the system.
with open('gerrit/projects.yaml') as f:
    projects = yaml.load(f.read())
for project in projects:
    pgs = project.get('groups', list())
    dig = project.get('docimpact-group', 'unknown')
    if PROJECT_GROUP in pgs or PROJECT_GROUP in dig:
        project_entry = project['project']
        project_github = 'https://github.com/%s' % project['project']
        print(project_github)
EOR
)

for project in ${PROJECTS}; do
    PROJECT_NAME="$(basename ${project})"
    PROJECT_PATH="${WORKSPACE}/${PROJECT_NAME}"
    git clone "${project}" "${PROJECT_PATH}"
done
```

Once cloned, change to the directory of a cloned repository and run whatever
bulk job is needed, commit the changes, and submit them for review.

### Running bulk jobs using a script

Here's a [simple script](https://github.com/cloudnull/random_scripts/blob/master/openstacky-things/bulk-job-doer.sh)
which pulls all of this together and can serve as a basic template for
running bulk jobs across a sprawl of repositories. The linked script has
some things which should be changed up to meet your needs.

**Specifically:**

1. The ``bulk_function`` should be updated to run your bulk job. This could
   be bash, external scripts, other tools, etc.
2. The **MESSAGE** constant should be updated to so reviewers know why
   you're making this change. This will be used when the script commits
   the changes and submits them for review.
3. The **BULK\_JOB\_TOPIC** should be set for proper tracking. Typically
   this is used for feature or bug tracking.
4. *OPTIONAL*: Set the **WORKSPACE** variable to the location where you'll
   be storing the repositories. The default is ``/tmp/workspace``.

