---
layout: post
title: This week in Information Security (week of June 15th)
date: '2015-06-15 23:59'
comments: true
author: Charles Neill
published: true
categories:
  - Security
---

Welcome back to *This week in Information Security*! Sorry if you missed us last week, but posts should follow the schedule you're used to going forward. This week, we have news of two high-profile compromises, a few hair-raising hardware/firmware vulnerabilities, tools from DARPA for searching the "deep" and "dark" web, an opinion piece about vulnerability embargoes in open source software, and more. Finally, we wrap up the week with a fun, interactive article from Bloomberg about the meaning of code and the people and culture that produce it.

As always, you can find me on Twitter [@ccneill][twitter] if you have any thoughts on this post.

<!-- more -->

### News / opinions

- [__FBI official: Companies should help us 'prevent encryption above all else'__][fbi_encryption] - Last week Michael B. Steinbach, the assistant director of the FBI's Counterterrorism Division, gave testimony that puzzled many, claiming that the FBI was working with technology companies "to build technological solutions to prevent encryption above all else." This is just another in a long line of statements by law enforcement about the need to introduce a government "front door" into encryption standards. As I've mentioned in previous posts, cryptography experts argue that ["front doors" in encryption are very hard or impossible to get right][encryption_backdoors], and, generally speaking, [are not a good idea][cloudflare_golden_key]. We're still facing the consequences of [weakened][freak] [encryption][weakdh], or "[export-grade encryption][export_encryption]," that was introduced in the last episode of the "crypto wars" in the '90s.

- [__Why the "biggest government hack ever" got past the feds__][opm_hack] - In other government news, a huge breach of the Office of Personnel Management (OPM) potentially exposed the personal information of millions of past and current federal employees. Ars Technica digs into the details of how this might've happened, citing a 2007 report from the Inspector General's office that labeled OPM's security a "material weakness." The Inspector General also found that "OPM [did] not maintain a comprehensive inventory of servers, databases, and network devices. In addition, [they] were unable to independently attest that OPM has a mature vulnerability scanning program." Some fear that the stolen information could be used to unmask or threaten undercover agents or spy-agency employees, or to submit [fraudulent tax returns to the IRS][irs], as happened with roughly 100,000 taxpayers' information during the 2015 tax season.

- [__Kaspersky Lab cybersecurity firm is hacked__][kaspersky] - A new breed of malware dubbed 'Duqu 2.0' has been found targeting Kaspersky Lab, an antivirus vendor from Russia, via previously-undisclosed vulnerabilities in Microsoft products (Microsoft Word is mentioned specifically). The firm believes that the attack was targeting new technologies, and some speculate it could also have been an attempt to spy on Kaspersky's customers, as was the case with the RSA hack that was confirmed several years ago, though Kaspersky [denies that any interference with its systems took place][kaspersky2]. The original version of the [Duqu malware][duqu] seems to be related to the [Stuxnet worm][stuxnet] used to attack Iranian nuclear facilities.

- [__The hidden costs of embargoes__][embargoes] - Red Hat has released a blog post discussing the advantages and disadvantages of using "embargoes" to coordinate vulnerability releases with open source projects. They call out the fact that most open source projects don't really have processes or tools in place to deal with developing in the dark so to speak. Their code repositories, their CI/CD infrastructure, their bug reporting systems, etc. are mostly public, so developing a fix in private means potentially not leveraging the expertise of the community or existing testing infrastructure, which can lead to incomplete patches that have to be updated later. It is also worth noting that if one security researcher has found an issue, there is nothing preventing others from doing so. The blog post suggests that embargoes be used sparingly, and that most security bugs be treated just like other bugs. This way, a larger number of eyes can be focused on the problem at once, thus giving the project the greatest chance of releasing a fully functional patch quickly.

### Security research

