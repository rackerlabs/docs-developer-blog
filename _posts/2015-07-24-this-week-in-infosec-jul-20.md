---
layout: post
title: This week in Information Security (week of July 20th)
date: '2015-07-24 23:59'
comments: true
author: Charles Neill
published: true
categories:
  - Security
---

Hey, folks! Lots of scary vulnerabilities today affecting Windows, Internet Explorer, OS X, OpenSSH, and WordPress core. Unfortunately, several of them are still unpatched at the time of writing this. We also have some research into remotely hacking cars to do an attacker's bidding over their cellular network, comparisons between security experts and non-experts in security habits and, finally, some research looking at the huge amount of data exposed to the public Internet by outdated MongoDB nodes that don't use authentication.

As always, you can find me on Twitter [__@ccneill__][twitter] if you have any thoughts on this post. Hope you enjoy it. Stay safe!


<!-- more -->

### News / opinions

- [__Oops! Adult Dating Website Ashley Madison Hacked; 37 Million Accounts Affected__][ashley_madison] - Ashley Madison, an online dating site that caters to married people looking for extramarital affairs, has been hacked, potentially affecting roughly 37 million people. A group called "The Impact Team" apparently took issue with Ashley Madison's policy of charging users to delete their personal data from the company's servers, and the hackers claim that that deletion itself was not effective. They claim that Ashley Madison saved the payment details, used to pay for the data deletion service, after the deletion had occurred. The hackers are threatening to release Ashley Madison's users' data - account information, names, addresses, and more.

### Security research

- [__Hackers remotely kill a Jeep on the highway - with me in it__][jeep] - Security researchers Charlie Millier and Chris Valasek have demonstrated, in real world conditions, that they are able to take over many functions of a Jeep Cherokee while it is operating normally. The author of this piece saw first-hand what they were capable of. At first, they did silly things like turn on his windshield wipers and crank up his stereo, but they were also able to disable his brakes while he was driving the car, which ended with him crashing it into a ditch (he was unharmed). The vulnerability lies somewhere in the Uconnect system that Chrysler uses for things like navigation and offering Wi-Fi to the car's occupants, and the Jeep Cherokee isn't the only model affected. The researchers believe that this issue affects any Chrysler car built from late 2013 through early 2015. They will disclose more information about their research at the upcoming Blackhat Conference in Las Vegas.

- [__New research: Comparing how security experts and non-experts stay safe online__][safety] - Google has released some interesting new research that looks at the differences between security experts and non-experts in their security habits online. The differences are quite significant and suggest something of a failure in the security community to communicate the most important best practices to non-experts. Google will present [a paper on their findings (PDF)][safety_pdf], "...no one can hack my mind: Comparing Expert and Non-Expert Security Practices," at the Symposium on Usable Privacy and Security this week. Here is a graphic showing some of the differences they discovered:

![Findings from new Google security research]({% asset_path 2015-07-24-this-week-in-infosec-jul-20/safety_practices.png %})

Source: [googleonlinesecurity.blogspot.com][safety]

