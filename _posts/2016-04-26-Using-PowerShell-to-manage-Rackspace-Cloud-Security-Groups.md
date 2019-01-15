---
layout: post
title: "Using PowerShell to manage Rackspace Cloud Security Groups"
date: 2016-04-26 00:00
comments: true
author: Jose Da Silva
published: true
authorIsRacker: true
authorAvatar: 'http://www.gravatar.com/avatar/e447889c7bb6912e05aa82248c9cf964'
bio: Jose is a long time Racker who enjoys new technology and helping others adopt it since he moves on to the next shiny thing quickly. His day to day is spent with customers designing against flaws and then fixing all the problems that arise from that.
categories:
  - DevOps
  - aws
---

One day I was testing this neat new API feature and was really struggling with those `curl` examples.

"I'm not a browser!" I thought. "Can I have this in a proper scripting or dev language?"

Since I couldn't find it anywhere, I decided to write this tutorial myself.

Everybody talks about Security, and, in the Cloud, sometimes the tools and options available seem confusing or inefficient because they require a lot of repetitive actions. Plus, it's all using Linux tools. And I want to use PowerShell.

Most companies just need a simple means to filter traffic to their Cloud Servers, and so Rackspace has launched, around 2015 and in limited availability, our own implementation of a very useful feature called 'Security Groups'.

<!-- more -->

This is the Rackspace equivalent to features like AWS Security Groups and Azure Network Security Groups; and, using scripting, you can achieve automation of those repetitive tasks, as well as your daily Cloud Server builds.

At the moment, Rackspace Cloud Security Groups is still in Limited Availability in all regions, and it's not yet very well known by most customers, but it is a very powerful tool to secure Cloud Servers and manage access filters with some consistency and ease.

So, customers need to filter traffic on hundreds of Cloud Servers, but they don't really want to do it one at a time, right?  Ideally, a deployment cycle is all automated (or near as), but if you cringe each time a new network requirement calls for rules change, then your process is still manual.

No more! In this post we're going to review what you can do and help you automate this feature using PowerShell. The concepts and basics should be simple enough for you to tweak at will but, if you need help, reach out with questions via Rackspace support channels or post a comment here.


### What are Rackspace Cloud Security Groups?



_"Security groups are named collections of network access rules that enable Rackspace Public Cloud users to specify the types of traffic that are allowed to pass through PublicNet and ServiceNet ports on a Cloud Servers instance."_

