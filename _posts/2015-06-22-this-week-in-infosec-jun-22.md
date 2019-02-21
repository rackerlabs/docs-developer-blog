---
layout: post
title: This week in Information Security (week of June 22nd)
date: '2015-06-23 23:59'
comments: true
author: Charles Neill
published: true
categories:
  - Security
---

Welcome to another installment of *This week in Information Security*! This week we have news of a critical vulnerability in millions of Samsung phones, a high-profile compromise of the password management tool LastPass, and a new method for stealing encryption keys via radios, without physically touching the machine in question. We also have tutorials about the basics of cryptography and using the Linux command line, and more!

As always, you can find me on Twitter [__@ccneill__][twitter] if you have any thoughts on this post.

<!-- more -->

### News / opinions

- [__LastPass Hacked__][lastpass] - In a post on their blog released last week, LastPass admitted that their servers had been compromised, exposing users' "email addresses, password reminders, server per user salts, and authentication hashes." Due to their usage of [PBKDF2-SHA256][pbkdf2] with 100k rounds, this compromise isn't as bad as it could be; cracking the obtained hashes will be harder than if something like vanilla MD5 were used. This doesn't mean the hashes are "uncrackable," but LastPass at least did their due dilligence in using one of the best hashing mechanisms available for their passwords. Nonetheless, users are urged to replace their master password for LastPass and to update their passwords on other services if they reused that password elsewhere.

- [__Who Has Your Back?__][effreport] - Responding to the revelations of Edward Snowden, and numerous calls by government officials to limit encryption (and, consequently, user privacy), the Electronic Frontier Foundation (EFF) has released a roundup of a few prevalent companies' policies with regards to releasing their users' information to law enforcement agencies. Their evaluation criteria included things like requiring law enforcement to obtain a warrant to acquire user data, publicly disclosing the company's data retention policies, and publicly advocating against government backdoors in encryption. Several companies got all 5 stars, though others were worryingly lacking. You can find their full evaluation criteria [here][effreport2] and a summary of the report's findings [here][effreport3].

### Security research

- [__Stealing Keys from PCs using a Radio__][radio] - Researchers from Tel Aviv University have released research showing that RSA and ElGamal keys can be recovered using simple, cheap hardware to detect and analyze electromagnetic signals produced by the decryption of a crafted ciphertext. The researchers were able to capture these signals from 50cm away using relatively inexpensive equipment and believe they could increase the range with improved hardware. They constructed a system they call "PITA" to capture signals and store them on an SD card for later decryption, which is small enough to fit inside a small piece of pita bread. A PDF of their technical paper with more details can be found [here][radio2].

- [__This Simple Trick Requires Only Your Phone Number to Hack your Email Account__][emailhacking] - A new video from Symantec demonstrates a relatively easy social engineering attack that can be used to fool a user into providing the details necessary to compromise their account. The attacker simply has to request a password reset code that will be sent to the victim's phone, and then they text the user while impersonating the email provider, asking for that access code. If the victim sends the code back, the attacker can then change the user's password with no further interaction from the victim. Symantec emphasizes that email providers will not text you asking for verification codes - they only use SMS to _send_ verification codes. To protect yourself, never respond to any text messages asking you for passwords or verification codes. Here is a demonstration of the attack:

{% youtube _dj_90TnVbo %}

### Vulnerabilities

