---
layout: post
title: "Security Hardening for Sitecore Environments"
date: 2016-08-09 10:22
comments: false
author: Bruce Lee, Grant Killian, Kelly Rusk, Jimmy Rudley
published: true
categories:
    - DevOps
---

# Security Hardening for Sitecore Environments

We in the [Rackspace Managed Services for Sitecore](https://www.rackspace.com/digital/sitecore) team work with a variety of enterprise Sitecore projects.  Part of our implementation routine is to complete "security hardening" for Sitecore, which means applying the set of published security best-practices from Sitecore.

Out-of-the-box, Sitecore installs a demo-friendly and developer-ready solution; this is not a configuration suitable for running in production, on many grounds, but our focus here is on security aspects . . . so let's examine the specific Sitecore security hardening recommendations ([Sitecore Security Hardening documentation](https://doc.sitecore.net/sitecore_experience_platform/setting_up__maintaining/security_hardening)) each in turn and share how we, at Rackspace, apply the recommendations.

<!-- more -->

Sitecore publishes a variety of security recommendations for their product.  At Rackspace, we've combined those published items together into a cohesive security hardening program.

## Sitecore's Individual Security Recommendations

1. Deny anonymous users access to key folders
2. Disable client RSS feeds
3. Secure the file upload functionality
4. Improve the security of the website folder
5. Increase login security
6. Limit access to certain file types
7. Protect PhantomJS
8. Protect media requests
9. Remove header information from responses sent by your website

Here is how we at Rackspace approach each of the above.

To understand each of the following topics, know that we initialize key PowerShell variables as follows:
    
    $site = get-website -name 'SitecoreClientSite'
    $webConfigPath = "{0}\web.config" -f $site.physicalPath

Recommendation Number 1. [Deny anonymous users access to key folders](https://doc.sitecore.net/sitecore_experience_platform/setting_up__maintaining/security_hardening/configuring/deny_anonymous_users_access_to_a_folder)

> While the Sitecore documentation walks you through how to do this by pointing and clicking on the server, when you have so many Sitecore environments to work with (we manage in excess of 100 environments and the list keeps growing...), PowerShell is the key execution context:

    $filterString = "/system.Webserver/security/authentication/anonymousauthentication"
    $app_ConfigLocation = "{0}/App_Config" -f $iisWebSiteName
    $adminLocation = "{0}/sitecore/admin" -f $iisWebSiteName
    $debugLocation = "{0}/sitecore/debug" -f $iisWebSiteName
    $ShellWebserviceLocation = "{0}/sitecore/shell/webservice" -f $iisWebSiteName

    Set-WebConfigurationProperty -filter $filterString -name enabled -value false -Location $app_ConfigLocation
    Set-WebConfigurationProperty -filter $filterString -name enabled -value false -Location $adminLocation
    Set-WebConfigurationProperty -filter $filterString -name enabled -value false -Location $debugLocation
    Set-WebConfigurationProperty -filter $filterString -name enabled -value false -Location $ShellWebserviceLocation


Recommendation Number 2. [Disable client RSS feeds](https://doc.sitecore.net/sitecore_experience_platform/setting_up__maintaining/security_hardening/configuring/disable_client_rss_feeds)

> Again, the Sitecore documentation assumes you're manually working with the IIS server; we turn to PowerShell instead:

    [xml] $webConfigXML = Get-Content $webConfigPath
    $targetName = "Sitecore.FeedRequestHandler"
    $nodePath = "configuration/system.webServer/handlers/add[@name='{0}']" -f $targetName
    $node = $webConfigXML.SelectSingleNode($nodePath)
    if($node -ne $null)
    {
      $webConfigXML.configuration.'system.webServer'.handlers.RemoveChild($node)
    }
    $webConfigXML.Save($webConfigPath)


Recommendation Number 3. [Secure the file upload functionality](https://doc.sitecore.net/sitecore_experience_platform/setting_up__maintaining/security_hardening/configuring/secure_the_file_upload_functionality)

> Sitecore documentation walks through the multi-step process.  While we make extensive use of PowerShell, again, we also store a copy of the UploadFilter.config and UploadFilter.dll in our Rackspace CDN for purposes of consistency and convenience.  Here's the full PowerShell for how we handle the measures outlined in Sitecore's documentation:

    $psPath = "MACHINE/WEBROOT/APPHOST/{0}/upload" -f $site.name
    $filter = "system.webServer/handlers/@AccessPolicy"
    Set-WebConfiguration -Filter $filter -Value "Read" -PSPath $psPath

    $psPath = "MACHINE/WEBROOT/APPHOST/{0}/temp" -f $site.name
    $filter = "system.webServer/handlers/@AccessPolicy"
    Set-WebConfiguration -Filter $filter -Value "Read" -PSPath $psPath

    $xml = [xml](get-content $webConfigPath) 
    foreach( $item in  $xml.configuration."system.webServer".modules.add )             
    {
        if( $item.name -eq "SitecoreUploadWatcher" )                                                 
        {
              $xml.configuration."system.webServer".modules.RemoveChild($item);   
        }
    }
    $xml.Save($webConfigPath)

    $sitecoreRoot = $site.physicalPath			
    $downLoadURI = "https://Guid-Guid-Guid.rackcdn.com/SitecoreResources/UploadFilter.config" 
    $downLoadZipPath1 = "C:\rs-pkgs\SecurityHardening.UploadFilter.config"
    Invoke-WebRequest -Uri $downLoadURI -OutFile $downLoadZipPath
    $downLoadURI = "https://Guid-Guid-Guid.rackcdn.com/SitecoreResources/Sitecore.UploadFilter.dll"
    $downLoadZipPath2 = "C:\rs-pkgs\Sitecore.UploadFilter.dll"
    Invoke-WebRequest -Uri $downLoadURI -OutFile $downLoadZipPath
    $WebsiteBin = "{0}\bin" -f $sitecoreRoot 
    $WebsiteConfig = "{0}\app_config\include" -f $sitecoreRoot 
    Copy-Item -Path $downLoadZipPath1 -Destination $WebsiteConfig
    Copy-Item -Path $downLoadZipPath2 -Destination $WebsiteBin


Recommendation Number 4. [Improve the security of the website folder](https://doc.sitecore.net/sitecore_experience_platform/setting_up__maintaining/security_hardening/configuring/improve_the_security_of_the_website_folder)

> At Rackspace, we have a library of PowerShell scripts that handle the installation of Sitecore and adhere to the official installation guide for each version.  The "Data" folder is located outside the "Website" folder as part of this process.  Instead of sharing the entire set of scripts, which amounts to **a lot** of statements that aren't relevant to this material about security hardening, I'll share a snippet specifically handling the default *DataFolder.config.example* that comes out of the box with Sitecore:

    $dataFolderConfigPath = "{0}\DataFolder.config.example" -f $sitecoreAppIncludeDirectory
    [xml]$dataConfigXML = Get-Content $dataFolderConfigPath
    $dataConfigXML.configuration.sitecore.'sc.variable'.attribute.'#text' = $sitecoreDataDirectory
    $dataConfigXML.Save($dataFolderConfigPath)
    $newFilename = (Get-ChildItem $dataFolderConfigPath).BaseName
    Rename-Item -Path $dataFolderConfigPath -NewName $newFilename

Recommendation Number 5. [Increase login security](https://doc.sitecore.net/sitecore_experience_platform/setting_up__maintaining/security_hardening/configuring/increase_login_security)

> Sitecore points to a couple main steps for this security hardening measure.  The first step is all about ensuring SSL is used for Sitecore login pages.  While Sitecore's documentation includes an ASP.Net example on how to do this, that would be added to the custom solution code for a project, at Rackspace we prefer a different approach.  

For a Sitecore **Content Management (CM) server**, the Sitecore client login portal is set to require SSL at the IIS site level (such as https://CMServer.domain.com/sitecore).  An alternative would be to use an IIS URL Rewrite rule to redirect traffic from *https://CMServer/domain.com/sitecore/login.aspx* to *https://CMServer.domain.com/sitecore/login.aspx* at the IIS config level.  We'd do the same for  the */sitcore/admin/login.aspx* page.  

For a Sitecore **Content Delivery (CD) server**, the client login is disabled since we do not anticipate non-admin users logging in to the Sitecore client on these servers.  Part of how we configure a CD server is to remove or restrict access to the client.  Sometimes teams like to use administrative utility pages on the CD servers, so we would leverage IP restrictions set at the IIS server level to allow access only from the loopback 127.0.0.1.  This ensures the admin pages are accessible when the browser is initiated from the CD server itself.  For most implementations, the CD servers are behind a load balancer.   SSL offloading is often configured at the load balancer appliance so that this relieves the web servers from the burden of encrypting and decrypting traffic sent via SSL.  In the case where access to the /sitecore/admin pages are necessary from locations remote from the local CD server, SSL should be used to protect logins passed via the /sitecore/admin/login.aspx.  Do consider if the requirement to access /sitecore/admin/ pages from a non-local browser outwieghs the benefit of SSL offloading configured at the load balancer.  We'd generally discourage opening this functionality to the non-local browser, but different clients have different needs.

One additional note on this topic: in order to implement SSL for the /sitecore/admin/ pages, the SSL cert would need to be installed at each IIS web server.  Creating a redirect at the IIS web server potentially results in an infinite redirect loop.  During the 1st trip, a user's ssl traffic enters at the load balancer, get descrypted and arrives at the web server unencrypted . . . the web server sees this and redirects the user to come back to the load balancer as SSL.  This can be avoided by scoping the SSL redirect to /sitecore/admin/login.aspx provided one does not access these admin pages through the load balancer.

Sitecore's documentation points out a method of handling this through .Net code in the context of IIS, but just because one **can** handle this SSL enforcement that way doesn't mean it's the best choice for every implementation.

> The second step to this "Increase login security" measure is to turn off auto complete of user name for the login pages.  We apply the following Sitecore config patch to accomplish this:

    <configuration xmlns:patch="https://www.sitecore.net/xmlconfig/">
      <sitecore>
        <settings>
      <setting name="Login.DisableAutoComplete">
        <patch:attribute name="value">true</patch:attribute>
      </setting>
      <setting name="Login.DisableRememberMe">
        <patch:attribute name="value">true</patch:attribute>
      </setting>
      <setting name="Login.RememberLastLoggedInUserName">
        <patch:attribute name="value">false</patch:attribute>
      </setting>
    </settings>
      </sitecore>
    </configuration>

Oddly, the *Login.RememberLastLoggedInUserName* is not part of Sitecore's published practices . . . but this is certainly a good measure to take in securing the login prompts.  We drop this .config patch into our app_config/include/Z.Rackspace directory.

Recommendation Number 6. [Limit access to certain file types](https://doc.sitecore.net/sitecore_experience_platform/setting_up__maintaining/security_hardening/configuring/limit_access_to_xml_xslt_and_mrt_files)

> The above piece of documentation is some of the most confusing from Sitecore -- it appears to mix instructions for "Classic" App Pools with newer "Integrated Mode" App Pools.  I think it would be better to have two specific pages for this security hardening measure, one for each of the two app pools.  With that being said, since at Rackspace we only work on 64-bit architectures and do not support customers running "Classic" App Pool mode, we make use of the following Powershell to work through the necessary xml configuration changes (a patch .config will not work in this scenario, since we're dealing with web.config files beyond Sitecore's patching context):

    $psPath = "MACHINE/WEBROOT/APPHOST/{0}" -f $site.name
    $filter = "system.webServer/handlers/"

    New-WebHandler -Path *.xml -Verb * -Type "System.Web.HttpForbiddenHandler" -Name "xml (integrated)" -Precondition integratedMode -PSPath $psPath
    New-WebHandler -Path *.xslt -Verb * -Type "System.Web.HttpForbiddenHandler" -Name "xslt (integrate)" -Precondition integratedMode -PSPath $psPath
    New-WebHandler -Path *.config.xml -Verb * -Type "System.Web.HttpForbiddenHandler" -Name "config.xml (integrate)" -Precondition integratedMode -PSPath $psPath
    New-WebHandler -Path *.mrt -Verb * -Type "System.Web.HttpForbiddenHandler" -Name "mrt (integrate)" -Precondition integratedMode -PSPath $psPath

Recommendation Number 7. [Protect PhantomJS](https://doc.sitecore.net/sitecore_experience_platform/setting_up__maintaining/security_hardening/configuring/phantomjs_and_security_hardening)

> [PhantomJS](https://phantomjs.org/) is a powerfull tool for "headless" browser automation.  Sitecore uses it for capturing screenshots of URLs.  The heart of PhantomJS is an .exe in the dataFolder\tools\phantomjs directory of the Sitecore installation.  This functionality isn't typically used on CD servers, so Sitecore recommends removing it entirely from those environments.  To do this, one deletes the phantomjs directory and removes the pipeline configuration for this activity:

    $dataFolderConfigPath = "{0}\App_Config\Include\DataFolder.config" -f $site.physicalPath
    [xml] $dataFolderConfigXML = Get-Content $dataFolderConfigPath
    $dataFolderValue = $dataFolderConfigXML.configuration.sitecore.'sc.variable'.attribute.'#text'
    $phantomToolPath = "{0}\tools\phantomjs" -f $dataFolderValue
    Remove-Item -Recurse -Path $phantomToolPath
    
Altering the Sitecore pipeline is accomplished via .config patching as follows:

    <configuration xmlns:patch="https://www.sitecore.net/xmlconfig/">
      <sitecore>
        <pipelines>
          <getScreenShotForURL>
            <patch:delete />
          </getScreenShotForURL>
        </pipelines>
      </sitecore>
    </configuration>
    
Recommendation Number 8. [Protect Media Requests](https://doc.sitecore.net/sitecore_experience_platform/setting_up__maintaining/security_hardening/configuring/protect_media_request)

> Sitecore has a mechanism to ensure the validity of dynamically scaled media requests.  

[Read some details of this here](https://kirkegaard-at.blogspot.com/2015/06/media-hash-and-resizing.html).  If your Sitecore error logs contain messages such as *ERROR MediaRequestProtection: An invalid/missing hash value was encountered. The expected hash value...* then this is the feature giving you challenges.  I won't dive deep into this, but suffice it to say you should use Sitecore controls (sc:image) for rendering media or use a pattern of *Sitecore.Resources.Media.HashingUtils.ProtectAssetUrl(theMediaUrl)* instead of just the *MediaManager.GetMediaUrl* method for rendering media links.

> Returning to the task at hand, Sitecore recommends that you edit the Media.RequestProtection.SharedSecret setting in the App_Config/Include/Sitecore.Media.RequestProtection.config file.  This ensures a unique key to your implementation, instead of using the out-of-the-box key provided by the Sitecore installation.  Be sure to use the *same* key for all the Sitecore servers in the solution!  We accomplish this via patch .config as follows:

    <configuration xmlns:patch="https://www.sitecore.net/xmlconfig/">
      <sitecore>
        <settings>
          <setting name="Media.RequestProtection.SharedSecret">
            <patch:attribute name="value">911edb71-aab3-4a1a-aba1-7ef61de116f</patch:attribute>
          </setting>
        </settings>
      </sitecore>
      </configuration>

I should note that we generate a new guid per customer installation, ensuring a unique secret value is in place.

Recommendation Number 9. [Remove header information from responses sent by your website](https://doc.sitecore.net/sitecore_experience_platform/setting_up__maintaining/security_hardening/configuring/remove_header_information_from_responses_sent_by_your_website)

> There are a few HTTP headers that are good to remove, so web server information isn't easily obtained by casual observation of the IIS responses.  We accomplish this starting with this PowerShell:   

    $webConfigPath = "{0}\web.config" -f $site.physicalPath
    [xml]$webConfigXML = Get-Content $webConfigPath
    $webConfigXML.configuration.'system.web'.httpRuntime.SetAttribute("enableVersionHeader","false")
    $webConfigXML.Save($webConfigPath)
    $psPath = "MACHINE/WEBROOT/APPHOST/{0}" -f $site.name
    $filter = "system.webServer/httpProtocol/customHeaders"
    Remove-WebConfigurationProperty -PSPath $psPath -Filter $filter -Name . -AtElement @{name='X-Powered-By'}
    Write-Host "Missing change from the Sitecore recommendations regarding 'Remove the X-AspNetMvc-Version HTTP header' -- that's an implementation specific element that should come from source control etc.  But don't forget!" -ForegroundColor Red

> Note the PowerShell writes a **red alert** to the output, reminding you of the need to apply the final measure in the solution code for the Sitecore site.  The Sitecore documentation suggests editing global.asax for this, but we recommend an approach more like how Akshay Sura does at [the bottom of this post](https://www.akshaysura.com/2016/08/02/secure-sitecore-headers-are-a-headache-but-nothing-we-cannot-solve/).  Consider using a custom HTTP Module instead of monkeying with Global.asax.  This guidance also applies for IOC initialization logic in Global.asax, too, but that's not especially a security related measure. 

We've combined all of these 9 sections into a [single PowerShell script one can download](https://gist.github.com/grant-killian/a6b00ccbfe28b40b76181fbb369f5c02).  Be sure you understand what each section does.  For example, recommendation #7 doesn't apply to most Sitecore CM environments.

This isn't the end of the process of securing a Sitecore implementation; this is more like a start.  This addresses the security measures as recommended by Sitecore.  Every Sitecore project has unique aspects, and this script should not replace careful evaluation and understanding of the risks to each scenario.  At Rackspace, our [managed services for Sitecore team](https://www.rackspace.com/digital/sitecore) follows this script as our baseline and works with each customer to tailor our efforts to their particular needs. 
