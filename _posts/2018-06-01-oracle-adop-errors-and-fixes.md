---
layout: post
title: "Oracle AD Online Patching errors and fixes"
date: 2018-06-01 00:00
comments: true
author: Nagunaik Vankudotu
published: true
authorIsRacker: true
categories:
    - Oracle
---

Originally published by Tricore: Aug 14, 2017

This blog describes the following common issues and solutions for the Oracle
&reg; AD Online Patching (adop) utility:

- Data dictionary corruption error
- adop prepare failure
- Forms object generation failure
- adop cutover hang-up
- Patch abort

<!-- more -->

### Data dictionary corruption error

The data dictionary corruption error might occur when the adop prepare step
fails.

#### Error

The following error might vary for different environments.

    [EVENT]     Verifying data dictionary.
    [UNEXPECTED]Data dictionary corrupted:
    [UNEXPECTED]Data dictionary corruption - missing parent
    5608975 ORA$BASE        IMAT            V_WORKFLOWWORKITEMII           VIEW
    5608973 ORA$BASE        IMAT            V_WFSTAGETIME                  VIEW
    5608973 ORA$BASE        IMAT            V_WFSTAGETIME                  VIEW
    [UNEXPECTED]Data dictionary corruption detected. Provide details to
    [UNEXPECTED]Oracle Support and ask for a bug to be opened against the
    [UNEXPECTED]Online Patching component of Oracle Application Install.

    /apps1/SID/fs_ne/EBSapps/log/adop/18/adop_xxxxx_xxxxx.log:

#### Cause

This data dictionary issue occurs when a developer promotes customizations
improperly, which violate the online patching standards.

#### Solution

To fix the data dictionary corruption (missing-parent), execute the
following steps:

1. Run the ``$AD_TOP/sql/ADZDDBCC.sql`` script as ``apps user`` to confirm
   whether logical data dictionary corruption exists. Check for corruption in
   the spool log.
2. Run the script ``$AD_TOP/patch/115/sql/adzddmpfix.sql`` as ``sys user`` to
   fix the corruption. In the following sample, 12 corruption objects are fixed.

        SQL> @adzddmpfix.sql

        "---- Fixing Data Dictionary Corruptions (missing parent) ----"
        12 rows deleted.
        Commit complete.
        System altered.
        "---- Compiling invalids ----"
        PL/SQL procedure successfully completed.
        Commit complete.

3. Run the ``$AD_TOP/sql/ADZDDBCC.sql`` script again as ``apps user`` to
   determine if the logical data dictionary corruption is still present.
   a. If no corruption is found, proceed with the upgrade or adop patching-cycle.
   b. If corruption is still present, contact Oracle Support and log a bug.

4. After the issue is resolved, retry the adop prepare step.

### adop prepare failure

Occasionally, the adop prepare step fails. This section shows one possible
prepare error and solution.

#### Error

The following adop prepare error is an Oracle bug:

    Lines #(47-50):
    runMSSrvPortsVal : oacore_server1:7252
    ERROR: Run fs Context variable s_oacore_server_ports value cannot be NULL for oacore_server2
    ERROR: Derived Patch managed server oacore_server2 port : NULL
    ERROR: Failed to clone Run Context file to refresh Patch context file

#### Solution

To resolve this error, execute the following steps:

1. Change the sample target server and SID in the following code sample to the
   port and paths reported in the error, and execute code to fix this issue.

        perl $AD_TOP/patch/115/bin/adProvisionEBS.pl \
        ebs-delete-managedserver \
        -contextfile=/apps1/SID/fs1/inst/apps/SID_server/appl/admin/SID_server.xml -managedsrvname=oacore_server2 \
        -servicetype=oacore -logfile=$APPLRGF/TXK/delMS_oacore_server2.log

        perl $FND_TOP/patch/115/bin/txkSetAppsConf.pl -contextfile=/apps1/SID/fs1/inst/apps/SID_server/appl/admin/SID_server.xml \
        -configoption=removeMS -oacore=server.cm.charter.com:7252

2. Retry adop prepare after the fix is applied.

### Forms object generation failure

Sometimes, when applying patches with ``adop phase=apply patches=123456``, the
forms objects might not generate successfully, which causes the adop session to
quit without showing the ``Patch continue prompt Y/N``.

#### Error

For example, the following Oracle Forms objects did not generate successfully:

    inv     forms/US        INVMWBIV.fmx

#### Solution

Restart the failed patch session from the patch directory with following commands:

    cd /apps1/SID/fs_ne/EBSapps/patch
    adop phase=apply patches=20609071 restart=yes flags=autoskip

### adop cutover hang

If an adop cutover hangs or a server has crash or reboot issues in the middle
of the adop cutover phase, execute the following steps to fix the issue and
then proceed with the patch process.

#### Solution

1. Make sure no services or processes are running from the PATCH file system.
2. Ensure that the Weblogic Admin Server and Node Manager are running on the run
   file system. Execute the following commands to check the status:

        $ adadminsrvctl.sh status
        $ adnodemgrctl.sh status

3. Execute the following commands:

        $ adop phase=abort
        $ adop phase=cleanup cleanup_mode=full
        $ adop phase=fs_clone force=yes

4. Run an empty adop cycle to make sure there is no issue in the adop cutover
   by executing the following command:

        $adop phase=prepare, finalize, cutover, cleanup cleanup_mode=full

5. Start a fresh adop prepare and apply patches.
6. After the apply step, complete the rest of the adop phases including finalize,
   cutover, and cleanup.

### Patch abort

If a patching cycle fails and you cannot resolve the issue quickly, you can
abort the patching cycle and return to normal runtime operation, which drops
the patch edition.

You can abandon a patching cycle (without applying any patches) by running the
following command:

    $ adop phase=abort

**Important:** You can only use this command before successful completion
of the cutover phase. After cutover, the system is running on the new edition,
and the ``abort`` command is no longer possible for that patching cycle.

Aborting a patching cycle drops the patch edition, but you must then run the
cleanup and fs\_clone phases before starting a new patching cycle. The cleanup
must be a full cleanup. The following example demonstrates this sequence of
events:

    $ adop phase=prepare
    $ adop phase=apply patches=123456
    [Patch application encounters problems and you want to abort]
    $ adop phase=abort
    $ adop phase=cleanup cleanup_mode=full
    $ adop phase=fs_clone

Optionally, you can combine the abort and cleanup commands as shown in the
following command:

    $ adop phase=abort,cleanup cleanup_mode=full

**Note:** You cannot abort application of a patch applied in hotpatch mode
(``adop phase=apply apply_mode=hot patch``).

### Conclusion

This collection of known issues and solutions for the adop utility can help
database administrators when they have these or similar issues.
