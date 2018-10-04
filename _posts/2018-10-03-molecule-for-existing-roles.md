---
layout: post
title: "Molecule for existing Ansible roles"
date: 2018-10-03 07:00
comments: true
author: Dan Kolb
published: true
authorIsRacker: true
authorAvatar: https://gravatar.com/avatar/fbdcdc8fcc8d2ae995d763dc6ed144d4
bio: "Dan Kolb is a Software Developer in Test in the Rackspace Private Cloud Powered by VMware. Dan spends his time improving products and services through his passion and evangelization of automation and open source software."
categories:
    - Automation
    - DevOps
    - Ansible
    - Orchestration
---

Ansible development is fast, and anyone using Ansible extensively has most likely come across an instance where a playbook that used to work does not work on a later Ansible version. Or, a system that wasn't supported initially is now added and an existing role requires modification to make it work on the new system. See [Molecule for Ansible role creation](https://developer.rackspace.com/blog/molecule-for-ansible-role-creation/) for more details on using and debugging Molecule. Creating a Molecule scenario to test an existing role allows for easy testing and modification of that role with all the benefits that Molecule provides.

<!-- more -->

## Existing role

For an easy example, we use a simple role that installs and starts a webserver. To prevent a complete copy and paste from the previous example, the webserver this time is Apache rather than Nginx. The existing role in its current state is as follows.

```
~/Projects/example_playbooks/roles/apache_install$ tree
.
└── tasks
    └── main.yml

1 directory, 1 file
~/Projects/example_playbooks/roles/apache_install$ cat tasks/main.yml 
---
# install and start apache    
- name: install apache
  yum:
    name: httpd
    state: present
  become: "yes"

- name: ensure apache running and enabled
  systemd:
    name: httpd
    state: started
    enabled: "yes"
  become: "yes"
```

Because Ansible and Molecule development is very fast these instructions might not work exactly as demonstrated if the software version varies significantly from the following output.

```
~/Projects/example_playbooks/roles/apache_install$ ansible --version && molecule --version
ansible 2.6.4
  config file = /etc/ansible/ansible.cfg
  configured module search path = [u'/home/dan/.ansible/plugins/modules', u'/usr/share/ansible/plugins/modules']
  ansible python module location = /home/dan/.local/lib/python2.7/site-packages/ansible
  executable location = /home/dan/.local/bin/ansible
  python version = 2.7.12 (default, Dec  4 2017, 14:50:18) [GCC 5.4.0 20160609]
molecule, version 2.17.0
```

## Init scenario

Because the role already exists, only a scenario needs to be created. A Molecule scenario is the same in this context as it is when using Molecule to create the role, but it results in Molecule not creating the directory structure and template files. The parameters to `init scenario` are almost exactly the same as `init role` and result in the same Molecule directory structure as if we created the role with Molecule.

Molecule `init scenario` usage information:

```
~/Projects/example_playbooks/roles/apache_install$ molecule init scenario --help
Usage: molecule init scenario [OPTIONS]

  Initialize a new scenario for use with Molecule.

Options:
  --dependency-name [galaxy]      Name of dependency to initialize. (galaxy)
  -d, --driver-name [azure|delegated|docker|ec2|gce|lxc|lxd|openstack|vagrant]
                                  Name of driver to initialize. (docker)
  --lint-name [yamllint]          Name of lint to initialize. (ansible-lint)
  --provisioner-name [ansible]    Name of provisioner to initialize. (ansible)
  -r, --role-name TEXT            Name of the role to create.  [required]
  -s, --scenario-name TEXT        Name of the scenario to create. (default)
                                  [required]
  --verifier-name [goss|inspec|testinfra]
                                  Name of verifier to initialize. (testinfra)
  --help                          Show this message and exit.
```

We create the scenario by using the existing role name and specifying using Vagrant as the driver. The Molecule directory structure is initialized the same as if we created the role with Molecule but without any role specific directories being created (such as `handlers`, `meta`, etc).

```
~/Projects/example_playbooks/roles/apache_install$ molecule init scenario --role-name apache_install --driver-name vagrant
--> Initializing new scenario default...
Initialized scenario in /home/dan/Projects/example_playbooks/roles/apache_install/molecule/default successfully.
~/Projects/example_playbooks/roles/apache_install$ tree
.
├── molecule
│   └── default
│       ├── INSTALL.rst
│       ├── molecule.yml
│       ├── playbook.yml
│       ├── prepare.yml
│       └── tests
│           └── test_default.py
└── tasks
    └── main.yml

4 directories, 6 files
```

## Configuration

The Molecule configuration is initialized as the default provided by molecule. I edited this to use CentOS 7 rather than the default Ubuntu 16.04. Also, I recommend updating the name of the virtual machine to something different to distinguish that virtual machine in case we need to troubleshoot at some point.

