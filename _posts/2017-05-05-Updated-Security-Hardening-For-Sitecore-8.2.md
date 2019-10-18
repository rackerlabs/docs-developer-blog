---
layout: post
title: "Updated security hardening for Sitecore 8.2+"
date: 2017-05-05 00:00
comments: false
author: Grant Killian, Jimmy Rudley, Kelly Rusk, Bruce Lee
authorIsRacker: true
published: true
categories:
    - Devops
---

Last year, we shared [the foundation Rackspace uses for Sitecore security hardening in a blog](https://developer.rackspace.com/blog/Security-Hardening-for-Sitecore-Environments/) on this site.  We're due for an update now that Sitecore has published additional best practices, and, here at Rackspace, we've folded those recommendations into our PowerShell process for securing environments.  The [Rackspace Managed Services for Sitecore team](https://www.rackspace.com/digital/sitecore) incorporates this into our provisioning work program for enterprise Sitecore projects.

<!-- more -->

### Four additional security measures from Sitecore

[The original post on this topic](https://developer.rackspace.com/blog/Security-Hardening-for-Sitecore-Environments/) covers 9 steps that Sitecore recommends you take to improve the security of an implementation.  Recently, there have been 4 additions to this list:

* [Disable WebDav](https://doc.sitecore.net/sitecore_experience_platform/setting_up_and_maintaining/security_hardening/configuring/disable_webdav)
* [Disable SQL Server access from XSLT](https://doc.sitecore.net/sitecore_experience_platform/setting_up_and_maintaining/security_hardening/configuring/disable_sql_server_access_from_xslt)
* [Enforce a strong password policy](https://doc.sitecore.net/sitecore_experience_platform/setting_up_and_maintaining/security_hardening/security_considerations)
* [Change the security hash algorithm](https://doc.sitecore.net/sitecore_experience_platform/setting_up_and_maintaining/security_hardening/configuring/change_the_hash_algorithm_for_password_encryption)

In reality, Sitecore has added a few other notes but the preceding recommendations lend themselves to PowerShell automation.  Advice such as "use SSL everywhere," for example, requires X.509 certificates etc.  We focus on these 4 new steps because they're well within the control of our implementation team.

Here is how we at Rackspace use PowerShell to approach the four additions to Sitecore's recommended practices:

These 4 steps continue [the list begun last year](https://developer.rackspace.com/blog/Security-Hardening-for-Sitecore-Environments/).  For the examples in this post, key PowerShell variables are initialized as follows:

    $site = get-website -name 'SitecoreClientSite'
    $webConfigPath = "{0}\web.config" -f $site.physicalPath

New Recommendation Number 1. [Disable WebDav](https://doc.sitecore.net/sitecore_experience_platform/setting_up_and_maintaining/security_hardening/configuring/disable_webdav)

> Web Distributed Authoring and Versioning (WebDav) is a dated technology at this point because it's a method for dragging and dropping content into Sitecore that is used only in Internet Explorer.  I have worked on a lot of Sitecore implementations, and very few have ever made use of WebDav.  Very few.  WebDav is enabled through a single Sitecore configuration file: App_Config/Include/Sitecore.WebDAV.config.  We disable this file with with the following PowerShell:

	$webDavConfigPath = "{0}\App_Config\Include\Sitecore.WebDAV.config" -f $site.physicalPath
	$webDavConfigDisabledPath = "{0}\App_Config\Include\Sitecore.WebDAV.config.disabled" -f $site.physicalPath
	Rename-Item $webDavConfigPath $webDavConfigDisabledPath

New Recommendation Number 2. [Disable SQL Server access from XSLT](https://doc.sitecore.net/sitecore_experience_platform/setting_up_and_maintaining/security_hardening/configuring/disable_sql_server_access_from_xslt)

> XSLT renderings are another dated technology that most new Sitecore implementations avoid, but the features remain part of the Sitecore platform.  Sitecore recommends disabling the ability for XSLT renderings to interact with SQL Server; it's a precautionary best practice to reduce the security surface area.  To do this, remove the xslExtensions of type "Sitecore.Xml.Xsl.SqlHelper" from the XML defined in App_Config/Sitecore.config as shown in the following PowerShell example:

	$sitecoreConfigPath = "{0}\App_Config\Sitecore.config" -f $site.physicalPath
	$configXML = [xml](get-content $sitecoreConfigPath)
	foreach( $item in  $configXML.sitecore.xslExtensions.extension )
	{
        if( $item.type -eq "Sitecore.Xml.Xsl.SqlHelper, Sitecore.Kernel" )
        {
              $configXML.sitecore.xslExtensions.RemoveChild($item);
        }
	}
    $configXML.Save($sitecoreConfigPath)

New Recommendation Number 3. [Enforce a strong password policy](https://doc.sitecore.net/sitecore_experience_platform/setting_up_and_maintaining/security_hardening/security_considerations)

> Sitecore relies on the .Net Membership class for out-of-the-box security of user credentials and account management.  There are a [variety of properties exposed by the .Net Membership object](https://msdn.microsoft.com/en-us/library/system.web.security.membership_properties%28v=vs.110%29.aspx), and Sitecore recommends implementations alter these settings in a way that is consistent with each organization.  The Membership settings Sitecore installs with are developer-friendly (that's a nice way of saying *not security best practice*), with specific attributes set as follows:

* minRequiredPasswordLength="1"
* minRequiredNonalphanumericCharacters="0"
* maxInvalidPasswordAttempts="256"

> This is low-hanging fruit for a security audit -- single character passwords are laughable for "real" implementations.  Sitecore recognizes this, and their newest documentation suggests tuning these settings for increased security.  At Rackspace, we consult with customers on best-fit but we have automated the full spectrum of options exposed in the web.config file for .Net Membership.  I'll share the full set of commands here, but know that it makes the most sense to be selective about which attributes to employ on each Sitecore implementation.  If you have a comprehensive [RegEx validation defined](https://msdn.microsoft.com/en-us/library/system.web.security.membership.passwordstrengthregularexpression%28v=vs.110%29.aspx), for instance, you probably do not need an explicit value set for a *minRequiredPasswordLength*.

	$webConfigPath = "{0}\web.config" -f $site.physicalPath
	$webConfigXML = Get-Content $webConfigPath
	$node = $webConfigXML.configuration.'system.web'.membership.providers.add | where {$_.name -eq 'sql'}
	$node.SetAttribute("minRequiredPasswordLength", "7")
	$node.SetAttribute("minRequiredNonalphanumericCharacters", "2")
	$node.SetAttribute("maxInvalidPasswordAttempts", "3")
	$node.SetAttribute("requiresQuestionAndAnswer", "true")
	$node.SetAttribute("passwordAttemptWindow", "30") #time window in minutes; default is 10 mins
	#Regex rule example: is greater than seven characters; contains at least one digit; contains at least one non-alphanumeric character:
	$node.SetAttribute("passwordStrengthRegularExpression", "(?=.{6,})(?=(.*\d){1,})(?=(.*\W){1,})")
	$webConfigXML.Save($webConfigPath)

I won't repeat the [.Net Membership documentation](https://msdn.microsoft.com/en-us/library/system.web.security.membership_properties%28v=vs.110%29.aspx) here because it covers each setting (and the inter-relations between settings) in detail.

New Recommendation Number 4. [Change the security hash algorithm](https://doc.sitecore.net/sitecore_experience_platform/setting_up_and_maintaining/security_hardening/configuring/change_the_hash_algorithm_for_password_encryption)

> Sitecore is an extensible platform, and the ability to change which hashing algorithm is used by the out-of-the-box .Net Membership provider has been around for years.  There's a good write-up from last year on [replacing the hashing algorithm](https://blog.baslijten.com/sitecore-security-1-how-to-replace-the-password-hashing-algorithm/) and even from back in 2013 [the concept was being explored](https://kamsar.net/index.php/2013/09/upgrading-sitecores-password-security/).  Just recently, however, Sitecore has published the *recommendation* to do this in an acknowledgement that SHA1 isn't going to cut it in 2017.  In fact, Sitecore now states "you must change the weak default hash algorithm (SHA1) that is used to encrypt user passwords to a stronger algorithm", and it doesn't get more clear than that!

There are a [wide variety of algorithms to pick from](https://msdn.microsoft.com/en-us/library/system.security.cryptography.cryptoconfig%28v=vs.110%29.aspx), but we'll use SHA512 since that's consistent with what Sitecore is recommending.  We use the following PowerShell to configure SHA512 as the hashing algorithm:

	$webConfigPath = "{0}\web.config" -f $site.physicalPath
	$webConfigXML = Get-Content $webConfigPath
	$webConfigXML.configuration.'system.web'.membership.SetAttribute("hashAlgorithmType","SHA512")
	$webConfigXML.Save($webConfigPath)
	$caveat = @"
  		You must reset the passwords for any accounts that used the previous algorithm, including sitecore/admin!  See https://gist.github.com/grant-killian/d2c17ec90adc4b1b99b6089172268571 for an examaple of how you could do this.
	"@
	Write-Host $caveat -ForegroundColor DarkYellow

While it's straight-forward to change the *hashAlgorithmType* attribute to use SHA512, it can be a pain to convert old user passwords to the new format.  The caveat in the above PowerShell points to [a sample page that could be used to reset a Sitecore password](https://gist.github.com/grant-killian/d2c17ec90adc4b1b99b6089172268571).  When standing up a new Sitecore environment and employing the security hardening steps included in this write-up, placing that file temporarily on the server and obtaining a new password through it can be part of the workflow.  Be sure to remove that utility page when you're done, though!

I should mention, there are more sophisticated ways of resetting and obtaining a Sitecore password, but they exceed the scope of this piece focussing on Sitecore's new security hardening recommendations.  There are SQL Server stored procs to reset a password, which could be folded into a process that updates the .Net Membership hashing algorithm etc.  I'll leave that as an exercise for the reader, should they want to pursue this further . . .

To conclude, I'll direct you to a unified PowerShell script that combines [our previous security hardening guidance](https://developer.rackspace.com/blog/Security-Hardening-for-Sitecore-Environments/) with the measures covered in this write-up.  The [full PowerShell is on GitHub and can help you jumpstart this process in your own projects](https://gist.github.com/grant-killian/a6b00ccbfe28b40b76181fbb369f5c02).

Finally, remember that that these security best practices are just a good starting point for a secure Sitecore implementation.  Our [Rackspace Sitecore team](https://www.rackspace.com/digital/sitecore) engages with customers on their particular situations and helps make them successful with the Sitecore platform.  When it comes to security, one size doesn't fit all, but it's nice to have a solid foundation to build on.
