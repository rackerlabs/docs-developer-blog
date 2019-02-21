---
layout: post
title: This week in Information Security (week of July 13th)
date: '2015-07-13 23:59'
comments: true
author: Charles Neill
published: true
categories:
  - Security
---

After 2 weeks off, we're back with another week in information security! We'll dive into several high-profile breaches at the Office of Personnel Management (again) and Hacking Team, a malware creator that counts several governments and law enforcement agencies as customers. The Hacking Team breach uncovered a nasty Adobe Flash 0day that they had discovered and not previously reported, which has been seen in live attacks both before and after public disclosure. On a lighter note, we also have some great guides and tools for you this week.

As always, you can find me on Twitter [__@ccneill__][twitter] if you have any thoughts on this post.

<!-- more -->

### News / opinions

- [__Hacking of Government Computers Exposed 21.5 Million People__][opm] - It's been pretty much impossible to avoid hearing about the hacking of the Office of Personnel Management, which was first disclosed about a month ago (I first wrote about it [here][twiis_jun15]). Well, it just got worse. The OPM announced yesterday that 21.5 million more people who had applied for background checks for federal employment, as well as their spouses and cohabitants, had their personal information compromised by a related attack. This information included things like social security numbers, fingerprints, health and financial history, and more. The director of the OPM, Katherine Archuleta, has [resigned][opm_resignation] under political pressure from many in Congress. She had previously testified that this data was not encrypted because "it is not feasible to implement on networks that are too old." ([Reference][opm_encryption])

- [__'Hacking Team' Gets Hacked! 400GB of Data Dumped Over the Internet__][hackingteam] - Italian malware/spyware creators Hacking Team, who provide services to governments and law enforcement agencies around the world, were apparently hacked last week. Hundreds of gigabytes of sensitive information has been leaked and is available via torrent. Their Twitter account was also hacked and used to distribute the stolen files. Several interesting things have come to light as a result, such as a [previously-unreleased Flash 0day][hackingteam_flash] that was described as "the most beautiful Flash bug for the last four years" by a member of Hacking Team, and a [BGP hijacking attack][hackingteam_bgp] carried out by an Italian ISP.

