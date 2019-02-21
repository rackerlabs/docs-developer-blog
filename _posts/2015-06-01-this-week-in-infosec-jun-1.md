---
layout: post
title: This week in Information Security (week of June 1st)
date: '2015-06-02 23:59'
comments: true
author: Charles Neill
published: true
categories:
  - Security
---

This week we have some interesting research on the security of many Docker containers in the official Docker Hub repository, showing that a large number of images are vulnerable to severe exploits like ShellShock and Heartbleed. We also look at some research introducing a new attack vector utilizing novel [steganography][stego] to deliver exploits to the browser using nothing but HTML5 and images. In other news, the NSA's phone metadata snooping program has folded (at least temporarily) following a failure of the Senate to extend the relevant provisions of the USA PATRIOT act that authorized the program.

As always, you can find me on Twitter [@ccneill][twitter] if you have any thoughts on this post!

<!-- more -->

### News / opinions

- [__Section 215 expires - for now__][nsa] - EFF is celebrating the lapse of section 215 of the USA PATRIOT act, which authorized the NSA's phone metadata collection program, though they acknowledge that the USA FREEDOM Act will likely reinstate some of these powers in different ways and with more oversight. A vote on the USA FREEDOM Act will likely happen sometime this week. This comes on the heels of a recent [federal appeals court decision][nsa_court] stating that the metadata program was not authorized by federal law and went beyond the bounds of what legislators thought they were voting for in authorizing the USA PATRIOT act.

- [__How is critical 'life or death' software tested?__][testing_software] - A thought-provoking article from Motherboard looks at two approaches for testing software used by airplanes and other so-called 'critical' systems. One method favored by NASA uses formal methods to prove the correctness of software with mathematical proofs and similar. The other method is more of an 'eat your own dogfood' mentality that forces engineers to come along on the first flight tests of aircraft that they write code for. I don't think there's a right answer here, as both methods probably produce much better code quality than typical software development processes, but it's an interesting topic to think about.

- [__Securing email communications from Facebook__][facebook_pgp] - Facebook has announced a new feature that will allow users to upload PGP keys to their profile to sign notification emails sent by Facebook. This is a step to protect data-at-rest that doesn't live on the Facebook website, which already uses high-quality SSL to prevent snooping. The announcement also states that users will be able to share keys with one another without enabling encrypted email notifications, though there aren't many specifics on this portion of the new system. In my reading, it sounds like they're trying to create their own version of [Keybase.io][keybase], a service for sharing, verifying, and utilizing encryption keys that uses user "proof posts" on 3rd party sites like Github and Twitter to verify a user's identity. You can find me on Keybase as [cneill][keybase_profile] if you'd like to see how it works or if you'd like an invitation to the service, which is still in beta. If you're interested in learning more about how to use PGP keys to secure your email, the announcement post has instructions for installing OpenPGP on Windows, Mac, and Linux. Operational security expert [@thegrugq][grugq] has also written a great gist about [how to actually use PGP in practice][grugq_pgp] to secure your email, which goes more in-depth.

- [__Users of Hola VPN service being used for DDoS attack__][hola] - Hola is a VPN service with millions of users that works in a similar way to [Tor][tor], in that users of the service become endpoints that traffic can pass through anonymously. Unlike Tor, the user's participation as a router of anonymized traffic is not an opt-in system, and the user may be unaware that all kinds of terrible traffic might be passing through their connection. This post on 8chan __(Warning: other pages on the 8chan site may be unsafe for work)__ describes a system set up by the Hola creators that allows anyone to pay to send traffic through their anonymous network, which boasts over 9 million unique IPs. This service was apparently used to send massive amounts of traffic to 8chan, ultimately crashing the site. The traffic could not be easily correlated to Hola endpoints, because it bears no extra headers. Furthermore, endpoints lack common open ports like Tor, forcing the 8chan site to require the solving of a CAPTCHA to create new posts.

- [__The creator of Locker ransomware renounces his creation__][locker] - The author of the ransomware known as [Locker][locker_2] has apologized for releasing it and has provided the following information: the Bitcoin addresses it uses, public and private keys, and details about how files are encrypted. The author also claims that all currently encrypted files will be decrypted starting on June 2nd at midnight. __Warning:__ I have not downloaded the file referenced in this pastebin, and take no responsibility if it is indeed malicious. Obviously, you should always be cautious when downloading files online, but it's especially true if you already know the author is a prolific malware creator.


### Security research

- [__Over 30% of official images in Docker Hub contain high priority security vulnerabilities__][docker] - Some research on Docker containers claiming that there are a large number of vulnerable Docker images in the official Docker Hub stirred up a lot of interest last week. While it's true that many images are vulnerable to old exploits, in my opinion, this research is a tiny bit alarmist. One of the most important (and most common) things to do on a new Linux machine is running the equivalent of "apt-get update && apt-get upgrade" to update system packages. In many cases, this will resolve the entire issue of an outdated Docker image. While it's true that a Docker image is often presumed innocent before proven guilty, this re-emphasizes that using a Docker image is not an excuse for not doing responsible package management for your apps. If you're looking for help securing your Docker containers, the researchers who posted this article released a [tool called collector][collector] to analyze Docker images in a scriptable way. Docker has also released [The Docker Bench for Security][docker_bench], which will run the standard [CIS Docker benchmark][docker_cis] tests against a given container. These tests include testing for appropriate file ownership/permissions, logging, firewall rules, and much more. While Bench won't test for all known CVEs in system packages, the CIS guide gives tips for how to audit packages used by your Docker images.

