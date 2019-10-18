---
layout: post
title: A Look Back at PyCon Australia 2013
date: '2013-07-22 17:00'
comments: true
author: Ed Leafe
published: true
categories:
  - Python
---
In an earlier [post][1] I reviewed the OpenStack miniconf that preceded the main PyCon, which was held in Hobart, Tasmania on July 6–7. I had meant to write this shortly after PyCon ended, but the whirlwind of travel back to the US and getting back into the daily grind pushed it off my plate.

The conference was recorded, and all the videos are available on the [pyvideo.org][2] website. I encourage you to watch as many of the sessions that interest you as you can – lots of good stuff in them!

The conference actually started for me earlier – the organizer, [Chris Neugebauer][3], had asked for volunteers to help with the conference prep work: badges, swag, all that stuff. This was on the Wednesday before the conference, which happened to be the day I arrived, so it was as good an excuse as any to get out of my hotel and into Hobart. For those of you who have never gone to a PyCon, it is completely run by volunteers. No one gets paid; no one gets free admission; no one gets special perks. This was shocking to me when I moved from the Microsoft conference world a decade ago, where conferences were run as profit centers, and attendees paid for tickets that cost well over $1,000, but who could then relax and treat their time there as a vacation (which many did, at their employers’ expense). But PyCons are the exact opposite, and as a result everyone has a stake in the conference experience. I’ve found that volunteering not only makes you feel like you’re contributing, but it also means that you meet a lot of interesting people who might otherwise remain anonymous faces in the crowd.<!-- more -->

{% img center 2013-07-22-a-look-back/1.jpg %}

The picture above is a quick snapshot I took as we carried out the task of wrapping a thousand coffee cups (yes, that’s correct: 1000) with vinyl cutouts of the coffee sponsor’s logo. Why did we do this? Because a run of pre-printed cups had a minimum of 50,000, and, well, PyCon just ain’t that big! And to make things even more fun, the logos were slightly bigger than the cup, which made it difficult to wrap cleanly. Tedious, huh? But rather than being a drag, it was a great time as the dozen or so people there had great conversations as we wrapped the cups one by one. As the only American there, and this being my first time in Australia, observations on cultural differences was a big topic, and I certainly learned a lot. We were all shocked when we were done to learn that we had spent 4 hours working on this stuff; it certainly went by much faster than that.

After the work was done, we went out to eat, where (among other things) I learned that Tasmania has a high-end distillery business that is producing spirits that rival other parts of the world, especially in the high-end whiskey area. Two of the best are the [Nant][4] and [Lark][5] distilleries. I’m not a big Scotch drinker, but I appreciated the quality that these two distilleries are producing. Unfortunately, they are relatively small, and their products are nearly impossible to find in the US.

The conference proper started off Saturday morning, with [Alex Gaynor][6] giving the [keynote][7]. It set the tone for the conference, and we spent much of the next two days exploring what it meant to be both a software developer in general, and a Pythonista in particular. I then went to Nick Coghlan’s talk about [the state of Python packaging][8]; it’s no secret that packaging has always been a pain point for Python, but it is great to see that the different efforts are now unified under Nick’s leadership.

Next up was Jacob Kaplan-Moss’s talk on [security in web apps][9] in the Python world. I was aware of most of the attack vectors thanks to my security training at Rackspace, but it was somewhat shocking to see how easy it is to expose a vulnerability if you don’t know it’s there. If you write web apps that are exposed to the public, make sure you watch the video of his talk. Now.

In the afternoon I drifted between various talks which, to be frank, varied in their appeal. That’s not to say that the content wasn’t valuable; it just wasn’t of particular interest to my work. I did end up skipping a few talks to work on my slides for my session; I don’t think I’ve ever given a talk without editing it right up to the last minute, and this was no different.

The day ended with a full hour of Lightning Talks, which are always one of my favorite parts of PyCon, and the lightning talks at PyCon AU did not disappoint. If you aren’t familiar with the concept, they are a series of short (5 minutes – enforced!) talks on whatever the speaker wants to talk about. There was a good mix of dense information, rants, product description and general wackiness. If you’ve never been to a PyCon, don’t miss the lightning talks! I didn’t take notes, but fortunately [Thomas Sutton did][10].

One thing that was different at this PyCon was the Conference Dinner after the sessions on Saturday. All the attendees were gathered into a room with many large round tables that sat about 10 people each. There was wine and beer served, along with iced tea and soda. The food was served buffet-style, but this was no ordinary conference fare. Fresh oysters! Smoked salmon! Freshly-carved roasts! All this with an assortment of salads, vegetables, breads, and deserts. I followed my usual practice and sat at a table where I knew no one, in order to make new friends and learn about what they are doing with Python, but we ended up having much less technical discussion for some reason (big surprise!).