- [__Remote Code Execution as System User on Samsung Phones__][samsung] - __UNFIXED__ - A flaw in Samsung's Swift keyboard allows attackers with a privileged network position to execute arbitrary code as the system user on an estimated 600 million Samsung phones via a man-in-the-middle attack, due to the absence of transport layer encryption or cryptographic signatures for packages when downloading language updates. The only protection is a SHA1 checksum provided in a manifest file that is downloaded (without transport encryption) to tell the vulnerable phone which version of the language package to download based on the model of the phone. This is easily bypassed by replacing the legitimate SHA1 value in the manifest with the SHA1 checksum for the attacker's malicious payload. The attack can be carried out with little or no active user interaction and is executed when the phone is restarted. Users are vulnerable regardless of whether or not they use the Swift keyboard by default, and there is no way to disable or uninstall the keyboard. [Samsung's blog post on the subject][samsung2] claims that the KNOX security platform bundled with many recent Samsung phones will mitigate the issue via kernel protections (though this would seem to be contradicted by the video below). The blog also claims that Samsung will release patches for the issue over-the-air via KNOX, though no dates are included and releases will likely vary by device and carrier. Here's a video of the attack in action:

{% youtube uvvejToiWrY %}

For now, the vulnerability author recommends not connecting to untrusted WiFi networks to mitigate the issue, or using a non-Samsung phone until you can download the patch.

- [__Results of my recent PostScript Charstring security research unveiled__][fonts] - __FIXED__ - Research recently released from Google into the Adobe Type Manager Font Driver, code that is widely used in Windows platforms for rendering fonts, has revealed multiple vulnerabilities ranging from denial of service attacks to remote code execution served through an HTML file. Patches for the numerous vulnerabilities are available from Microsoft ([[MS15-021][fonts2]], [[MS15-044][fonts3]) and Adobe ([[APSB15-10][fonts4]). Patching as soon as possible is advised.

### Reference / tutorials

- [__Crypto 101__][crypto101] - Crypto 101 is an in-depth tutorial into the basics of cryptography, which is made available for free. The PyCon 2013 presentation that started the Crypto 101 project is included below, and you can get a PDF of the book [here][crypto101book]. Check out [their Github repository][crypto101repo] for the book's source, learning exercises, and more. Also, I can't help but call out that this project is hosted for free by Rackspace! If you find this project helpful, consider donating to them (links on their home page, crypto101.io).

{% youtube 3rmCGsCYJF8 %}

### Random link of the week

- [__The Art of Command Line__][commandline] - This is a great collection of tips, tools, and examples for learning [bash][bash] and becoming a command line aficionado. It is intended to be useful for both beginners and experts, and provides both general (e.g. 'Know regular expressions well, and the various flags to grep/egrep. The -i, -o, -A, and -B options are worth knowing.') and specific ('For interactive selection of values from the output of another command, use [percol][percol].') tips.

[twitter]: https://twitter.com/ccneill

[lastpass]: https://blog.lastpass.com/2015/06/lastpass-security-notice.html/
[pbkdf2]: https://en.wikipedia.org/wiki/PBKDF2
[effreport]: https://www.eff.org/who-has-your-back-government-data-requests-2015
[effreport2]: https://www.eff.org/who-has-your-back-government-data-requests-2015#evaluation-criteria
[effreport3]: https://www.eff.org/who-has-your-back-government-data-requests-2015#results-summary

[radio]: http://www.tau.ac.il/~tromer/radioexp/
[radio2]: http://www.cs.tau.ac.il/~tromer/papers/radioexp.pdf
[emailhacking]: http://thehackernews.com/2015/06/how-to-hack-email-account.html

[samsung]: https://www.nowsecure.com/blog/2015/06/16/remote-code-execution-as-system-user-on-samsung-phones/
[samsung2]: http://global.samsungtomorrow.com/information-regarding-the-keyboard-security-issue-and-our-device-policy-update/
[fonts]: http://j00ru.vexillium.org/?p=2520
[fonts2]: https://technet.microsoft.com/library/security/MS15-021
[fonts3]: https://technet.microsoft.com/library/security/MS15-044
[fonts4]: https://helpx.adobe.com/security/products/acrobat/apsb15-10.html

[crypto101]: https://www.crypto101.io/
[crypto101book]: https://9d0df72831e4b345bb93-4b37fd03e6af34f2323bb971f72f0c0d.ssl.cf5.rackcdn.com/Crypto101.pdf
[crypto101repo]: https://github.com/crypto101

[commandline]: https://github.com/jlevy/the-art-of-command-line
[bash]: https://www.gnu.org/software/bash/
[percol]: https://github.com/mooz/percol