- [__Security gurus deliver coup de grace to US govt's encryption backdoor demands__][crypto_wars] - Well-respected security researchers such as Whitfield Diffie, Bruce Schneier, Ronald Rivest, Matt Blaze, Ross Anderson, and others have released [a paper (PDF)][crypto_wars_paper] aimed at discouraging the weakening or breaking of encryption, which has been championed by FBI officials and others, including [UK Prime Minister David Cameron][crypto_wars_cameron]. The paper looks back to the first iteration of the 'crypto wars' that took place in the mid-nineties, when claims of 'going dark' prompted similar calls for mandated backdoors in encrypted communications, and examines the overwhelming negative impacts and extreme technical difficulty of implementing such proposals today. This comes as James Comey, Director of the FBI, was [testifying to Congress][crypto_wars_comey] last week about the necessity of such controls to allow law enforcement to gain access to the communications of bad actors.

- [__"We take security seriously", otherwise known as "We didn't take it seriously enough"__][serious] - _(H/T Herb Jackson)_ - Troy Hunt, a security researcher at Microsoft, posted a blog post last week lambasting software companies for their commitment to security (or lack thereof). He provided examples of several companies saying that they "take security seriously," right after they were hacked. This caused quite a stir in the security community, and several [people][serious2] [criticized][serious3] the article for being unrealistic and unfair. At the end of the day, while these companies likely really do want to be as secure as possible, there is always some level of insoluble uncertainty with security, and it doesn't necessarily make sense to pay infinite dollars to prevent ANY attack, at the expense of running your actual business profitably.

### Security research

- [__A month with BADONIONS__][badonions] - Tor is widely used to provide privacy for individuals, governments, and everyone in between, but recent research shows that there are at least a number of bad actors operating exit nodes and sniffing Tor traffic. This researcher set up a honeypot and accessed it with unique passwords for each Tor exit node they used, and monitored for re-use of those passwords. She discovered that roughly 16 Tor exits that she tested attempted to log into the page with the password she used, meaning they were actively sniffing and attacking Tor users. This underscores the need, [as mentioned on the Tor website][tor_disclaimer], to use encryption at all times while using the Tor network.

### Vulnerabilities

- [__Adobe Flash explot that was leaked by Hacking Team goes wild; patch now!__][flash_0day] - __PATCHED__ - As mentioned above, the disclosures following a massive data dump from Italian firm Hacking Team included a previously-undisclosed Adobe Flash exploit. This exploit has quickly found its way into malicious malware kits and the popular Metasploit framework, and it has been observed in the wild. It was even [able to exploit Google Chrome][flash_0day_chrome], which is considered the hardest browser to attack in some respsects due to its unique security controls, in at least one real-world case. You can find patches for your system [here][flash_0day_patches].

- [__Information about the recent OpenSSL bug (for techies without infosec chops)__][openssl_post] - _(H/T Laurens Van Houtven)_ - __PATCHED__ - This post explores the details of the [OpenSSL advisory][openssl_advisory] released on Thursday that patched a critical issue in the way certificate verification worked, and provides information about how it might affect you. Thankfully, this issue was introduced in a fairly recent version of OpenSSL, and few stable operating systems were affected. Affected OpenSSL versions are >= 1.0.1n and >= 1.0.2b. Known affected Linux distributions are Fedora stable, Debian testing and unstable, ArchLinux testing, Ubuntu 15.10 (unstable). Homebrew, a popular package manager for OS X also shipped a vulnerable version for a while (1.0.2c). If you are using an affected version, you should patch ASAP!

- [__Django Security releases issued: 1.8.3, 1.7.9, 1.4.21__][django] - __PATCHED__ - A number of vulnerabilities have been patched in the popular Django framework, including 2 denial-of-service issues and a possible header injection issue. All previous versions of Django 1.8, 1.7, and 1.4 are affected. Patches are listed at the bottom of this advisory.

### Reference / tutorials

- [__Using Encryption and Authentication Correctly__][enc_and_auth] - This tutorial describes how to properly use encryption together with message authentication to build secure systems that provide confidentiality, integrity, and authenticity. It looks at a number of examples of the right and wrong way to use encryption and keyed-hash message authentication code (HMAC). The code is mostly geared toward a PHP audience, but the information should be readily transferable to other languages. Great read!

- [__Two-Factor-Authentication with SSH__][ssh_mfa] - In this post, the author explains how to set up two-factor authentication (2FA) for SSH logins on FreeBSD (though the process should be mostly applicable to other Linux/Unix distros). 2FA has gotten a lot of attention recently after several breaches (including the OPM breach discussed above) have highlighted the insecurity of single-factor/password authentication, and privileged SSH access is definitely something worth protecting with 2FA.

### Tools

- [__zxcvbn (Password strength testing tool)__][zxcvbn] - Dropbox has a library that can be used to evaluate the security of a given password, looking at things like common dictionary words, common character permutations, repetitions, and more. For example, while other password complexity systems might say a password like "hello!!!!!!!!!!" was secure, zxcvbn recognizes that this is just a dictionary word + a repeated character, which it estimates can be cracked almost instantly. This tool has been around for a while, but I was just made aware of it recently while reading a Stack Exchange answer about [real entropy in passwords][entropy]. You can see it in action [here][zxcvbn_demo].

- [__Awesome Shell__][awesome_shell] - From the repository readme: "A curated list of awesome command-line frameworks, toolkits, guides and gizmos." I have to agree that this is an absolutely awesome list, and includes all kinds of useful tools and reference materials, like [fzf][fzf], a CLI fuzzy finder, [marker][marker], a shell command bookmark tool, and much more.

### Random link of the week

- [__How to undo (almost) anything with Git__][git_fix] - Github recently posted a great article on their blog describing how to undo a number of "oops" scenarios when using Git, like pushing a bad commit or tracking a file you don't want to track. Note: these steps are not sufficient for removing e.g. API keys if you've checked them in at some point. If you need to do that, [Github has you covered there too][github_fix]

[twitter]: https://twitter.com/ccneill

[opm]: http://www.nytimes.com/2015/07/10/us/office-of-personnel-management-hackers-got-data-of-millions.html?_r=0
[twiis_jun15]: https://developer.rackspace.com/blog/this-week-in-infosec-jun-15/
[opm_resignation]: http://www.nytimes.com/2015/07/11/us/katherine-archuleta-director-of-office-of-personnel-management-resigns.html
[opm_encryption]: http://arstechnica.com/security/2015/06/encryption-would-not-have-helped-at-opm-says-dhs-official/
[serious]: http://www.troyhunt.com/2015/07/we-take-security-seriously-otherwise.html?m=1
[serious2]: https://www.lvh.io/posts/they-do-take-security-seriously.html
[serious3]: https://news.ycombinator.com/item?id=9834099
[hackingteam]: http://thehackernews.com/2015/07/Italian-hacking-team-software.html
[hackingteam_flash]: http://thehackernews.com/2015/07/flash-zero-day-vulnerability.html
[hackingteam_bgp]: http://blog.bofh.it/id_456
[crypto_wars]: http://www.theregister.co.uk/2015/07/08/security_giants_publish_paper_destroying_government_encryption_plans/
[crypto_wars_paper]: http://dspace.mit.edu/bitstream/handle/1721.1/97690/MIT-CSAIL-TR-2015-026.pdf?sequence=8
[crypto_wars_cameron]: http://www.businessinsider.com/bruce-schneier-david-cameron-proposed-encryption-ban-destroy-the-internet-2015-7
[crypto_wars_comey]: https://www.eff.org/deeplinks/2015/07/fbis-revival-crypto-wars-part-ii-continues-two-hearings-congress

[badonions]: https://chloe.re/2015/06/20/a-month-with-badonions/
[tor_disclaimer]: https://www.torproject.org/download/download-easy.html.en#warning

[openssl_post]: https://www.lvh.io/posts/todays-openssl-bug-for-techies-without-infosec-chops.html
[openssl_advisory]: https://www.openssl.org/news/secadv_20150709.txt
[django]: https://www.djangoproject.com/weblog/2015/jul/08/security-releases/
[flash_0day]: http://arstechnica.com/security/2015/07/adobe-flash-exploit-that-was-leaked-by-hacking-team-goes-wild-patch-now/
[flash_0day_chrome]: http://arstechnica.com/security/2015/07/hacking-teams-flash-0day-potent-enough-to-infect-actual-chrome-user/
[flash_0day_patches]: https://www.adobe.com/products/flashplayer/distribution3.html

[enc_and_auth]: https://paragonie.com/blog/2015/05/using-encryption-and-authentication-correctly?resubmit=true
[ssh_mfa]: http://sysconfig.org.uk/two-factor-authentication-with-ssh.html

[zxcvbn]: https://github.com/dropbox/zxcvbn
[entropy]: http://security.stackexchange.com/questions/92726/how-secure-is-snowdens-margaretthatcheris110sexy-password
[zxcvbn_demo]: https://dl.dropboxusercontent.com/u/209/zxcvbn/test/index.html
[awesome_shell]: https://github.com/alebcay/awesome-shell
[fzf]: https://github.com/junegunn/fzf
[marker]: https://github.com/pindexis/marker

[git_fix]: https://github.com/blog/2019-how-to-undo-almost-anything-with-git
[github_fix]: https://help.github.com/articles/remove-sensitive-data/
