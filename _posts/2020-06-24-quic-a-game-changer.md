---
layout: post
title: "QUIC: A Game Changer"
date: 2020-06-24 00:01
comments: true
author: Mustapha Benmbarek
published: true
authorIsRacker: true
bio: "Mustapha works with startups and companies of any size to support their
innovation. In his role as Solutions Architect at Rackspace, he leverages his
experience to help people bring their ideas to life, providing guidance and
technical assistance on cloud-based and AWS architectures."
categories:
    - Architecture
metaTitle: "QUIC is Google's answer to the latency challenge."
metaDescription: "QUIC is a new transport protocol designed from the ground up to improve performance for HTTPS traffic and to enable rapid deployment and continued evolution of transport mechanisms."
ogTitle: "QUIC is Google's answer to the latency challenge."
ogDescription: "QUIC is a new transport protocol designed from the ground up to improve performance for HTTPS traffic and to enable rapid deployment and continued evolution of transport mechanisms."
---

With the proliferation of mobile and web applications, latency has certainly
become a very huge deal on the Internet of today. The Internet is a very
competitive environment and users are becoming more and more content hungry
and certainly very impatient with latency.

<!-- more -->

Latency is a serious business concern for some big market players such as
Google, Amazon. Some previous studies have shown that users might visit a
website less often if it is slower just by a quarter of a second (250ms) and
another study has shown that Amazon can lose up to 1% in its sales just
because of a tenth of a second delay (100ms).

We know that bandwidth is cheap and will continue to grow but there is a
fundamental limitation in what we can do about latency and it has to do with
the fact that information cannot travel faster than the speed of light.
So unless we can figure out how to travel faster than the speed of light or
build tunnels in earth or maybe move to a smaller planet pretty much we are
faced with the following challenge which has to do with minimizing the number
of RTT's (round-trip times) required to establish a connection and hopefully
without sacrificing security.

And this is exactly where QUIC comes in.


### What is QUIC

QUIC, which stands for Quick UDP Internet Connection, was originally introduced
by Google in 2014 to provide a next generation multiplexed transport, and is
being standardized by the IETF
([Draft version 28 at the time of the writing](https://tools.ietf.org/html/draft-ietf-quic-transport-28)).

QUIC is a new transport protocol designed from the ground up to improve
performance for HTTPS traffic and to enable rapid deployment and continued
evolution of transport mechanisms. QUIC replaces most of the traditional
HTTPS stack: HTTP/2, TLS, and TCP, but implemented on top of UDP. Because
TCP is implemented in operating system kernels, and middlebox firmware, making
significant changes to TCP is next to impossible. However, since QUIC is built
on top of UDP and located in the user-space, it suffers from no such
limitations.

QUIC is basically Google's answer to the latency challenge. The protocol has
been globally deployed at Google on thousands of servers and is used to serve
traffic to a range of clients including a widely-used web browser (Chrome)
and a popular mobile video streaming app (YouTube). We estimate that around
5% of today’s Internet traffic is running on QUIC
(source: [w3techs](https://w3techs.com/technologies/details/ce-quic)).


### Where does QUIC fit?

Let’s understand now where the protocol fits in the OSI layer. QUIC is a
cross-layer protocol, rides on top of UDP and kind steals all the good things
from the TCP (e.g. congestion control, lost recovery), TLS
(e.g. cryptography, handshake) and all the control aspects of HTTP/2
(e.g. multi-streaming) to become its own protocol.

![QUIC protocol]({% asset_path 2020-06-24-quick-a-game-changer/quic-protocol.png %})

### Benefits

QUIC addresses some of challenges encountered by modern web applications on
desktop or mobile devices. Here are some of the key features of QUIC but you
can find more about it on the IETF working group website.

Speed : The core feature of QUIC is faster connection establishment. QUIC
reduces the number of round-trips (RTTs) to establish a connection between
a client and a server by combining the cryptographic and transport
handshakes. The initial connection takes one single round-trip while the
subsequent connection (or session resumption) to the same origin requires
no additional RTT.

Security : QUIC is an encrypted transport which means packets are always
authenticated and encrypted, preventing modification and limiting ossification
of the protocol by middleboxes. QUIC is very comparable to TLS and uses only
the (most secure) cipher suites that TLS 1.3 supports (i.e. complied with the
  perfect forward secrecy).

Optimization (Multiplexing) : Applications commonly multiplex units of data
within TCP’s single byte stream abstraction. To avoid head-of-line blocking
due to TCP’s sequential delivery, QUIC supports multiple streams within a
connection, ensuring that a lost UDP packet only impacts those streams whose
data was carried in that packet. Subsequent data received on other streams
can continue to be reassembled and delivered to the application.

Resiliency (Connection Migration) : QUIC connections are identified by a 64-bit
Connection Identifier. QUIC’s connection ID enables connections to survive
changes to the client’s IP address and port. Such changes can be caused by NAT
timeout and rebinding (which tend to be more aggressive for UDP than for TCP)
or by the client changing network connectivity to a new IP address
(for example, switching from Wi-Fi to cellular).

Reliability (Congestion control) : QUIC is reliable just like TCP and it
incorporates all the best practices and builds on years of learning with
TCP. Unlike TCP, the QUIC protocol does not rely on a specific congestion
control algorithm and its implementation has a pluggable interface to allow
experimentation and flexibility. Endpoints can unilaterally choose a different
algorithm to use, such as Cubic. It also improves loss recovery by using
unique packet numbers to avoid retransmission ambiguity and by using explicit
signaling in ACKs for accurate RTT measurements.

### Challenges

The main challenge encountered with QUIC is the middleboxes out there on the
internet which may hinder  perform the following restrictions: Middleboxes
have somehow become key check points in the Internet’s architecture: firewalls
tend to block anything unfamiliar for security reasons and Network Address
Translators (NATs) rewrite the transport header, making both incapable of
allowing traffic from new transports like QUIC without adding explicit
support for them. Any packet content not protected by end-to-end security, such
as the TCP packet that the organization implementing the protocol has no
ontrol over. This is one of the reason the QUIC protocol has been developed
on top of UDP because UDP and TCP are built into the kernel space, difficult
to change and very slow to update.

### Conclusion

One more time, Google has come up with a new initiative to make the web faster
and reliable. For several years, Google has been investing heavily on the web
space, by first deploying one of biggest CDN global cache network to get
closer to its users, and then by developing what will become the most widely
used browser, Google Chrome, to be even closer to the user; to finally
reshaping the transport protocol by opening QUIC to the open source community.

Even though the protocol is not yet standardized, we see a growing interest
by some big players like Cloudflare and Akamai that have already added
support for QUIC in their edge network

The QUIC protocol has made serious advancements in the last few years and has
inspired some new or still in draft technologies such as TLS 1.3, DoQ
(DNS over QUIC), SNI and HTTP/3 which is the upcoming version of HTTP
running over QUIC.

After going through the features and benefits of the protocol, it makes no
doubt that QUIC is a faster and more secure transport layer protocol that
is definitely designed for the needs of the modern Internet. Stay tuned for
the official announcement from the IETF.


Use the Feedback tab to make any comments or ask questions.