[https://support.rackspace.com/how-to/cloud-networks-faq/](https://support.rackspace.com/how-to/cloud-networks-faq/)

Servers can be secured with Rules that work similarly to Access Control Lists which filter traffic based on TCP/IP ports, on TCP, UDP or ICMP protocols, for both IPv4 and IPv6 traffic. Optionally, you can filter by source IP address or range.

Currently, only Inbound rules are supported, but Outbound rules are expected to be available with unlimited availability launch, this year.

It's also important to reiterate the distinction that Security Groups are applied to a network, like PublicNet and ServiceNet, not directly to an instance.

Remember:

**A Security Group is a container for Security Group Rules and can only be applied to resources in the region where it was created.**

Now with the caveats and explanations out of the way, you may want to start using this right away.

First, since it's not in general availability yet, please contact our Support or Service Delivery team to request being added to the beta testing group of customers. It will be provisioned in your service catalogue, to use via the API or portal.

A User Guide can be found here:

[https://developer.rackspace.com/docs/user-guides/infrastructure/cloud-config/network/cloud-networks-product-concepts/security-groups/](https://developer.rackspace.com/docs/user-guides/infrastructure/cloud-config/network/cloud-networks-product-concepts/security-groups/)

So the purpose of this blogpost is to simplify and automate using PowerShell.

Also, I'm not a browser!



### Code

Below are the main sections I intend to cover and will delve in detail in each of them:


 * Let's start with some assumptions that are resolved with your preference of SDK
 * Let's confirm you have access properly configured:
 * Tokens and tidbits
 * List Security Groups
 * Show Security Group per Group ID
 * Delete your Security Group per Group ID
 * Create Security Group Rules
 * List Security Group Rules
 * Show Security Group Rules


Since the API used is an HTTP endpoint, we will be using `Invoke-RestMethod`. The PowerShell SDK should soon be expanded to support this but, in the meantime, here's how you can use it.

 * Let's start with some assumptions that are resolved with your preference of SDK.

   Since we don't want to tattoo the code (hardcoding is bad) with API keys and sensitive information, I'm assuming you have configured user variables in your environment that include:

```sh
$apiuser = [Environment]::GetEnvironmentVariable("apiuser","User")

$apikey = [Environment]::GetEnvironmentVariable("apikey","User")
```

Your control panel will show this information, but a guide is here too:

[https://developer.rackspace.com/docs/cloud-networks/v2/developer-guide/#getting-started](https://developer.rackspace.com/docs/cloud-networks/v2/developer-guide/#getting-started)

Since Security Groups are bound to the region where they were created, we're also configuring:

```sh
$region = [Environment]::GetEnvironmentVariable("region","User")
```

Remember: if needed, you can also create and save these environment variables using PowerShell. For example:

```sh
[Environment]::SetEnvironmentVariable("region","LON","User")

[Environment]::SetEnvironmentVariable("apiuser","your_RS_username_here","User")

[Environment]::SetEnvironmentVariable("apikey","your_API_key_here","User")
```


 * Let's confirm you have access properly configured:

```sh
try
{
    #Set URL
    $URL = "https://identity.api.rackspacecloud.com/v2.0/tokens"

    #Build JSON object with variables
    $auth = New-Object -TypeName psobject -Property @{
        "auth" = @{
            "RAX-KSKEY:apiKeyCredentials"=@{
                "username" = "$apiuser";
                "apiKey" = "$apikey"
            }
        }
    }

    #Convert object to JSON
    $authJSON = $auth | ConvertTo-Json

    # call API
    $request = Invoke-RestMethod  -Uri $URL  -Method Post -Body $authJSON -ContentType "application/json"
}
catch
{
    # error handling
    $ErrorMessage = $_.Exception.Message
    Write-Host "Problem found! Hope this helps:"
    Write-Host $ErrorMessage -ForegroundColor Red

}
```

If you got an error, it was most likely `(401) Unauthorized`, which means go above and fix your apiuser or apikey environment variables.

 * Tokens and tidbits

    Otherwise your request resulted in a wealth of information, including your required authentication token to continue with the rest of these operations:

```sh
# token handling
$token = $request.access.token.id
$authToken = @{"X-Auth-Token" = $token}
```

We also get the service catalogue, which has the full range of available products available to use.

```sh
# service catalog here - range of available products to use and associated IDs
$fullcatalog = $request.access.serviceCatalog
```

And therefore, let's browse the catalog in a lazy (non elegant way).

I'm sure you're already thinking on how to improve the following! Good on you!

```sh
# browing the catalog
foreach ($catalog in $fullcatalog) {

    if ($catalog.name -eq "cloudNetworks")
    {
        $catalogNetwork = $catalog
    }
}
```

Here we also get the tenantID and URI for Cloud Networks operations so we don't need to hardcode it!

Hardcoding is bad, have I said that?

```sh
# useful details here
$tenantId = $catalogNetwork.endpoints.tenantID
$CloudNetworkURI = $catalogNetwork.endpoints.publicURL
```

 * List Security Groups

   You can finally list existing Security Groups (if any were created via the GUI/portal). If you're just following this demo, then go ahead and create something on the portal just to confirm that the below works.

   Go on, I'll wait...

```sh
# List current Security Groups and its Rules
$lstSecGroups = Invoke-RestMethod -Uri "$CloudNetworkURI/security-groups" -Method GET -Headers $authToken  -ContentType application/json

# View them in a pretty way
$lstSecGroups.security_groups | ConvertTo-Json -Depth 6
```

But now comes the fun part!

Let's create one new:

First, define it, then POST it!

```sh
# we're ready to create a NEW Security Group
try{
    #Set URLsc
    $URLsc = "$CloudNetworkURI/security-groups"

    #Build JSON object with variables
    $rbody = New-Object -TypeName psobject -Property @{
            "security_group"=@{
            "name" = "1-new-tcp";
            "description" = "Security Group for webservers"}
            }

    #Convert object to JSON
    $bJSON = $rbody | ConvertTo-Json

    # call API
    $newsgrequest = Invoke-RestMethod  -Uri $URLsc  -Method Post -Headers $authToken -Body $bJSON -ContentType "application/json"

    # view results
    $newsgrequest | ConvertTo-Json -Depth 6
    Write-Host "Created Security Group",$newsgrequest.security_group.id

}
catch
{
    # error handling
    $ErrorMessage = $_.Exception.Message
    Write-Host "Problem found! Hope this helps:"
    Write-Host $ErrorMessage -ForegroundColor Red

}
```

Since the Security Group identifier is a Group ID, and not the name, you could create multiple Security Groups with the same name, but let's NOT do that, ok?

Could be confusing...

If you get error `(409) Conflict`, then you've reached the current limit of 10 Security Groups.

 * Show Security Group per Group ID

   If you ever need to show details on a specific Security Group, you will need its ID.
   So store it or parse it based on your application requirements.

```sh
# if you want to show a specific security group
$URLscId = "$URLsc"+"/"+$newsgrequest.security_group.id #re-using this var because I know it exists in this demo

# call API and display in human readable format
$showSecGroupId = Invoke-RestMethod -Uri $URLscId -Method GET -Headers $authToken  -ContentType application/json
$showSecGroupId | ConvertTo-Json -Depth 6
```

Neat!

 * Delete your Security Group per Group ID

   So I hear you now want to delete it? Make sure nobody is using it...
   Just change method to DELETE, and point to the previous $URLscId

```sh
# Delete your Security Group per Group ID
try{
    Invoke-RestMethod -Uri $URLscId -Method DELETE -Headers $authToken  -ContentType application/json
}
catch
{
    # error handling
    $ErrorMessage = $_.Exception.Message
    Write-Host "Problem found! Hope this helps:"
    Write-Host $ErrorMessage -ForegroundColor Red

}
```

   If there are any errors, it's likely been already deleted! Oops, no undelete available...

 * Create Security Group Rules

   Let's look at the Security Group Rules, because you can't do much with those groups you've created thus far. Each Security Group Rule is associated with a specific Security Group ID, but you have this code so you can easily deploy the same to any other Security Groups you have.
   Since we deleted the last group created, we can't use it.
   But if you're following the demo, I'll just select a random Security Group ID that exists in the account (assuming you have at least one, otherwise please create one).

   You know what they say about assumptions, right?

```sh
# Security Group lottery draw
$lstSecGroups = Invoke-RestMethod -Uri "$CloudNetworkURI/security-groups" -Method GET -Headers $authToken  -ContentType application/json
$random = get-random -Maximum $lstSecGroups.security_groups.Count
$randomgroupid = $lstSecGroups.security_groups | Select-Object -Index $random | Select-Object ID
write-host "Random select Security Group ID: ",$randomgroupid.id

# create a security-group-rule
try{
    #Set URLscRl
    $URLscRl = "$CloudNetworkURI/security-group-rules"

    #Build JSON object with variables
    $rbody = New-Object -TypeName psobject -Property @{
            "security_group_rule"=@{
                "direction" = "ingress";
                "port_range_min" = "80";
                "ethertype" = "IPv4";
                "port_range_max" = "80";
                "protocol" = "TCP";
                "security_group_id" = $randomgroupid.id}
            }

    #Convert object to JSON
    $bJSON = $rbody | ConvertTo-Json

    # call API
    $newsgrrequest = Invoke-RestMethod  -Uri $URLscRl  -Method Post -Headers $authToken -Body $bJSON -ContentType "application/json"

    # view results
    $newsgrrequest | ConvertTo-Json -Depth 6
    Write-Host "Created Security Group Rule",$newsgrrequest.security_group_rule.id

}
catch
{
    # error handling
    $ErrorMessage = $_.Exception.Message
    Write-Host "Problem found! Hope this helps:"
    Write-Host $ErrorMessage -ForegroundColor Red

}
```

   If you got errors, it's likely an invalid Security Group ID.
   Feel free to run the above code multiple times, because it will randomly create rules in any existing Security Groups you have.  Yes, they will be the same, because rules are unique based on the IDs.
   Let's see the mess we've created...

 * List Security Group Rules

```sh
# List security-group-rules
$lstSecGroupRules = Invoke-RestMethod -Uri $URLscRl -Method GET -Headers $authToken  -ContentType application/json
$lstSecGroupRules.security_group_rules | ConvertTo-Json -Depth 6
```

   A bit untidy, so you probably just want to see

 * Show Security Group Rules

   A specific Security Group Rule ID

```sh
# show security-group-rules per Security Group Rule Id
$URLscRlId = "$URLscRl"+"/"+$newsgrrequest.security_group_rule.id #re-using this var because I know it exists in this demo
$showSecGroupRuleId = Invoke-RestMethod -Uri $URLscRlId -Method GET -Headers $authToken  -ContentType application/json
$showSecGroupRuleId | ConvertTo-Json -Depth 6
```

   Or all the Security Group Rules on a specific Security Group ID

```sh
# use random again to make sure it exists
$URLscIdrnd = $URLsc + "/" + $randomgroupid.id
# show security-group-rules per Security Group Id
$showSecGroupIdRules = Invoke-RestMethod -Uri $URLscIdrnd -Method GET -Headers $authToken  -ContentType application/json
$showSecGroupIdRules.security_group | ConvertTo-Json -Depth 6
```

   Now, we're getting to the stage of deleting rules.

 * Delete Security Group Rules

   You can't change existing rules, so you might as well delete and recreate, if needed.

```sh
#	Delete your Security Group Rule per Rule ID
try{
    Invoke-RestMethod -Uri $URLscRlId -Method DELETE -Headers $authToken  -ContentType application/json
}
catch
{
    # error handling
    $ErrorMessage = $_.Exception.Message
    Write-Host "Problem found! Hope this helps:"
    Write-Host $ErrorMessage -ForegroundColor Red

}
```

   If there are errors, it's likely because it's already been deleted.

   Here's a final exercise: You want to remove all the Security Group Rules in a specific Security Group without deleting the group itself.

   And sure you can, but remember to not do this in Production (!!!) since your Cloud Servers would lose all the protection you've spent so many hours (minutes/seconds) creating:

```sh
# Delete all rules within a specific Security Group
$showSecGroupIdRules = Invoke-RestMethod -Uri $URLscIdrnd -Method GET -Headers $authToken  -ContentType application/json
$noRules=0  # I like to count
foreach ($ruleID in $showSecGroupIdRules.security_group.security_group_rules){
    $noRules++
    $URLscRlIdTodelete = $URLscRl+"/"+$ruleID.ID
    Invoke-RestMethod -Uri $URLscRlIdTodelete -Method DELETE -Headers $authToken  -ContentType application/json
write-host "Deleted Rule ID",$ruleID.ID

}
write-host "Deleted $noRules rules"
```

And now, farewell. (Already?)

Thank you for reading and demoing this feature with me.

For clean-up, run:

```sh
# delete all Security Groups created in this demo (actually ALL of them)
# So be careful!
$lstSecGroups = Invoke-RestMethod -Uri "$CloudNetworkURI/security-groups" -Method GET -Headers $authToken  -ContentType application/json
foreach ($groupID in $lstSecGroups.security_groups){
    $URLscIdTodelete = $URLsc+"/"+$groupID.ID
    Invoke-RestMethod -Uri $URLscIdTodelete -Method DELETE -Headers $authToken  -ContentType application/json
    write-host "Deleted Security Group Name",$groupID.Name
}
```

![Output]({% asset_path 2016-04-30-Using-PowerShell-to-manage-Rackspace-Cloud-Security-Groups/nosecgrps.png %})


You should now be equipped to script and develop your own version of the above functionality using the Rackspace Cloud Security Groups feature. This will make your Cloud Servers much more secure while making you feel good about your scripting skills.

No more `curl` for you!

After all, you're not a browser, right?

Eager to try more?
Think you can code better? Hope so!


Check out our API dev guide with all the details:

[https://developer.rackspace.com/docs/cloud-networks/v2/developer-guide/#document-api-operations/sec-group-operations](https://developer.rackspace.com/docs/cloud-networks/v2/developer-guide/#document-api-operations/sec-group-operations)

Thanks!
