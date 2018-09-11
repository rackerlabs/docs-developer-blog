---
layout: post
title: Weekly Security Link Dump (Week of May 11th)
date: '2015-05-12 23:59'
comments: true
author: Charles Neill
published: true
categories:
  - Security
  - architecture
---

Hello! This is the first post in a series that will bring you new and interesting links every week from the perspective of a Rackspace Security Engineer. I try to include links that are useful/interesting to a general audience, so you don't have to be an "uber 1337 h4x0r" to enjoy them. If you have any comments, or if you want to submit a link, feel free to leave a comment or catch me on [Twitter][twitter].

<!-- more -->

## News / Opinions

- [__Lawsuit filed against Lenovo for Superfish backdoor__][lenovo] - A lawsuit has been filed against Lenovo and Superfish Inc. for installing spyware, named Superfish, that worked using man-in-the-middle attacks on user traffic to inject advertisements, on millions of Lenovo PCs. This is on the back of [__more news of serious security failures at Lenovo__][lenovo2] that were revealed in detail last week, in which malware could be installed by using "coffee shop attacks", i.e. man-in-the-middling a public WiFi connection.

- [__Tesla plans to open car doors to all hackers this summer__][tesla] - Tesla is rumored to be planning an event at DEFCON in Las Vegas this summer, to hack on one of their Model S vehicles and detect potential security vulnerabilities. Tesla is currently denying this rumor, but this article's author seems very convinced that this is a diversion, and that an event will indeed happen.

- [__Deprecating non-secure HTTP__][https] - Mozilla released a blog post that surprised quite a few people last week, in which they announced that they would be deprecating HTTP in future versions of Firefox, though the deadline is unknown at this point. This is interesting, because we're still quite far away from free CAs being used by the millions and millions who would have to use them if the entire internet is to migrate to HTTPS. Mozilla isn't the only group wanting to deprecate HTTP. The federal government has also announced [__its intention to only offer HTTPS__][https2] for public government websites.

- [__Back doors are bad for security architecture__][backdoors] - AgileBits, makers of 1Password and Knox, have released a blog post detailing why backdoors, whether they're called "front doors," "golden keys," or any other name, are bad for security architecture. Great read, especially if you're not sure who you side with in the battle between security/privacy advocates and law enforcement, who claim they need such "front doors" to do their jobs and keep us safe.

## Security Research