- [__Stegosploit__][stegosploit1] - [@therealsaumil][saumil] has released some excellent research at Hack in the Box showing that one can insert browser exploits into a simple image, and have them execute when the user loads said image in their browser. This is not like previous research where an attacker simply dumps PHP or ASP code into EXIF data and then spoofs the file extension but, instead, it uses HTML5 Canvas to parse JavaScript that can't be detected with a simple EXIF data search, as he demonstrates in the video below.

Here is a YouTube video of Saumil creating an evil image out of his profile picture:

{% youtube O9vSSQIZPlI %}

Here's the evil image being used to exploit an old Internet Explorer bug to drop the attacker into a Meterpreter shell on the victim VM:

{% youtube fAyuOhB4uvo %}

Now to find a [Ghostery][ghostery]-like plugin to block scary images...

- [__Mobile application assessments by the numbers - a whole-istic view__][dan_talk] - I was fortunate enough to attend a San Antonio OWASP talk by DenimGroup CTO Dan Cornell ([@danielcornell][dan_twitter]) last week about his company's experience auditing mobile applications for security issues and the lessons they've learned along the way. The presentation takes data from over 60 engagements with 20 different mobile applications to try to determine what methods work best for finding the most critical security bugs. Unfortunately, it appears that there is no single approach that will find all the bugs you probably care about - it's a combination of manual and automated testing and both source code analysis and black-box testing. The main points I took away from the talk were that the majority of serious issues affecting mobile applications actually come from the server side, not the application itself, and that the tooling for mobile applicaton testing is not as mature as that used to test classic web applications, for example.


### Reference / tutorials

- [__Preventing SQL injection in PHP applications - the easy and definitive guide__][php_sqli] - This is a great article by Paragon Initiative which is essentially an "update" to all the thousands of articles online that more or less state that to prevent SQL injection, you must "sanitize your inputs!" The author's main point is that prepared statements in PHP essentially make SQL injection a thing of the past (with some caveats), and you don't have to do fine-grained input sanitization to leverage it. Paragon also offers a PHP library for easily using prepared statements called [EasyDB][easydb]. If we're ever going to erradicate SQL injection entirely (unlikely, but I can dream, right?), we need more people to take an approach like this to solve the problem holistically, rather than trying to solve every potential edge case on their own.


### Tools

- [__Collector__][collector] - Collector is a tool created to allow scripting against Docker containers, with an eye for security. This was the tool created and used by Banyan to determine how many Docker images in the Docker Hub contained outdated packages with unpatched vulnerabilities. It is extensible, so you can write and run all kinds of tests against your containers with this tool.

- [__Docker Bench for Security__][docker_bench] - As mentioned in the summary of the research into Docker image security, under the "Security Research" category above, Docker Bench can be a helpful tool to test the security of your Docker containers. It can perform the [Docker CIS checks][docker_cis] against a container and tell you if that container is fundamentally insecure in some way. Be forewarned - this will not find EVERY issue that could happen with a Docker container, including testing for CVEs in old system packages. It mainly focuses on good hygeine in areas like file permissions and logging configurations.


### Random link of the week

- [__MIT cheetah robot lands the running jump__][cheetah] - An MIT robot that mimics the shape and movement of a cheetah can now successfully clear tall obstacles in its path while it is running at high speed in an entirely autonomous way, and with no safety harness. Check out the video of this awesome robot in action below:

{% youtube _luhn7TLfWU %}


[stego]: http://en.wikipedia.org/wiki/Steganography
[twitter]: https://twitter.com/ccneill

[nsa]: https://www.eff.org/deeplinks/2015/05/section-215-expires-now
[nsa_court]: http://www.npr.org/sections/thetwo-way/2015/05/07/404898259/federal-court-bulk-collection-of-phone-metadata-is-illegal
[testing_software]: http://motherboard.vice.com/en_uk/read/how-is-critical-life-or-death-software-tested
[facebook_pgp]: https://www.facebook.com/notes/protecting-the-graph/securing-email-communications-from-facebook/1611941762379302?_rdr&_fb_noscript=1
[keybase]: https://keybase.io/
[keybase_profile]: https://keybase.io/cneill
[grugq]: https://twitter.com/thegrugq
[grugq_pgp]: https://gist.github.com/grugq/03167bed45e774551155
[hola]: http://8ch.net/hola.html
[tor]: https://www.torproject.org/
[locker]: http://pastebin.com/1WZGqrUH
[locker_2]: http://www.bleepingcomputer.com/virus-removal/locker-ransomware-information

[docker]: http://www.banyanops.com/blog/analyzing-docker-hub/
[collector]: https://github.com/banyanops/collector
[docker_bench]: https://github.com/docker/docker-bench-security
[docker_cis]: https://benchmarks.cisecurity.org/tools2/docker/CIS_Docker_1.6_Benchmark_v1.0.0.pdf
[stegosploit1]: https://conference.hitb.org/hitbsecconf2015ams/wp-content/uploads/2015/02/D1T1-Saumil-Shah-Stegosploit-Hacking-with-Pictures.pdf
[saumil]: https://twitter.com/therealsaumil
[ghostery]: https://www.ghostery.com/en/
[dan_talk]: http://www.slideshare.net/denimgroup/application-security-assessments-by-the-numbers-owaspappseceu20151
[dan_twitter]: https://twitter.com/danielcornell

[php_sqli]: https://paragonie.com/blog/2015/05/preventing-sql-injection-in-php-applications-easy-and-definitive-guide
[easydb]: https://github.com/paragonie/easydb

[cheetah]: https://www.youtube.com/watch?v=_luhn7TLfWU
