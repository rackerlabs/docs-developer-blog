---
layout: post
title: This Week in Information Security (Week of May 25th)
date: '2015-05-28 23:59'
comments: true
author: Charles Neill
published: true
categories:
  - Security
---

This week we have information about the much-talked-about LogJam vulnerability in SSL/TLS, and several other issues that received less attention, but are scarier in my opinion (e.g. the buffer overflow in NetUSB and the DoS vulnerability in IPsec). We take a brief look at some recent vulnerabilities involving race conditions, affecting companies like Facebook, Dropbox, and Starbucks. We also look at some new research from Google about the effectiveness (or lack thereof) in using "security questions" like "what was your first pet's name?" or "what's your favorite kind of food?" (Spoiler: they're terrible in practice). Finally, for our random link of the week we have an opinion piece calling for the death of the PowerPoint, which sounds great, right?!

As always, you can find me on Twitter [@ccneill][twitter] if you have any thoughts on this post.

<!-- more -->

# News / Opinions

- [__Privacy behaviors after Snowden__][snowden] - A study published in the ACM looks at how user behavior has changed since the relevations of former NSA contractor Edward Snowden, finding that none of the indicators that the author monitored changed significantly in the long-term. The one exception was increased interest in Snowden himself, but the author points out that this doesn't correlate to increased user interest in privacy. I'm not sure that the indicators that were monitored give a full picture since I would argue that parts of the dataset are more representative of users that are less inclined toward downloading or using third party solutions for privacy (users of MSIE, Bing). Still, this is probably the most comprehensive look at user behavior so far in the wake of what the author calls "PRISM day," when details of NSA snooping programs were revealed.

- [__Downloading software safely is nearly impossible__][putty] - This article explores the difficulty of trying to download a verified, safe version of the Windows SSH client PuTTY, but the frustrations the author faces are by no means unique to PuTTY. The author looks at concerns of ownership of domains/download locations, lack of SSL, use of MD5 for checksums, and plenty more. This article is all the more relevant since a trojanized version of PuTTY [has been making the rounds][putty2].


# Security Research

- [__Timeshifter: transmissions of data through time based covert channels across a network__][timeshifter] - This is a tool that can hide messages inside the normal stream of network traffic by delaying packets by a known amount. This method makes intercepting messages harder, because the message doesn't reside in the actual packet data, but the timing between packets.

- [__Hacking Starbucks for unlimited coffee__][starbucks] - Race conditions seem to be growing in prevalance recently (see [here][racecond] and [here][racecond2] for recent examples), or at least they are being discussed publicly with more frequency. This week, a researcher at Sakurity found that he was able to exploit a race condition in Starbucks' gift card system that allowed him to inflate his balance by quickly transferring money from one card to another and the system not subtracting the transferred amount from one card before adding it to the other, essentially an example of the [double spending problem][racecond3]. If you're interested in learning more about race conditions in web applications, [this post][racecond4] has some good information.

- [__Secrets, lies, and account recovery: lessons from the use of personal knowledge questions at Google__][sec_questions] _(PDF)_ - This paper by several researchers at Google looks into the common "forgot my password" questions used by most online services to recover passwords for users who have lost them. Most questions have a relatively high likelihood of being broken with as few as 10 guesses (e.g. 10 good guesses for the question "what is your favorite food?" will match roughly 36.5% of provided answers for English-speaking users). The paper concludes that security questions are sub-optimal at best, and worse than other methods of verificaton such as SMS or email. Google has mostly shifted towards other methods for proving user identity, but security questions may still be used in some cases (e.g. when a user doesn't have access to their phone).

# Vulnerabilities

- [__LogJam__][logjam] - The big news last week was a vulnerability exploiting "export ciphers," somewhat similar to the recent FREAK vulnerability. This particular issue affects the Diffie-Hellman key exchange, and could be exploited by an attacker with a privileged network position. The idea is to modify the cipher list sent by the client to only include export-grade cipher suites, which then forces D-H key exchange to happen with a weaker 512-bit modulus. This weaker modulus can be broken by the attacker, especially if it is using the default D-H parameters provided by the server's SSL library. [This answer on Security Stack Exchange][logjam2] provides some more detail about the vulnerability itself and what to do about it. [Cloudflare][logjam3] also has a great post describing the D-H key exchange process and how this vulnerability breaks it.

- [__KCodes NetUSB: How a small Taiwanese software company can impact the security of millions of devices worldwide__][netusb] - A huge number of routers have been found to use a common library for providing "USB over IP" functionality, which is vulnerable to an easily-exploitable buffer overflow. This functionality is almost always enabled and running by default, even when no USB devices are attached to the networking device. Thankfully, the daemon isn't usually opened to the internet, so an attacker would (theoretically) have to already be on the network to exploit this issue.

- [__IPsec vulnerabilities and software security prediction__][ipsec] - A researcher who goes by the handle "Javantea" has posted a long article that briefly describes a denial-of-service attack on the IKE daemon (part of IPsec), and he suggests that IPsec is now essentially broken. The author's bigger point is not about IPsec itself but about poorly-maintained projects that nonetheless end up on a large number of machines. He dives into a process for filtering out insecure packages from Linux distros, such as measures of active maintenance and number of known security issues, and lists several packages that he believes should be removed from distros' package repositories unless they get better at proactively fixing security issues.

# Reference / Tutorials

- [__Cryptographic right answers__][crypto_answers] - This Gist includes answers to some common (and some not-so-common) cryptography questions, especially geared toward those who are architecting a new system that will use cryptography in some way. Quick read, totally worth it.


# Tools

- [__Regexr__][regexr] - A nifty online tool for creating and evaluating regular expressions, with lots of helpful documentation and the ability to run replacements.

# Random Link of the Week

- [__PowerPoint should be banned__][ppt] - This opinion piece from Katrin Park at the Washington Post argues that PowerPoint should be banned from use by enterprises and other organizations, due to the limiting of conversation and thoughtful examination that PowerPoint enforces. She calls out the Columbia shuttle disaster as an example of vital information being hidden in tiny bullet points, which may have played a part in why NASA took the unfortunate course of action that they did. Whether you agree or disagree with the entire premise, I'd bet a world with fewer PowerPoint decks and more in-depth conversations is probably a better one on balance.


[twitter]: https://twitter.com/ccneill

[snowden]: https://cacm.acm.org/magazines/2015/5/186025-privacy-behaviors-after-snowden/fulltext
[putty]: https://noncombatant.org/2014/03/03/downloading-software-safely-is-nearly-impossible/
[putty2]: https://www.net-security.org/malware_news.php?id=3041

[timeshifter]: https://www.anfractuosity.com/projects/timeshifter/
[starbucks]: https://sakurity.com/blog/2015/05/21/starbucks.html
[racecond]: https://hackerone.com/reports/59179
[racecond2]: https://josipfranjkovic.blogspot.com/2015/04/race-conditions-on-facebook.html
[racecond3]: https://en.wikipedia.org/wiki/Double-spending
[racecond4]: https://defuse.ca/race-conditions-in-web-applications.htm
[sec_questions]: https://static.googleusercontent.com/media/research.google.com/en/us/pubs/archive/43783.pdf

[logjam]: https://weakdh.org/
[logjam2]: https://security.stackexchange.com/questions/89689/what-is-logjam-and-how-do-i-prevent-it
[logjam3]: https://blog.cloudflare.com/logjam-the-latest-tls-vulnerability-explained/
[netusb]: https://blog.sec-consult.com/2015/05/kcodes-netusb-how-small-taiwanese.html?m=1
[ipsec]: https://www.altsci.com/ipsec/

[crypto_answers]: https://gist.github.com/tqbf/be58d2d39690c3b366ad

[regexr]: https://regexr.com/

[ppt]: https://www.washingtonpost.com/posteverything/wp/2015/05/26/powerpoint-should-be-banned-this-powerpoint-presentation-explains-why/?tid=pm_pop_b