- [__Boeing 787 software bug can shut down planes' generators IN FLIGHT__][boeing] - A software bug in Boeing's 787 has been discovered that essentially shuts down the plane's generator control units (which control electricity generation for the plane) every 248 days, due to an integer overflow. If all GCUs were started at the same time and overflowed at once, the plane's electricity generation would halt entirely, potentially bricking the plane right out of the sky.

- [__Lawyers threaten researcher over key-cloning bug in high-security lock__][lock] - The security firm IOActive has released details about security issues with a widely-used high-tech physical lock that is currently certified by a number of US government standards. The maker of the lock has filed suit against them, invoking part of the CFAA that prevents reverse-engineering of proprietary systems, again raising the issue of whether researchers should be allowed to release critical security issues to the general public before they are fixed.

- [__The computers are listening - How the NSA converts spoken words into searchable text__][nsa_speech] - Leaked documents from Edward Snowden reveal that the NSA has developed the capability to transcribe voice calls (in 6 languages, including English, Russian, and Mandarin Chinese), into searchable text that can be filtered through the other myriad surveillance systems at their disposal. This signals a huge shift in the costs of surveillance, by at least partially removing the requirement that a human being listen to the calls being scooped up by dragnet surveillance.

## Vulnerabilities

- [__Multiple Docker Vulnerabilities__][docker_vulns] __(PATCH RELEASED)__ - Version 1.6.1 of Docker has been released to address multiple serious CVEs related to privelege escalation and information disclosure. Users are encouraged to upgrade to version 1.6.1 as soon as possible to address these issues.

- [__CVE-2015-3459 - Hospira Lifecare PCA infusion pump allows telnet root login without password__][pacemaker] __(PATCH STATUS UNKNOWN)__ - A security researcher looking into a pump that allows patients to administer their own drugs has found that it is possible to log into it using telnet, with no password. This could obviously go badly in a large number of ways, and his recommendation is not to use the device, until a fix can be confirmed.

- [__BACKRONYM (MySQL SSL downgrade vulnerability)__][backronym] __(NO PATCH <=5.7.2, PATCHED IN 5.7 PREVIEW AND >=6.1.3)__ - Duo Security has released a vulnerability, bearing the tongue-in-cheek name "BACKRONYM", which stands for "Bad authentication causes kritical risk over networks yikes MySQL." The vulnerability concerns SSL/TLS downgrades on MySQL network connections, which could be exploited by [__APTs__][apt] using DNS spoofing. They have provided a tool called [__mysslstrip__][mysslstrip] on Github, that allows you to test your own MySQL installations for issues. As the authors rightly point out (albeit sarcastically), this isn't an "end of the world" vulnerability, but it should still _definitely_ be patched.

- [__Wordpress Multiple XSS Vulnerabilities__][wordpress] __(PATCH RELEASED)__ - It's been a rough couple weeks for blogging platform WordPress, which suffered from a cross-site scripting vulnerability due to the way they handled comments and MySQL truncating text fields at a certain length. This culminated in a release of [WordPress 4.2.1][wordpress2] on April 27. Roughly a week later, they released [version 4.2.2][wordpress] to address a deficiency in the previous patch, and to fix a new DOM-based cross-site scripting issue affecting many Wordpress themes and plugins, including their default themes. It is recommended that users update to 4.2.2 as soon as possible, as attacks have already been observed in the wild.

## Reference / Tutorials

- [__Encrypting your laptop like you mean it__][disk_encryption] - The Intercept has released an in-depth article about how to set up full-disk encryption on several popular platforms (Windows, OSX, and Linux), as well as the benefits and pitfalls to doing so.

- [__Passphrases that you can memorize - but that even the NSA can't guess__][passphrases] - Another great one from The Intercept about creating manageable but extremely secure passwords. Their main recommendation is to use [__diceware__][passphrases2], rolling dice (yes, like the ones you use in Yahtzee!) to generate e.g. a 5 digit number that corresponds to a random word in a dictionary file, and repeating this process several times to create a passphrase composed of a collection of random words. This is very, _very_ hard to brute-force, even if your adversary has your dictionary file, due to the large number of possible words and combinations thereof.

- [__Understanding Docker security and best practices__][docker_security] - Docker has released a blog post with lots of great information about how to secure your Docker containers/Dockerfiles/etc.


## Tools

- [__ccat__][ccat] - ccat, or "colorized cat" functions like the normal UNIX utility, cat, but it will also syntax-highlight code. Handy for debugging, triaging issues, etc.


[twitter]: https://twitter.com/ccneill

[lenovo]: https://www.unitedstatescourts.org/federal/cand/284981/1-0.html
[lenovo2]: http://www.bbc.com/news/technology-32607618
[tesla]: http://www.forbes.com/sites/thomasbrewster/2015/04/28/tesla-opening-car-to-hackers/
[https]: https://blog.mozilla.org/security/2015/04/30/deprecating-non-secure-http/
[https2]: https://https.cio.gov/
[backdoors]: https://blog.agilebits.com/2015/04/29/back-doors-are-bad-for-security-architecture/

[boeing]: http://www.theregister.co.uk/2015/05/01/787_software_bug_can_shut_down_planes_generators/?mt=1430935171609
[lock]: http://arstechnica.com/security/2015/05/lawyers-threaten-researcher-over-key-cloning-bug-in-high-security-lock/
[nsa_speech]: https://firstlook.org/theintercept/2015/05/05/nsa-speech-recognition-snowden-searchable-text/

[docker_vulns]: http://www.openwall.com/lists/oss-security/2015/05/07/10
[pacemaker]: https://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2015-3459
[backronym]: http://backronym.fail/
[apt]: http://en.wikipedia.org/wiki/Advanced_persistent_threat
[mysslstrip]: https://github.com/duo-labs/mysslstrip
[wordpress]: https://codex.wordpress.org/Version_4.2.2
[wordpress2]: https://wordpress.org/news/2015/04/wordpress-4-2-1/

[disk_encryption]: https://firstlook.org/theintercept/2015/04/27/encrypting-laptop-like-mean/
[passphrases]: https://firstlook.org/theintercept/2015/03/26/passphrases-can-memorize-attackers-cant-guess/
[passphrases2]: https://en.wikipedia.org/wiki/Diceware
[docker_security]: https://blog.docker.com/2015/05/understanding-docker-security-and-best-practices/

[ccat]: https://github.com/jingweno/ccat