- [__Why Stegosploit isn't an exploit__][stegosploit] - Some of you may remember the research I mentioned last week about a tool called "Stegosploit" that claimed to be able to embed malicious exploit code into an image file, which could be triggered by a user simply viewing the image in their browser. A new article from researcher Christian Bundy says that this is at best an exaggeration, claiming that the exploit will only work if the attacker can embed the image within an HTML `<script>` tag. Anyone familiar with cross-site scripting will tell you that if you're able to inject a `<script>` tag into a legitimate site, you don't need an image to do nasty things - you've already won. If true, this means that Stegosploit isn't much more than a way to obfuscate attacks, rather than a truly novel way to smuggle them through a previously undiscovered channel.

- [__How apps track your location without asking for permission__][mobile_location] - Researchers at Trustlook have released some interesting research showing how an Android app can acquire users' location data, even if the app doesn't explicitly ask for the well-known "Location" permission. It is possible to retrieve the [BSSIDs][bssid] of WiFi networks the user has scanned, as well as signal strength for those networks, even with WiFi disabled on the phone. The BSSID can be plugged into a service like [WiGLE][wigle], which tracks the BSSIDs of WiFi networks around the world, to get a surprisingly accurate picture of the user's location.

### Vulnerabilities

- [__The Memory Sinkhole - Unleashing an x86 design flaw allowing universal privilege escalation__][x86] - Researcher Christopher Domas will present a talk at this year's Black Hat Conference detailing a flaw in the x86 architecture that could be used by attackers to gain privileged access to low-level bits of the processor that are normally off-limits. He claims that he will be releasing a proof-of-concept of the attack during the talk. It will be interesting to see if he is "allowed" to give a presentation that has such high potential for abuse, or if it will be cancelled at the last minute, like in the case of the Carnegie Mellon researchers who were [prevented from giving a talk about de-anonymizing Tor][tor] at last year's Black Hat conference.

- [__The Empire Strikes Back Apple - how your Mac firmware security is completely broken__][mac_firmware] _(H/T Ed Ray)_ - __UNFIXED__ - A researcher looking into recent attacks on Apple firmware [(1)][mac_firmware2] [(2)][mac_firmware3] has discovered that by simply putting a Mac to sleep and waking it back up, an attacker is allowed to overwrite the BIOS and introduce a rootkit into the UEFI, making the attack much simpler than those detailed in the past. More Apple firmware vulnerabilities [might be announced][mac_firmware4] at the DEFCON hacking conference in August.

- [__Mongo BSON Injection: Ruby Regexps Strike Again__][bson] _(H/T [Josh Gibbs][jgibbs])_ - __FIXED__ - Egor Homakov ([@homakov][egor]) details an issue in the Ruby BSON gem that can create DoS or BSON injection, depending on the version of BSON in use. The vulnerability hinges on the fact that Ruby, unlike most other languages, treats regular expressions as multi-line expressions by default. What does this mean?

If I have this regular expression:

    /^http:\/\/[^\n]+$/

Rather than only matching strings like this, as would be the case with many other languages:

    http://test.com

Ruby will also match strings like this:

    javascript:alert(1);/*
    http://test.com
    */

Egor has a [great post from a few years ago][ruby_regex] about this issue. The Ruby on Rails security guide [calls out this issue][ruby_regex2] and suggests using "\A" and "\z", which will be treated as the beginning and end, respectively, of the whole string, rather than matching on one line in a multi-line string. The latest version of the gem (3.0.4) can be obtained [here][bson2].

### Tools

- [__MEMEX__][memex] - A few months ago, DARPA open sourced code from a project called MEMEX which is intended to provide developers with tools to create more advanced search engines than are common today. MEMEX has already been used to [combat human trafficking][memex2], helping to secure a conviction of a human trafficker in New York City. The tools are wide-ranging in their abilities, but some examples include [Formasaurus][memex3], a tool to detect types of HTML forms (e.g. login, search, contact, etc.) and [Splash][memex4] a lightweight, HTTP-based browser emulator written in Python.

### Random link of the week

- [__What is code?__][whatiscode] - This is a long read from Bloomberg that seeks to answer the question "What is code?" with great pictures, examples, explanations, and a liberal sprinkling of humor throughout. Whether you're a seasoned developer, a project manager trying to manage a team of developers, or a recent graduate of a learn-to-code bootcamp program, this article will likely amuse you, and might even teach you something interesting along the way.

[twitter]: https://twitter.com/ccneill

[fbi_encryption]: http://www.washingtonpost.com/blogs/the-switch/wp/2015/06/04/fbi-official-companies-should-help-us-prevent-encryption-above-all-else/
[encryption_backdoors]: https://blog.agilebits.com/2015/04/29/back-doors-are-bad-for-security-architecture/
[cloudflare_golden_key]: https://keybase.io/blog/2014-10-08/the-horror-of-a-secure-golden-key
[freak]: https://freakattack.com/
[weakdh]: https://weakdh.org/
[export_encryption]: http://en.wikipedia.org/wiki/Export_of_cryptography_from_the_United_States
[opm_hack]: http://arstechnica.com/security/2015/06/why-the-biggest-government-hack-ever-got-past-opm-dhs-and-nsa/
[irs]: http://www.washingtonpost.com/blogs/federal-eye/wp/2015/05/26/hackers-stole-personal-information-from-104000-taxpayers-irs-says/
[kaspersky]: http://www.bbc.com/news/technology-33083050
[kaspersky2]: https://securelist.com/blog/research/70504/the-mystery-of-duqu-2-0-a-sophisticated-cyberespionage-actor-returns/
[duqu]: http://en.wikipedia.org/wiki/Duqu
[stuxnet]: http://en.wikipedia.org/wiki/Stuxnet
[embargoes]: https://securityblog.redhat.com/2015/06/10/the-hidden-costs-of-embargoes/

[stegosploit]: https://medium.com/@christianbundy/why-stegosploit-isn-t-an-exploit-189b0b5261eb
[mobile_location]: http://blog.trustlook.com/2015/06/02/how-apps-tracking-your-location-without-asking-for-permission/
[bssid]: http://en.wikipedia.org/wiki/Service_set_%28802.11_network%29#Basic_service_set_identification_.28BSSID.29
[wigle]: https://wigle.net/

[x86]: https://www.blackhat.com/us-15/briefings.html#the-memory-sinkhole-unleashing-an-x86-design-flaw-allowing-universal-privilege-escalation
[mac_firmware]: https://reverse.put.as/2015/05/29/the-empire-strikes-back-apple-how-your-mac-firmware-security-is-completely-broken/
[mac_firmware2]: http://events.ccc.de/congress/2014/Fahrplan/events/6129.html
[mac_firmware3]: http://blog.cr4.sh/2015/02/exploiting-uefi-boot-script-table.html
[mac_firmware4]: https://www.defcon.org/html/defcon-23/dc-23-speakers.html#Kovah
[bson]: http://sakurity.com/blog/2015/06/04/mongo_ruby_regexp.html
[jgibbs]: https://twitter.com/quizzicaljosh
[egor]: https://twitter.com/homakov
[ruby_regex]: http://homakov.blogspot.ru/2012/05/saferweb-injects-in-various-ruby.html
[ruby_regex2]: http://guides.rubyonrails.org/security.html#regular-expressions
[bson2]: https://rubygems.org/gems/bson/versions/3.0.4

[memex]: http://opencatalog.darpa.mil/MEMEX.html
[memex2]: http://www.scientificamerican.com/article/human-traffickers-caught-on-hidden-internet/
[memex3]: https://github.com/TeamHG-Memex/Formasaurus
[memex4]: https://github.com/scrapinghub/splash

[whatiscode]: http://www.bloomberg.com/graphics/2015-paul-ford-what-is-code/