In this example, our tests are very similar to my previous [Ansible role creation with Molecule](https://developer.rackspace.com/blog/molecule-for-ansible-role-creation/) post. The primary (and possibly only) differences in our tests from the previous example is that we're testing for the `httpd` service rather than `nginx`.

```
~/Projects/example_playbooks/roles/apache_install$ cat molecule/default/molecule.yml 
---
dependency:
  name: galaxy
driver:
  name: vagrant
  provider:
    name: virtualbox
lint:
  name: yamllint
platforms:
  - name: apache
    box: centos/7
provisioner:
  name: ansible
  lint:
    name: ansible-lint
scenario:
  name: default
verifier:
  name: testinfra
  lint:
    name: flake8
    
~/Projects/example_playbooks/roles/apache_install$ cat molecule/default/tests/test_default.py
import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_apache_installed(host):
    apache = host.package("httpd")
    assert apache.is_installed


def test_apache_config(host):
    apache = host.file('/etc/httpd/conf/httpd.conf')
    assert apache.exists


def test_apache_running_and_enabled(host):
    apache = host.service("httpd")
    assert apache.is_running
    assert apache.is_enabled
```

## Molecule test

Now that we've updated our Molecule configuration to use the Vagrant box we want and updated our tests to ensure that our role is doing what we want, we run any of the Molecule commands (`test`, `create`, `converge`, etc) just as if we created the role using Molecule.

```
~/Projects/example_playbooks/roles/apache_install$ molecule test
--> Validating schema /home/dan/Projects/example_playbooks/roles/apache_install/molecule/default/molecule.yml.
Validation completed successfully.
--> Test matrix
    
└── default
    ├── lint
    ├── destroy
    ├── dependency
    ├── syntax
    ├── create
    ├── prepare
    ├── converge
    ├── idempotence
    ├── side_effect
    ├── verify
    └── destroy
    
--> Scenario: 'default'
--> Action: 'lint'
--> Executing Yamllint on files found in /home/dan/Projects/example_playbooks/roles/apache_install/...
Lint completed successfully.
--> Executing Flake8 on files found in /home/dan/Projects/example_playbooks/roles/apache_install/molecule/default/tests/...
Lint completed successfully.
--> Executing Ansible Lint on /home/dan/Projects/example_playbooks/roles/apache_install/molecule/default/playbook.yml...
Lint completed successfully.
--> Scenario: 'default'
--> Action: 'destroy'
    
    PLAY [Destroy] *****************************************************************
    
    TASK [Destroy molecule instance(s)] ********************************************
    changed: [localhost] => (item=None)
    changed: [localhost]
    
    TASK [Populate instance config] ************************************************
    ok: [localhost]
    
    TASK [Dump instance config] ****************************************************
    changed: [localhost]
    
    PLAY RECAP *********************************************************************
    localhost                  : ok=3    changed=2    unreachable=0    failed=0
    
    
--> Scenario: 'default'
--> Action: 'dependency'
Skipping, missing the requirements file.
--> Scenario: 'default'
--> Action: 'syntax'
    
    playbook: /home/dan/Projects/example_playbooks/roles/apache_install/molecule/default/playbook.yml
    
--> Scenario: 'default'
--> Action: 'create'
    
    PLAY [Create] ******************************************************************
    
    TASK [Create molecule instance(s)] *********************************************
    changed: [localhost] => (item=None)
    changed: [localhost]
    
    TASK [Populate instance config dict] *******************************************
    ok: [localhost] => (item=None)
    ok: [localhost]
    
    TASK [Convert instance config dict to a list] **********************************
    ok: [localhost]
    
    TASK [Dump instance config] ****************************************************
    changed: [localhost]
    
    PLAY RECAP *********************************************************************
    localhost                  : ok=4    changed=2    unreachable=0    failed=0
    
    
--> Scenario: 'default'
--> Action: 'prepare'
    
    PLAY [Prepare] *****************************************************************
    
    TASK [Install python for Ansible] **********************************************
    ok: [apache]
    
    PLAY RECAP *********************************************************************
    apache                     : ok=1    changed=0    unreachable=0    failed=0
    
    
--> Scenario: 'default'
--> Action: 'converge'
    
    PLAY [Converge] ****************************************************************
    
    TASK [Gathering Facts] *********************************************************
    ok: [apache]
    
    TASK [apache_install : install apache] *****************************************
    changed: [apache]
    
    TASK [apache_install : ensure apache running and enabled] **********************
    changed: [apache]
    
    PLAY RECAP *********************************************************************
    apache                     : ok=3    changed=2    unreachable=0    failed=0
    
    
--> Scenario: 'default'
--> Action: 'idempotence'
Idempotence completed successfully.
--> Scenario: 'default'
--> Action: 'side_effect'
Skipping, side effect playbook not configured.
--> Scenario: 'default'
--> Action: 'verify'
--> Executing Testinfra tests found in /home/dan/Projects/example_playbooks/roles/apache_install/molecule/default/tests/...
    ============================= test session starts ==============================
    platform linux2 -- Python 2.7.12, pytest-3.3.1, py-1.5.2, pluggy-0.6.0
    rootdir: /home/dan/Projects/example_playbooks/roles/apache_install/molecule/default, inifile:
    plugins: testinfra-1.14.1
collected 3 items                                                              
    
    tests/test_default.py ...                                                [100%]
    
    =========================== 3 passed in 5.62 seconds ===========================
Verifier completed successfully.
--> Scenario: 'default'
--> Action: 'destroy'
    
    PLAY [Destroy] *****************************************************************
    
    TASK [Destroy molecule instance(s)] ********************************************
    changed: [localhost] => (item=None)
    changed: [localhost]
    
    TASK [Populate instance config] ************************************************
    ok: [localhost]
    
    TASK [Dump instance config] ****************************************************
    changed: [localhost]
    
    PLAY RECAP *********************************************************************
    localhost                  : ok=3    changed=2    unreachable=0    failed=0
```

## Conclusion

Molecule not only provides great defaults and a consistent directory structure when creating a new role, but it also makes it easy and efficient to add a Molecule workflow for testing existing roles. Adding Molecule scenarios to existing roles is a great way for testing existing roles across Operating Systems and Ansible versions to improve their reliability.
