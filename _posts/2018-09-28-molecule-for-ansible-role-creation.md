---
layout: post
title: "Molecule for Ansible role creation"
date: 2018-09-28 07:00
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

In our Quality Engineering organization, we create, configure, and destroy a lot of servers via automation. [Ansible](https://ansible.com) is a great method for handling the configuration of servers, but the creation of Ansible roles and playbooks can be trial and error for even experienced Operations Engineers. [Molecule](https://molecule.readthedocs.io/en/latest/) provides a way to speed up the development and confidence of Ansible roles and playbooks by wrapping a virtualization driver with tools for testing and linting.

<!-- more -->

## Installation

Molecule and Ansible can be installed by using `pip`, but I would recommend not running this in a dedicated virtual environment. I typically run on a Fedora system and have run into issues with `libselinux` when using a virtual environment. A quick online search can provide a work around or two, but I find it easiest to use the `--user` flag to install Molecule with the user scheme.

```
pip install --upgrade --user ansible
pip install --upgrade --user molecule
```

If you don't already have `ansible` or `molecule` installed, running a pip install results in some significant output. Pip is good about drawing attention to errors, even if the resolution isn't always clear, but the last couple lines of output provide the libraries and versions installed from those commands.

## Getting started

If you're creating a new role in an existing Ansible playbook directory, simply access the `roles` directory in it. If you're just following along to learn Molecule, create an empty directory to hold your new Ansible playbooks.

```
~/$ mkdir -p ~/Projects/example_playbooks/roles
~/$ cd ~/Projects/example_playbooks/roles
```

In the interest of brevity, I'm not including the pip installation output. But, the output below provides the software versions used in the creation of this example. Both Ansible and Molecule development move quick and do have some significant changes between point releases, so if the version numbers vary significantly, these instructions might now work verbatim.

```
~/Projects/example_playbooks$ ansible --version
ansible 2.6.4
  config file = /etc/ansible/ansible.cfg
  configured module search path = [u'/home/dan/.ansible/plugins/modules', u'/usr/share/ansible/plugins/modules']
  ansible python module location = /home/dan/.local/lib/python2.7/site-packages/ansible
  executable location = /home/dan/.local/bin/ansible
  python version = 2.7.12 (default, Dec  4 2017, 14:50:18) [GCC 5.4.0 20160609]
~/Projects/example_playbooks$ molecule --version
molecule, version 2.17.0
~/Projects/example_playbooks$ tree
.

0 directories, 0 files
~/Projects/example_playbooks$ 
```

## Create a role

Molecule has pretty excellent help output with `molecule --help`. In this example, we're going to create a role with `molecule` and use the `vagrant` provider. `molecule` defaults to Docker for provisioning, but I prefer to use `vagrant` with VirtualBox because the majority of the testing environments I interact with are virtual machines and not containers.

Creating a role and specifying both the name and driver creates a role directory structure.

```
~/Projects/example_playbooks$ molecule init role --role-name nginx_install --driver-name vagrant
--> Initializing new role nginx_install...
Initialized role in /home/dan/Projects/example_playbooks/nginx_install successfully.
~/Projects/example_playbooks$ tree
.
└── nginx_install
    ├── defaults
    │   └── main.yml
    ├── handlers
    │   └── main.yml
    ├── meta
    │   └── main.yml
    ├── molecule
    │   └── default
    │       ├── INSTALL.rst
    │       ├── molecule.yml
    │       ├── playbook.yml
    │       ├── prepare.yml
    │       └── tests
    │           └── test_default.py
    ├── README.md
    ├── tasks
    │   └── main.yml
    └── vars
        └── main.yml

8 directories, 11 files
```

As you can see, that command creates quite a few directories. Most of the following files and directories are standard and are considered best practises for Ansible.

* defaults - default values to variables for the role
* handlers - specific handlers to notify based on actions in Ansible
* meta - Ansible-Galaxy info for the role if you are uploading this to Ansible-Galaxy
* molecule - molecule specific information (configuration, instance information, playbooks to run with molecule, etc)
* README.md - Information about the role. Well documented, excellent feature (I'm a big fan of documentation, should be obvious if you're reading this)
* tasks - tasks for the role
* vars - other variables for the role

## Modifications from default Molecule

Theres a few defaults I **always** change when using `molecule` because it uses `Cookie-Cutter` to create a default configuration. The first, `molecule` defaults to Ubuntu, but the majority of our test systems are RHEL based. Also I prefer to specify the memory and CPUs rather than relying on the box defaults.

Another thing we'll change from default is to set up port forwarding. Because we're using `nginx` in this example, we may as well set it up so we can hit the webserver locally.

These changes are made by modifying the `molecule/default/molecule.yml` file to be similar to the following example. This `molecule.yml` file is where `molecule` looks for the configuration of instances, testing, linting, etc.

*Heads up, a raw copy/pasta of the following code will result in an error. Read on to see why*

```
~/Projects/example_playbooks/nginx_install$ cat molecule/default/molecule.yml 
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
  - name: nginx_install
    box: centos/7
    instance_raw_config_args:
      - "vm.network 'forwarded_port', guest: 80, host: 9000"
    memory: 512
    cpus: 1
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
```

Once we've got the `molecule` configuration to our liking, time to start working on the role itself. Ansible role tasks are in `tasks/main.yml` for the role. This example is pretty simple, so all we're doing is installing a repository to install `nginx`, installing `nginx`, and starting/enabling `nginx`. The only Ansible modules we need for this is `yum` for package installation and `systemd` to start and enable the service.

```
~/Projects/example_playbooks/nginx_install$ cat tasks/main.yml 
---
# tasks file for nginx_install
- name: Install epel-release for nginx
  yum:
    name: epel-release
    state: present
  become: "yes"

- name: install nginx
  yum:
    name: nginx
    state: present
  become: "yes"

- name: ensure nginx running and enabled
  systemd:
    name: nginx
    state: started
    enabled: "yes"
  become: "yes"
```

Molecule does some great things. It handles the orchestration of the virtual environment to test, lints Ansible syntax, lints and runs a test suite, and even destroys the created resources on completion.

## Writing tests for the role

We can manually test the role with some SSHing and curl, but [testinfra](https://testinfra.readthedocs.io/en/latest/) is included as the default verifier step of `molecule`. Testinfra uses `pytest` and makes it easy to test the system after the role is run to ensure our created role has the results that we expected.

This role is pretty simple, so our tests are pretty simple. Since we're just installing and starting `nginx`, there's not a whole lot more we're looking for in our test. Of course `molecule` provides a good demonstration test to build up a test suite and `testinfra` documentation even uses `nginx` in their [quickstart](https://testinfra.readthedocs.io/en/latest/).

### Tests - quantity or quality?

The following three tests are all pretty simple. The overall count of tests really doesn't matter as much as the quality of tests. While we've got three tests in this example, we could easily have one or five. This might vary based on the Software Developer, but I chose the following three because they follow a logical order.

1. Make sure nginx is installed
1. Make sure nginx configuration was installed correctly
1. Make sure nginx is running and enabled

This is easiest to understand by looking at it backwards. If we had one test to see if `nginx` is running, when it fails we won't know why it fails. That one test can't tell us if it was not installed, if the configuration was incorrect, or if it was not started. My approach is to first make sure it is installed, next check if the configuration exists (in a more elaborate example, we'd instead check to make sure there is some expected text in the configuration file). Finally, we make sure `nginx` is running and enabled. This way the tests follow a logical flow of prerequisites to get to our ultimate state, and knock out some troubleshooting steps along the way.

```
cat molecule/default/tests/test_default.py
import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_nginx_installed(host):
    nginx = host.package('nginx')
    assert nginx.is_installed

def test_nginx_config_exists(host):
    nginx_config = host.file('/etc/nginx/nginx.conf')
    assert nginx_config.exists

def test_nginx_running(host):
    nginx_service = host.service('nginx')
    assert nginx_service.is_running
    assert nginx_service.is_enabled
```

## Running Molecule

We've got both our role and tests written. We could just run `molecule test` and work through all the steps. But, I prefer running `create`, `converge`, and `test` all separately and in that order. This separates the various steps and makes any failures easier to track down.

### Molecule create

The first step of Molecule is the creation of the virtual machine. For `Docker` and `vagrant` providers, Molecule includes a default `create` playbook. Running `molecule create` creates the virtual machine for our role based on the `molecule.yml` configuration.

```
~/Projects/example_playbooks/nginx_install$ molecule create
--> Validating schema /home/dan/Projects/example_playbooks/nginx_install/molecule/default/molecule.yml.
Validation completed successfully.
--> Test matrix
    
└── default
    ├── create
    └── prepare
    
--> Scenario: 'default'
--> Action: 'create'
    
    PLAY [Create] ******************************************************************
    
    TASK [Create molecule instance(s)] *********************************************
    failed: [localhost] (item=None) => {"censored": "the output has been hidden due to the fact that 'no_log: true' was specified for this result", "changed": false}
    fatal: [localhost]: FAILED! => {"censored": "the output has been hidden due to the fact that 'no_log: true' was specified for this result", "changed": false}
    
    PLAY RECAP *********************************************************************
    localhost                  : ok=0    changed=0    unreachable=0    failed=1   
    
    
ERROR: 
```

That create gave us an error, and Ansible has a `no_log` property for tasks that is intended to prevent the outputting secrets that stopped us from seeing what exactly went wrong. We can set the environment variable of `MOLECULE_DEBUG` to log errors, but the first thing I do to save some typing is rerun the command with `--debug` flag.

```
~/Projects/example_playbooks/nginx_install$ molecule --debug create
...
        }, 
        "item": {
            "box": "centos/7", 
            "cpus": 1, 
            "instance_raw_config_args": [
                "vm.network 'forwarded_port', guest: 80, host: 9000"
            ], 
            "memory": 512, 
            "name": "nginx_install"
        }, 
        "msg": "ERROR: See log file '/tmp/molecule/nginx_install/default/vagrant-nginx_install.err'"
    }
    
    PLAY RECAP *********************************************************************
    localhost                  : ok=0    changed=0    unreachable=0    failed=1   
    
```

Reading into the error tells us it was an "error" in Vagrant and not necessarily one with `molecule` itself. We can look at the file provided in the error output for more clues.

```
~/Projects/example_playbooks/nginx_install$ cat /tmp/molecule/nginx_install/default/vagrant-nginx_install.err
### 2018-09-07 17:32:59 ###
### 2018-09-07 17:32:59 ###
There are errors in the configuration of this machine. Please fix
the following errors and try again:

vm:
* The hostname set for the VM should only contain letters, numbers,
hyphens or dots. It cannot start with a hyphen or dot.

### 2018-09-07 17:33:20 ###
### 2018-09-07 17:33:20 ###
There are errors in the configuration of this machine. Please fix
the following errors and try again:

vm:
* The hostname set for the VM should only contain letters, numbers,
hyphens or dots. It cannot start with a hyphen or dot.

```

Well, that's easy. Our hostname can't contain `_`. A quick edit to the `molecule.yml` should fix this right up.

```
~/Projects/example_playbooks/nginx_install$ grep -A1 platform molecule/default/molecule.yml 
platforms:
  - name: nginx-install
```

Now, we try again on the `create`:

```
~/Projects/example_playbooks/nginx_install$ molecule create
--> Validating schema /home/dan/Projects/example_playbooks/nginx_install/molecule/default/molecule.yml.
Validation completed successfully.
--> Test matrix
    
└── default
    ├── create
    └── prepare
    
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
    ok: [nginx-install]
    
    PLAY RECAP *********************************************************************
    nginx-install              : ok=1    changed=0    unreachable=0    failed=0
```

### Molecule converge

Molecule `create` only acts as orchestration. The `coverge` step is what runs our playbook that calls our role to configure the environment. There's good reason to do these steps separate. First, the `create` step ensures our virtual machine is provisioned and started correctly. After it's up, we've got less troubleshooting when actually running the playbook.

Another benefit of running steps separately is that, on a more complicated role, we could just run `converge` after every task to which we add to our role to make sure that it does what we intend for it to do. Because we only have three simple tasks, we can run converge to test all tasks at the same time.

```
~/Projects/example_playbooks/nginx_install$ molecule converge
--> Validating schema /home/dan/Projects/example_playbooks/nginx_install/molecule/default/molecule.yml.
Validation completed successfully.
--> Test matrix
    
└── default
    ├── dependency
    ├── create
    ├── prepare
    └── converge
    
--> Scenario: 'default'
--> Action: 'dependency'
Skipping, missing the requirements file.
--> Scenario: 'default'
--> Action: 'create'
Skipping, instances already created.
--> Scenario: 'default'
--> Action: 'prepare'
Skipping, instances already prepared.
--> Scenario: 'default'
--> Action: 'converge'
    
    PLAY [Converge] ****************************************************************
    
    TASK [Gathering Facts] *********************************************************
    ok: [nginx-install]
    
    TASK [nginx_install : Install epel-release for nginx] **************************
    changed: [nginx-install]
    
    TASK [nginx_install : install nginx] *******************************************
    changed: [nginx-install]
    
    TASK [nginx_install : ensure nginx running and enabled] ************************
    changed: [nginx-install]
    
    PLAY RECAP *********************************************************************
    nginx-install              : ok=4    changed=3    unreachable=0    failed=0
```

Cool. It worked, or at least looks like it did. Even though our playbooks ran without errors, running our tests will validate that it did what we think it did.

### Molecule test

Now we run test. This goes through all the steps and tells us whether what we think we're doing is actually working based our our `testinfra` tests. This tests our role by destroying any existing virtual machine, checking the syntax on the role, creating a new virtual machine, running our playbook, and linting and running our tests. If there are any issues, this should let us know.

```
~/Projects/example_playbooks/nginx_install$ molecule test
--> Validating schema /home/dan/Projects/example_playbooks/nginx_install/molecule/default/molecule.yml.
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
--> Executing Yamllint on files found in /home/dan/Projects/example_playbooks/nginx_install/...
Lint completed successfully.
--> Executing Flake8 on files found in /home/dan/Projects/example_playbooks/nginx_install/molecule/default/tests/...
    /home/dan/Projects/example_playbooks/nginx_install/molecule/default/tests/test_default.py:13:1: E302 expected 2 blank lines, found 1
    /home/dan/Projects/example_playbooks/nginx_install/molecule/default/tests/test_default.py:17:1: E302 expected 2 blank lines, found 1
    /home/dan/Projects/example_playbooks/nginx_install/molecule/default/tests/test_default.py:21:1: W391 blank line at end of file
An error occurred during the test sequence action: 'lint'. Cleaning up.
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

Another unintended failure. Lint issues in the python tests. Flake provides excellent output for pep errors, so we know exactly what to fix based on the output.

We can address those issues and then rerun the command, which should result in the following:

```
~/Projects/example_playbooks/nginx_install$ molecule test
--> Validating schema /home/dan/Projects/example_playbooks/nginx_install/molecule/default/molecule.yml.
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
--> Executing Yamllint on files found in /home/dan/Projects/example_playbooks/nginx_install/...
Lint completed successfully.
--> Executing Flake8 on files found in /home/dan/Projects/example_playbooks/nginx_install/molecule/default/tests/...
Lint completed successfully.
--> Executing Ansible Lint on /home/dan/Projects/example_playbooks/nginx_install/molecule/default/playbook.yml...
Lint completed successfully.
--> Scenario: 'default'
--> Action: 'destroy'
    
    PLAY [Destroy] *****************************************************************
    
    TASK [Destroy molecule instance(s)] ********************************************
    ok: [localhost] => (item=None)
    ok: [localhost]
    
    TASK [Populate instance config] ************************************************
    ok: [localhost]
    
    TASK [Dump instance config] ****************************************************
    skipping: [localhost]
    
    PLAY RECAP *********************************************************************
    localhost                  : ok=2    changed=0    unreachable=0    failed=0
    
    
--> Scenario: 'default'
--> Action: 'dependency'
Skipping, missing the requirements file.
--> Scenario: 'default'
--> Action: 'syntax'
    
    playbook: /home/dan/Projects/example_playbooks/nginx_install/molecule/default/playbook.yml
    
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
    ok: [nginx-install]
    
    PLAY RECAP *********************************************************************
    nginx-install              : ok=1    changed=0    unreachable=0    failed=0
    
    
--> Scenario: 'default'
--> Action: 'converge'
    
    PLAY [Converge] ****************************************************************
    
    TASK [Gathering Facts] *********************************************************
    ok: [nginx-install]
    
    TASK [nginx_install : Install epel-release for nginx] **************************
    changed: [nginx-install]
    
    TASK [nginx_install : install nginx] *******************************************
    changed: [nginx-install]
    
    TASK [nginx_install : ensure nginx running and enabled] ************************
    changed: [nginx-install]
    
    PLAY RECAP *********************************************************************
    nginx-install              : ok=4    changed=3    unreachable=0    failed=0
    
    
--> Scenario: 'default'
--> Action: 'idempotence'
Idempotence completed successfully.
--> Scenario: 'default'
--> Action: 'side_effect'
Skipping, side effect playbook not configured.
--> Scenario: 'default'
--> Action: 'verify'
--> Executing Testinfra tests found in /home/dan/Projects/example_playbooks/nginx_install/molecule/default/tests/...
    ============================= test session starts ==============================
    platform linux2 -- Python 2.7.12, pytest-3.3.1, py-1.5.2, pluggy-0.6.0
    rootdir: /home/dan/Projects/example_playbooks/nginx_install/molecule/default, inifile:
    plugins: testinfra-1.14.1
collected 3 items                                                              
    
    tests/test_default.py ...                                                [100%]
    
    =========================== 3 passed in 5.33 seconds ===========================
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

Great! With all that, now we know that our Ansible and Python tests are linted, and our tests run. This means our role does what we **intend** for it to do.

### Molecule verify

I did skip a step here. So far I have described the steps for:

* `molecule create` - create the virtual machine to make sure `molecule` is configured correctly.
* `molecule converge` - run multiple times as we add tasks to our role.
* `molecule test` - once we're happy, run all the steps of Molecule.

Really though, since `molecule test` runs through all the steps (creation, linting, testing, deletion, etc), and earlier I laid out the steps of running converge to manually test each time, this does not exactly fit the workflow I mentioned previously. We can separate out the `molecule` steps a little further.

Rather than running `molecule test`, we can run `molecule verify` separately to skip the little bit of extra time in creating and destroying the virtual machine.

```
~/Projects/example_playbooks/nginx_install$ molecule verify
--> Validating schema /home/dan/Projects/example_playbooks/nginx_install/molecule/default/molecule.yml.
Validation completed successfully.
--> Test matrix
    
└── default
    └── verify
    
--> Scenario: 'default'
--> Action: 'verify'
--> Executing Testinfra tests found in /home/dan/Projects/example_playbooks/nginx_install/molecule/default/tests/...
    ============================= test session starts ==============================
    platform linux2 -- Python 2.7.12, pytest-3.3.1, py-1.5.2, pluggy-0.6.0
    rootdir: /home/dan/Projects/example_playbooks/nginx_install/molecule/default, inifile:
    plugins: testinfra-1.14.1
collected 3 items                                                              
    
    tests/test_default.py ...                                                [100%]
    
    =========================== 3 passed in 5.25 seconds ===========================
Verifier completed successfully.
~/Projects/example_playbooks/nginx_install$ molecule lint
--> Validating schema /home/dan/Projects/example_playbooks/nginx_install/molecule/default/molecule.yml.
Validation completed successfully.
--> Test matrix
    
└── default
    └── lint
    
--> Scenario: 'default'
--> Action: 'lint'
--> Executing Yamllint on files found in /home/dan/Projects/example_playbooks/nginx_install/...
Lint completed successfully.
--> Executing Flake8 on files found in /home/dan/Projects/example_playbooks/nginx_install/molecule/default/tests/...
Lint completed successfully.
--> Executing Ansible Lint on /home/dan/Projects/example_playbooks/nginx_install/molecule/default/playbook.yml...
Lint completed successfully.
```

## Conclusion

Molecule is a great abstraction for the multiple steps of create, test, and clean that happen during development of an Ansible role. Not only does it create and provide sane defaults to the directory structure of a role, it makes it easy to create a test a role during development. While there is a bit of a learning curve, the increased productivity of testing during development makes it an absolutely worthwhile investment.