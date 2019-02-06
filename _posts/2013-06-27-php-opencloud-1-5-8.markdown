---
layout: post
title: 'php-opencloud now supports Cloud Monitoring &amp; OpenStack Heat'
date: '2013-06-28 08:00'
comments: true
author: Hart Hoover
published: true
titlecase: false
categories:
  - SDK
---
Version 1.5.8 of [php-opencloud][1] is now available. In this release the PHP
SDK now supports [OpenStack Heat][2] as well as [Rackspace Cloud Monitoring][3].
You can read the [release notes][4] for information related on what has changed.
In this post, we will take a look at how to set up a Cloud Monitoring alarm using
php-opencloud.<!-- more --> More documentation on configuring Cloud Monitoring
is available in the php-opencloud [docs][5].

### Alarms

Alarms bind alerting rules, entities, and notification plans into a logical unit.
Alarms are responsible for determining a state (```OK```, ```WARNING``` or
```CRITICAL```) based on the result of a check, and executing a notification plan
whenever that state changes. You create alerting rules by using the alarm DSL.
For information about using the alarm language, refer to the
[reference documentation](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/alerts-language.html).

#### Setup

```php
require_once 'path/to/lib/php-opencloud.php';

use OpenCloud\OpenStack;
use OpenCloud\CloudMonitoring\Service;

$connection = new OpenStack(
	RACKSPACE_US, // Set to whatever
	array(
		'username' => 'foo',
		'password' => 'bar'
	)
);

$monitoringService = new Service($connection);
```

Be aware that alarms are sub-resources of entities, so you need to associate an
alarm to its parent entity before exploiting its functionality.

```php
$entity = $monitoringService-resource('entity');
$entity->get('enAAAA'); // Get by ID

$alarm = $monitoringService->resource('alarm');
$alarm->setParent($entity); // Associate
```

#### Create alarm

```php
$alarm->create(array(
	'check_id' => 'chAAAA',
	'criteria' => 'if (metric["duration"] >= 2) { return new AlarmStatus(OK); } return new AlarmStatus(CRITICAL);',
	'notification_plan_id' => 'npAAAAA'
));
```

#### List alarms

```php
$alarmList = $alarm->listAll();

while ($alarm = $alarmList->Next()) {
	echo $alarm->id . PHP_EOL;
}
```

#### Get, update and delete alarm

```php
$alarm->id = 'newAlarmId';

// Get data
$alarm->get();

// Update
$alarm->update(array(
	'criteria' => 'if (metric["duration"] >= 5) { return new AlarmStatus(OK); } return new AlarmStatus(CRITICAL);'
));

// Delete
$alarm->delete();
```

More information on php-opencloud is available at <http://php-opencloud.com>


[1]: http://php-opencloud.com/
[2]: https://wiki.openstack.org/wiki/Heat
[3]: http://www.rackspace.com/cloud/monitoring/
[4]: https://github.com/rackspace/php-opencloud/releases
[5]: https://github.com/rackspace/php-opencloud/tree/master/docs/userguide/Cloud%20Monitoring