The evening wasn’t all food and drink, though. There was an [evening keynote][11] by Mark Pesce of MooresCloud that talked about their work integrating Raspberry Pi units to control [LED displays][12]. An example of this was used in the lightning talks to provide a visual indication of the time remaining for each speaker; as time wound down, the LEDs changed from green to yellow to red to flashing red to off. During the keynote, though, he demonstrated how the Pis could change the light display in response to a stream of Twitter hashtags, creating a virtual tug-of-war. He had half the room send tweets with one hashtag, while the other half tweeted a different hashtag, and the color distribution of the display changed in response. Apologies to anyone who follows me on Twitter for the hashtag spam that night! So while this was a somewhat silly example of what it could do, it certainly demonstrated that you could program the device to respond to any sort of dynamic data.

Sunday morning’s sessions were… ok, you got me. I skipped the sessions at the prompting of Alan Perkins, the director of our Sydney office, who grew up in Hobart and knows the area well. He wanted to take me along with a couple of other Rackers up to the peak of [Mount Wellington][13], which is probably the most ubiquitous visual in the Hobart area. Unfortunately, being the middle of winter there, the roads were closed due to iciness. So instead Alan took us on a tour along the [coastline of the Derwent estuary][14] through some of the smaller towns and some truly gorgeous scenery.

We made it back in time for the last morning session, but I needed to prepare for my talk in the afternoon. After lunch Richard Jones gave an [excellent talk][15] entitled "Don’t Do This", which was an exploration of some of the oddities that were possible in the Python language. Fortunately I can say that none of them could be found in my code! Next up was Dylan Lacey from Sauce Labs, with a talk on using [Splinter][16] to streamline your testing by providing an API that allows you to automate browser actions. Splinter looks pretty interesting, and if I were doing web acceptance testing, I would definitely check it out.

Next up was my session on [using Python to build your application infrastructure][17]. I won’t self-review, but I do want to thank the people who attended the talk for being understanding when the shaky hotel network caused my live demo to die halfway through. I did get a few [good reviews][18] from those who attended the talk.

After the afternoon tea break, I saw Luke Miller’s [talk on developing an indie game][19] with Python that featured a gay theme. I had never really thought about it before, but there weren’t any games that featured leading characters who were gay, and which might appeal to gay audiences more than the current selection available. The talk wasn’t just about the game’s theme; it was a very in-depth look into what it takes to develop a game and make it interesting. I must say that I learned more in that talk than in any other I attended, as the material was totally new to me, and it was presented very clearly.

The final session was by Adam Forsyth on [Getting the Most Out of StackOverflow][20]. Adam is seriously active on that site, and knows quite a bit about how things work, and how it can be overwhelming at times to a newcomer. He had many tips for those who wanted to both ask better questions that would have a good chance of receiving a great answer, as well as for those who wanted to be able to find questions to answer before others did.

Last but not least were the second day of lightning talks. Once again they were excellent, and again, Thomas Sutton took [much better notes][21] than I did.

That was the end of the conference, and Chris Neugebauer, as the conference chair, gave his closing remarks, thanking everyone from the sponsors to the attendees for making PyCon AU 2013 a truly remarkable conference. He received a standing ovation of thanks from the audience for all his hard work, and he deserved every clap.

Many people left after that, but for those of us who remained, things were not over. We had the upper level of [Jack Greene’s][22] reserved, and it was packed with Pythonistas enjoying some final food, drink, and conversation.

I’ve been to 10 PyCon US conferences, and while PyCon AU 2013 was much smaller in overall size, it matched its US counterpart in terms of spirit, content, and sense of community. Next year it moves to Brisbane, and I would certainly love to be able to return.

[1]: https://developer.rackspace.com/blog/openstack-miniconf-at-pycon-au-2013.html
[2]: http://pyvideo.org/category/38/pycon-au-2013
[3]: http://www.flickr.com/photos/parisba/9213433853/in/set-72157634490541945
[4]: http://nant.com.au/
[5]: http://www.larkdistillery.com.au/
[6]: http://www.flickr.com/photos/parisba/9220259889/
[7]: http://blog.leafe.com/a-look-back-at-pycon-australia-2013/Computer%20Science,%20Software%20Engineering,%20and%20the%20Scientific%20Method
[8]: http://2013.pycon-au.org/schedule/30030/view_talk?day=saturday
[9]: http://2013.pycon-au.org/schedule/30081/view_talk?day=saturday
[10]: http://passingcuriosity.com/2013/pycon-australia-day-one/
[11]: http://2013.pycon-au.org/media/news/36
[12]: http://www.flickr.com/photos/parisba/9228028476/in/set-72157634490541945
[13]: http://en.wikipedia.org/wiki/Mount_Wellington_(Tasmania)
[14]: http://en.wikipedia.org/wiki/Derwent_River_(Tasmania)
[15]: http://2013.pycon-au.org/schedule/30047/view_talk?day=sunday
[16]: http://splinter.cobrateam.info/
[17]: http://2013.pycon-au.org/schedule/30028/view_talk?day=sunday
[18]: http://jackscott.id.au/2013/07/reflections-on-pyconau-2013/
[19]: http://2013.pycon-au.org/schedule/30050/view_talk?day=sunday
[20]: http://2013.pycon-au.org/schedule/30083/view_talk?day=sunday
[21]: http://passingcuriosity.com/2013/pycon-australia-day-two/
[22]: http://www.urbanspoon.com/r/345/1706785/restaurant/Tasmania/Jack-Greene-Bar-Hobart
