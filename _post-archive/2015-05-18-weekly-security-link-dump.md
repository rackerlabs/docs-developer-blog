---
layout: post
title: Weekly Security Link Dump (Week of May 18th)
date: '2015-05-19 23:59'
comments: true
author: Charles Neill
published: true
categories:
  - Security
---

Welcome to the Weekly Security Link Dump for the week of May 18th! This week, we'll take a look at some new tech, some broken crypto, and a few guides to help you improve the security of your workstation and your product.

After several [high-profile][deprecation] [articles][deprecation2] [calling][deprecation3] for the deprecation of plaintext HTTP recently, the new HTTP/2 RFC has arrived! While it doesn't explicitly mandate SSL/TLS, HTTP/2 definitely has some improvements from a security perspective. Unfortunately, the Open Smart Grid Protocol has not had such good news this week, as researchers uncovered serious issues with some of their non-standard cryptographic algorithms. You can find out more about these and other topics below the fold.

If you have any feedback about this week's links, the format of these posts, or anything else, please [let me know][twitter]!

<!-- more -->

# News / Opinions

- [__HTTP/2 RFC released__][http2] - The RFC for HTTP/2 was released recently, and it looks to be quite a major shift from HTTP/1.1 in a lot of ways, including compressed headers, server push, and more. Changes that impact security include mandating TLS >=1.2 and deprecating a large number of cipher suites, among other things. [Section 10][http2_sec] is all about the security considerations to keep in mind with HTTP/2, if you're interested in learning more.

# Security Research

- [__Weak homegrown crypto dooms open smart grid protocol__][smart_grid] - Security researchers have discovered serious issues in the cryptography of the Open Smart Grid Protocol, releasing a new paper called [Dumb Crypto in Smart Grids][smart_grid2] to report their findings. In the words of these researchers, some of the crypto "has been found to be extremely weak, and cannot be assumed to provide any authenticity guarantee whatsoever." Thankfully, the OSGP Alliance has stated that [they intend to update this crypto][smart_grid3], but they will still be using their own algorithms instead of using common standards, which is heavily frowned upon by most cryptography experts.

- [__How to make two binaries with the same MD5 hash__][md5] - In case you needed any more proof that you shouldn't be using MD5 anymore, especially for verifying hashes of arbitrary binary files, someone has developed [a simple PHP tool][md5_2] to generate hash collisions, allowing virtually anyone to easily spoof MD5 hashes.

- [__What one may find in robots.txt__][robots] - Security researchers will often use a tool like DirBuster or wfuzz to discover directories or files that might not be linked to in public places during an engagement, but this test is only as good as your wordlist. To create a new wordlist, a French security researcher has harvested thousands of robots.txt files that often explicitly list files that website owners don't want search engine crawlers (or bad guys) to know about, and sorted it by frequency of occurrences. Great way to keep an updated list if you ask me.

# Reference / Tutorials

- [__A week with a Rails security strategy__][rails] - This article presents a nice framework for taking care of the security of your products on a weekly basis. It is geared towards Rails, but you can replace a lot of the Rails-specific pieces with the applicable tools for the language you're using. It includes simple processes like checking for outdated packages that might have security issues and checking out and updating TLS/SSL configurations, but it also contains more holistic processes like thinking about the guts of your application's login system, for example.

- [__Secure yourself, part 1: air-gapped computer, GPG and smartcards__][secure_yourself] - Feeling particularly paranoid today? This guide will tell you how to set up an [air-gapped computer][air_gap], configure a [Yubikey][yubikey], and much more.

# Random Link of the Week

- [__Lily__][lily] - Ever wanted a drone to capture all your motions on HD video? Just throw this thing in the air, and it will fly around tracking you and shooting video automatically. Personally, I'm not looking forward to the day we have thousands of these things flying around everywhere capturing everything we do, but at least they'll look cool.

[deprecation]: https://https.cio.gov/
[deprecation2]: https://blog.mozilla.org/security/2015/04/30/deprecating-non-secure-http/
[deprecation3]: https://www.chromium.org/Home/chromium-security/marking-http-as-non-secure
[twitter]: https://twitter.com/ccneill

[http2]: https://httpwg.github.io/specs/rfc7540.html
[http2_sec]: https://httpwg.github.io/specs/rfc7540.html#security

[smart_grid]: https://threatpost.com/weak-homegrown-crypto-dooms-open-smart-grid-protocol/112680
[smart_grid2]: https://eprint.iacr.org/2015/428
[smart_grid3]: https://threatpost.com/open-smart-grid-protocol-alliance-plans-to-fix-its-weak-crypto/112794
[md5]: https://natmchugh.blogspot.com/2015/05/how-to-make-two-binaries-with-same-md5.html
[md5_2]: https://github.com/natmchugh/longEgg
[robots]: https://thiébaud.fr/robots.txt.html

[rails]: https://bauland42.com/articles/a-week-with-a-rails-security-strategy/
[secure_yourself]: https://viccuad.me/blog/secure-yourself-part-1-airgapped-computer-and-GPG-smartcards/
[air_gap]: https://en.wikipedia.org/wiki/Air_gap_%28networking%29
[yubikey]: https://www.yubico.com/products/yubikey-hardware/

[lily]: https://www.lily.camera/