- [__It's the Data, Stupid!__][mongodb] - Shodan, which monitors publicly-accessible online services, has a new blog post looking at the huge number of MongoDB databases that are exposed to the public Internet without any authentication. Shodan had almost 30,000 accessible databases in its index as of July 18th (you can see [a report of their findings here][mongodb_report]). The most shocking statistic to me is the sheer amount of data that is vulnerable: some 595 TERRABYTES. Apparently, this stems from old versions of MongoDB that listened by default on '0.0.0.0' instead of localhost. This was patched some time ago but, apparently, a lot of folks are still running old versions that listen on all interfaces by default.

### Vulnerabilities

- [__OS X 10.10 DYLD_PRINT_TO_FILE Local Privilege Escalation Vulnerability__][os_x] - __NO OFFICIAL PATCH__ - A serious vulnerability in OS X has been discovered that allows a malicious user to easily elevate their privileges to root if they have the ability to execute commands as a normal user. Essentially, the issue allows an attacker to write to any file on the system as if they had root privileges. This could be used to write your standard user to the /etc/sudoers file, for example. There is currently no patch from Apple, but the researcher who released the details of the vulnerability has also released [a kernel extension][os_x_kernel] that can be applied as a temporary solution while Apple fixes the bug more thoroughly. You can check [Apple's security updates page][os_x_security] to get the patch when it is eventually released.

- [__Bug in widely used OpenSSH opens servers to password cracking__][openssh] - __NO OFFICIAL PATCH__ - If you have a server that runs OpenSSH and you're accepting passwords for authentication, you're about to get some bad news. The latest version of OpenSSH has a vulnerability that allows attackers to take advantage of the "interactive keyboard" functionality to send thousands of passwords via one SSH connection. The SSH connection is usually closed after a few failed login attempts, but this issue takes advantage of the fact that OpenSSH will allow you to open thousands of password prompts upon connecting and will accept password attempts from each of them. Brute force attacks against SSH are already probably one of the most common attacks taking place online today, and they just got a lot worse. No word yet on the [OpenSSH site][openssh_security] about a fix at the time of this posting.

- [__Four RCE Zero-Day Flaws Plague Internet Explorer: ZDI__][ie] - __NO OFFICIAL PATCH__ - Researchers from HP's Zero-Day Initiative have dropped 4 0days on Microsoft's Internet Explorer browser today, after reporting them to Microsoft more than 6 months ago. Microsoft had requested to extend the deadline to July 19th, which ZDI did, but Microsoft did not deliver patches in time, so ZDI decided to release the issues publicly so that users can be aware of them and, presumably, avoid using Internet Explorer until patches are available.

- [__Hacking Team Leak Uncovers Another Windows Zero-Day, Fixed in Out-of-Band Patch__][windows_font] - __PATCHED__ - Another Microsoft vulnerability popped up this week, this one the result of the Hacking Team compromise that we discussed [in last week's post][last_week]. It is a particularly nasty one, so bad that Microsoft offered [a patch for it outside its normal patching schedule][windows_font_patch]. Almost all versions of Windows appear to be affected. The issue resides in some code that handles Open Type fonts and, apparently, the exploit is even capable of escaping Chrome's sandbox when the victim visits a malicious page in their browser. Both code execution and privilege escalation are possible using this vulnerability. This is the second time Microsoft has had to patch some serious issues with the Adobe Type Manager Font Driver (ATMFD) recently ([other issues were reported in late June][windows_font_2]).

- [__WordPress 4.2.3 Security and Maintenance Release__][wp_vuln] - __PATCHED__ - WordPress has patched a cross-site scripting vulnerability in versions 4.2.2 and below. The vulnerability has not been disclosed publicly, but the description states that it would "allow users with the Contributor or Author role to compromise the site." If you have not enabled automatic updates, check out [this article on the WordPress Codex][wp_auto_update] about configuring them.

### Reference / tutorials

- [__HowTo: Privacy & Security Conscious Browsing__][browser_howto] - This is a great Gist describing steps you can take to prevent being tracked by advertisers or malicious actors and to just generally be safe when browsing online. The author takes a look at several different browsers, with recommendations of privacy settings and 3rd party plugins for how to configure the browser to be as secure/private as possible.

### Tools

- [__SecLists__][seclists] - This is an OWASP project to allow security testers to quickly and easily plug common payloads into their security tests. From the repository description: "SecLists is the security tester's companion. It is a collection of multiple types of lists used during security assessments. List types include usernames, passwords, URLs, sensitive data grep strings, fuzzing payloads, and many more." Basically, these are curated lists of strings that can be used to, for example, test for SQL injection, search for sensitive information like passwords in code repositories, or audit users' passwords to ensure they meet complexity requirements and aren't known, commonly-used passwords. The lists come from all over the place, like [FuzzDB][fuzzdb], as well as individual contributors like RSnake and others.

### Random link of the week

- [__Row hammering in JavaScript__][row_hammering] - _H/T Jonathan Evans_ - Security researcher @lavados recently posted a tantalizing screenshot claiming that he has achieved [DRAM row-hammering][row_hammering2] using JavaScript in FireFox. I'm still waiting on the edge of my seat for the paper describing his technique but, for now, I'll just leave you with the horrifying possibility of privilege escalation via JavaScript. See [Google Project Zero's post on the subject][gpz_dram] if you want to learn more about the technical details of DRAM row-hammering to effect privelege escalation.

![JavaScript row-hammering (apparently)]({% asset_path 2015-07-24-this-week-in-infosec-jul-20/row_hammer.png %})

Source: [@lavados' Twitter][row_hammering]


[twitter]: https://twitter.com/ccneill

[ashley_madison]: http://thehackernews.com/2015/07/adult-dating-website.html

[jeep]: http://www.wired.com/2015/07/hackers-remotely-kill-jeep-highway/
[safety]: http://googleonlinesecurity.blogspot.com/2015/07/new-research-comparing-how-security.html
[safety_pdf]: https://www.usenix.org/system/files/conference/soups2015/soups15-paper-ion.pdf
[mongodb]: http://thehackernews.com/2015/07/MongoDB-Database-hacking-tool.html
[mongodb_report]: https://www.shodan.io/report/OID7V1zw

[os_x]: https://www.sektioneins.de/en/blog/15-07-07-dyld_print_to_file_lpe.html
[os_x_kernel]: https://github.com/sektioneins/SUIDGuard
[os_x_security]: https://support.apple.com/en-us/HT201222
[openssh]: http://arstechnica.com/security/2015/07/bug-in-widely-used-openssh-opens-servers-to-password-cracking/
[openssh_security]: http://www.openssh.com/security.html
[ie]: http://www.securityweek.com/four-rce-zero-day-flaws-plague-internet-explorer-zdi
[windows_font]: http://blog.trendmicro.com/trendlabs-security-intelligence/hacking-team-leak-uncovers-another-windows-zero-day-ms-releases-patch/
[windows_font_patch]: https://technet.microsoft.com/library/security/MS15-078
[windows_font_2]: http://j00ru.vexillium.org/?p=2520
[last_week]: https://developer.rackspace.com/blog/this-week-in-infosec-jul-13/
[wp_vuln]: https://wordpress.org/news/2015/07/wordpress-4-2-3/
[wp_auto_update]: https://codex.wordpress.org/Configuring_Automatic_Background_Updates

[browser_howto]: https://gist.github.com/atcuno/3425484ac5cce5298932

[seclists]: https://github.com/danielmiessler/SecLists
[fuzzdb]: https://code.google.com/p/fuzzdb/

[row_hammering]: https://twitter.com/lavados/status/619164699972792320
[row_hammering2]: https://en.wikipedia.org/wiki/Row_hammer
[gpz_dram]: http://googleprojectzero.blogspot.com/2015/03/exploiting-dram-rowhammer-bug-to-gain.html
