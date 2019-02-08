---
layout: post
title: 'Cloud Auto Scale: Java developer highlights'
date: '2014-01-15 10:30'
comments: true
author: Zack Shoylev
published: true
categories:
  - jclouds
---

One of the big benefits of using the cloud to drive your applications is the
ability to seamlessly scale to meet user demand. Developers will find it easy
to configure how their Rackspace cloud scales by utilizing Rackspace's Cloud
Auto Scale. While SDK support for Auto Scale is available in multiple
languages, here I will demonstrate how to configure it with Java and
Apache [jclouds](http://developer.rackspace.com/#java).

<!-- more -->

An easy way to start using jclouds in your Java projects is by adding the proper maven dependencies to the project pom file. Start by including Cloud Auto Scale to your Java project:

    <dependency>
    	<groupId>org.apache.jclouds.labs</groupId>
    	<artifactId>rackspace-autoscale-us</artifactId>
    	<version>1.7.0</version>
    </dependency>

Once the dependency is in place, instantiate the Auto Scale Api like this:

    AutoscaleApi autoscaleApi = ContextBuilder.newBuilder("rackspace-autoscale-us")
            .credentials(username, apiKey)
            .buildApi(AutoscaleApi.class);

Developers can access the following through the AutocaleApi:

1. Group
1. Policy
1. Webhook

For example:

    groupApi = autoscaleApi.getGroupApiForZone("DFW");
    policyApi = autoscaleApi.getPolicyApiForZoneAndGroup("DFW", groupId);
    webhookApi = autoscaleApi.getWebhookApiForZoneAndGroupAndPolicy("DFW", groupId, policyId);

Here DFW specifies the Dallas.Fort Worth zone (or location). The IDs specify the group or policy you want to modify.

The scaling group is the first important Auto Scale concept to learn. It refers to a set of similarly configured and load balanced servers. The number of machines in the set can grow or shrink in number based on how Scaling Policies are configured or Webhooks executed.

To begin using Auto Scale, a scaling group needs to be created and configured. A "simple" group can be created like this:

      GroupConfiguration groupConfiguration = GroupConfiguration.builder()
            .maxEntities(5)
            .cooldown(2)
            .name(NAME)
            .minEntities(0)
            .metadata(ImmutableMap.of("notes","This is an autoscale group for examples"))
            .build();

      LaunchConfiguration launchConfiguration = LaunchConfiguration.builder()
            .loadBalancers(ImmutableList.of(LoadBalancer.builder().port(8080).id(9099).build()))
            .serverName(NAME)
            .serverImageRef("0d589460-f177-4b0f-81c1-8ab8903ac7d8")
            .serverFlavorRef("2")
            .serverDiskConfig("AUTO")
            .serverMetadata(ImmutableMap.of("notes","Server examples notes"))
            .networks(ImmutableList.<String>of("internal", "public"))
            .personalities(ImmutableList.of(Personality.builder().path("filepath").contents("VGhpcyBpcyBhIHRlc3QgZmlsZS4=").build()))
            .type(LaunchConfigurationType.LAUNCH_SERVER)
            .build();

      List<ScalingPolicy> scalingPolicies = Lists.newArrayList();

      ScalingPolicy scalingPolicy = ScalingPolicy.builder()
            .cooldown(0)
            .type(ScalingPolicyType.WEBHOOK)
            .name(NAME)
            .targetType(ScalingPolicyTargetType.PERCENT_CHANGE)
            .target("1")
            .build();
      scalingPolicies.add(scalingPolicy);

      Group g = groupApi.create(groupConfiguration, launchConfiguration, scalingPolicies);

Multiple components need to be configured to create a working scaling group, as demonstrated above. While the GroupConfiguration setup is straightforward, some explaining might be needed for the LaunchConfiguration and ScalingPolicy.

Remember how the scaling group contains a set of *similarly* configured servers? The LaunchConfiguration determines the configuration of these servers, such as which image gets used, which networks the machine connects to, and so-forth. Personality here specifically refers to any files we want to customize on the image.

Each scaling group also has a number of policies associated with it. These determine when and how the group scales up or down. There are two distinct policy types: schedule and event based (these will be under ScalingPolicyType). The schedule scaling policy gets triggered on specific dates and times, using a cron-like argument. The event policy triggers when a web service call is executed (anonymous execution is available). Here we look at the Webhook type (event-based).

To execute an event-based scaling policy, create a Webhook:

    FluentIterable<WebhookResponse> result = webhookApi.create("SomeName", ImmutableMap.<String, Object>of());

Note that it seems like a scaling policy ID was not specified. However, it was specified when we obtained the webhookApi. To get the anonymous execution URL for the Webhook (this means you do not need to be signed-in to call it):

    webhook.getAnonymousExecutionURI().get()

Here is one way to execute the Webhook (and corresponding scaling policy):

    result = AutoscaleUtils.execute(webhook.getAnonymousExecutionURI().get());

If you look at the execute code, notice that you do not have to do anything to authorize the call. It is usually a good idea to create multiple Webhooks when a policy can be executed from multiple applications (for example). Thus specific Webhooks can be later deleted without affecting the policy.

The full examples code is also [available](https://github.com/jclouds/jclouds-examples/tree/master/rackspace).

