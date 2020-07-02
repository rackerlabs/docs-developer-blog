---
layout: post
title: "QUIC: A game changer"
date: 2020-06-26 00:01
comments: true
author: Mustapha Benmbarek
published: true
authorIsRacker: true
authorAvatar: 'https://s.gravatar.com/avatar/0299204313e4fc8d8c722748fa21a6b2?s=80'
bio: "Mustapha works with startups and companies of any size to support their
innovation. In his role as Solutions Architect at Rackspace, he leverages his
experience to help people bring their ideas to life, providing guidance and
technical assistance on cloud-based and AWS architectures."
categories:
    - Architecture
    - Security
metaTitle: "QUIC: A game changer"
metaDescription: "QUIC is a new transport protocol designed from the ground up
to improve performance for HTTPS traffic and to enable rapid deployment and
continued evolution of transport mechanisms."
ogTitle: "QUIC: a game changer"
ogDescription: "QUIC is a new transport protocol designed from the ground up to
improve performance for HTTPS traffic and to enable rapid deployment and continued
evolution of transport mechanisms."
---

With the proliferation of mobile and web applications, latency has certainly
become a huge deal on the Internet of today. The Internet is a very
competitive environment, and users are becoming more and more content hungry
and certainly impatient with latency.

<!-- more -->

Latency is a serious business concern for some big market players such as
Google&reg; and Amazon&reg;. Some studies have shown that users might visit a
website less often if it is slower just by a quarter of a second (250 ms), and
another study has shown that Amazon could lose up to one percent of its sales
because of a tenth of a second delay (100 ms).

We know that bandwidth is cheap and will continue to grow, but there is a
fundamental limitation with what we can do about latency. Information cannot
travel faster than the speed of light. So, unless we can figure out how to
travel faster than the speed of light, build tunnels through the earth, or move
to a smaller planet, we are faced with the challenge of minimizing the number
of round-trip times (RTTs) required to establish a connection&mdash;hopefully
without sacrificing security.

And this is exactly where QUIC comes in.

### What is QUIC?

Google originally introduced the Quick UDP Internet Connection (QUIC) protocol
in 2014 to provide a next-generation multiplexed transport that conforms to the
Internet Engineering Task Force (IETF) standards:
([Draft version 28 at the time of the writing](https://tools.ietf.org/html/draft-ietf-quic-transport-28)).

QUIC is a new transport protocol designed from the ground up to improve
performance for HTTPS traffic and to enable rapid deployment and continued
evolution of transport mechanisms. QUIC, implemented on top of User Datagram Protocol (UDP),
replaces most of the traditional HTTPS stack:

- HTTP/2
- Transport Layer Security (TLS)
- Transmission Control Protocol (TCP)

TCP is usually implemented in operating system kernels and middlebox firmware, so making
significant changes to TCP is next to impossible. However, because QUIC is built
on top of UDP and located in the user-space, it suffers from no such
limitations.

QUIC is basically Google's answer to the latency challenge. Google has deployed the
protocol globally on thousands of servers. It serves
traffic to a range of clients, including a widely-used web browser (Chrome&trade;)
and a popular mobile video streaming app (YouTube&reg;). We estimate that around
five percent of today’s Internet traffic runs on QUIC
(source: [w3techs](https://w3techs.com/technologies/details/ce-quic)).

### Where does QUIC fit?

Let’s understand now where the QUIC protocol fits in the Open Systems Interconnection (OSI) layer.
QUIC is a cross-layer protocol that rides on top of UDP. It becomes its own protocol by stealing of
all the good things from TCP (congestion control and loss recovery), TLS (cryptography and handshake),
and all of the control aspects of HTTP/2 (multi-streaming).

![QUIC protocol]({% asset_path 2020-06-24-quick-a-game-changer/quic-protocol.png %})

### What are the benefits of QUIC?

QUIC addresses some of the challenges encountered by modern web applications on
desktop or mobile devices. You can learn more about QUIC on the
[IETF working group website](https://tools.ietf.org/html/draft-ietf-quic-transport-28),
but the following list has some of the key features of QUIC:

- **Speed**: The core feature of QUIC is faster connection establishment. QUIC
reduces the number of RTTs that you need to establish a connection between
a client and a server by combining the cryptographic and transport
handshakes. The initial connection takes a single round-trip, and the
subsequent connection (or session resumption) to the same origin requires
no additional RTT.

- **Security**: QUIC is an encrypted transport, which means packets are always
authenticated and encrypted. This encryption prevents modification and limits
protocol ossification by middleboxes. Comparable to TLS, QUIC uses only
the most secure cipher suites that TLS 1.3 supports (complying with
perfect forward secrecy).

- **Optimization (Multiplexing)**: Applications commonly multiplex units of data
within TCP’s single byte-stream abstraction. To avoid head-of-line blocking
because of TCP’s sequential delivery, QUIC supports multiple streams within a
connection. This support ensures that a lost UDP packet only impacts those streams with
data carried in that packet. Subsequent data received on other streams
can continue to be reassembled and delivered to the application.

- **Resiliency (Connection migration)**: You can identify QUIC connections by a 64-bit
Connection Identifier. QUIC’s connection ID enables connections to survive
changes to the client’s IP address and port. Such changes can be caused by Network address
translation (NAT) timeout and rebinding (which tends to be more aggressive for UDP than for TCP)
or by the client changing network connectivity to a new IP address
(for example, switching from Wi-Fi to cellular).

- **Reliability (Congestion control)**: QUIC is reliable just like TCP, and it
incorporates all the best practices, building on years of learning with
TCP. Unlike TCP, the QUIC protocol does not rely on a specific congestion
control algorithm, and its implementation has a pluggable interface to allow
experimentation and flexibility. Endpoints can unilaterally choose a different
algorithm to use, such as CUBIC. It also improves loss recovery by using
unique packet numbers to avoid retransmission ambiguity and by using explicit
signaling in acknowledgements (ACKs) for accurate RTT measurements.

### What are the challenges with QUIC?

The main challenge encountered with QUIC is the middleboxes out there on the
Internet. Middleboxes have somehow become key checkpoints in the
Internet architecture. Firewalls tend to block anything unfamiliar for
security reasons, and NATs rewrite the transport header, making both incapable of
allowing traffic from new transports, such as QUIC, without explicit support. The
firewall blocks any packet content not protected by end-to-end security, such as
the TCP packet over which the organization implementing the protocol has no control.
This is one of the reasons Google developed the QUIC protocol on top of UDP. UDP and
TCP are built into the kernel space, which is difficult to change and very slow to update.

### Conclusion

Google has come up with a new initiative to make the web faster and more reliable. For
several years, Google has been investing heavily in the webspace. First, it deployed one
of the biggest content delivery network (CDN) global cache networks to get
closer to its users. Then, it developed one of the most widely
used browsers, Google Chrome, to be even closer to the user. Finally, it
reshaped the transport protocol by opening QUIC to the open-source community.

Even though the protocol is not yet standardized, we see a growing interest
by some big players like Cloudflare&reg; and Akamai&reg;, which have already added
support for QUIC in their edge network.

The QUIC protocol has made serious advances in the last few years and has
inspired some new or still-in-draft technologies such as the following ones:

- TLS 1.3
- DoQ (DNS over QUIC)
- SNI
- HTTP/3 (the upcoming version of HTTP that runs over QUIC)

After going through the features and benefits of the protocol, you hopefully agree
that QUIC is a faster and more secure transport layer protocol, which
is definitely designed for the needs of the modern Internet. Stay tuned for
the official announcement from the IETF.

Use the Feedback tab to make any comments or ask questions.
