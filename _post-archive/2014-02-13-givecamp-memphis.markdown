---
layout: post
title: GiveCamp Memphis 2014
date: '2014-02-18 13:40'
comments: true
author: Ed Leafe
published: true
categories:
  - Developers
  - Events
---


GiveCamp is a weekend-long event where technology professionals from designers, developers and database administrators to marketers and web strategists donate their time to provide solutions for non-profit organizations. This was the third year, and it was held at [Cowork Memphis](https://coworkmemphis.com/). **Rackspace** was a major sponsor of the event: we provided some funding, as well as donating free hosting for any of the charities that participated. They were also nice enough to send me to Memphis for the weekend in order to help out any way I could.

<!-- more -->

The event began Friday evening at 6pm. Representatives from the various charities kicked off the evening by giving a brief introduction to the charitable work that they do, and the technical assistance they need. There were a wide range of organizations:

   * [**Mid-South Spay & Neuter Services**](https://www.spaymemphis.org): A veterinary clinic offering free/low-cost spay/neutering services to help reduce the stray population
   * [**Memphis Area Coalition on Hunger**](https://memphishunger.org/): A coalition linking the various services for feeding the hungry
   * [**Memphis Immigration Advocates**](https://memphisimmigrationadvocates.org/): Immigration and refugee protection legal services
   * [**Outreach Housing & Community, Inc.**](https://ohcinc.org/): Helping the homeless find housing and keep it.
   * [**Habitat for Hope**](https://www.habitatforhope.org/): Serving chronic/terminally ill children, and providing bereavement counseling for the families.
   * [**Porter-Leath**](https://www.porterleath.org/): Providing early education to children in the poorest areas, and support for teen runaways.
   * **The Standard Youth Ministry** (no website yet!): Youth outreach aiming to teach kids to code, and provide them with the tools to learn programming
   * [**TN Parks and Greenways Foundation: Mid South Greenways**](https://www.midsouthgreenways.org/): Greenway improvement and management
   * [**Junior League of Memphis**](https://www.jlmemphis.org/Home): training young women to be tomorrow’s leaders, and giving back to the community.


After the introductions, there was some general mingling as the developers met with the representatives of the charity to learn more about what was needed by each.They then selected the charity they wanted to work with, based mostly on the match of their skills to the needs of the charity, but also somewhat on the focus of the charity itself. We all then settled into groups to discuss the needs of the charity in more detail, and to figure out the approach we would be taking.

I chose to work with the Memphis Area Coalition on Hunger along with several other developers, as well as a design professional. We decided on a WordPress site, which would be customized with a PHP-based backend. Being a Python guy, my ability to contribute code was limited, because while I know some PHP, I was unfamiliar with the various frameworks being used, such as Laravel, Eloquent, Twig, and Blade. So instead I concentrated on two aspects: working with the designer on translating the charity’s requests into a functional design, and designing the database to not only support the immediate goals for the weekend, but also some of the stretch goals they will need down the road.

Every 4-6 hours we would have a standup to discuss where each group was, what was blocking their progress, and where we expected to be by the next standup. If a group had an issue that was blocking them, I would float over to their team for a bit to help them out. As a result I got to meet a lot more of the developers, and learn about such fun things like Google OAuth2 integration.

The space at Cowork Memphis was available around the clock, and many developers chose to work through the night. That’s a younger man’s game, however, so I headed back to the hotel for some sleep around midnight.

Saturday was pretty much non-stop development, as we worked to get something working by the end of GiveCamp. Again, I contributed little coding, but instead led many of the design discussions, and helped to keep the project moving. The design was settled, and since I'm not that great at tweaking web front ends, I worked on defining the data backend. The challenge that we had was to enter information about all of the various locations that provided food for the hungry, such as location, days/hours of operation, and whether they were child-friendly. That last data item was one of the things I learned from the organizers of the charity: since most of the hungry are poor families with small children, many services are geared toward making their service safe for small children. Many others took in anyone off the street, including people with severe mental illnesses, and you wouldn't want to send a family with small children there. Once the data was entered, people could go to the web, enter their location, and find all the services that were nearby.

We set it up so that when the address of any service was entered, a call would be made to the Google Maps API to get the latitude and longitude information for the address so that it could be used in distance calculations later. Then later, when someone entered their location, the Maps API would be used to generate a map centered on their location, with markers for each of the nearby services. Clicking on the marker would give some basic info about the service, along with a link for more information. [Try it out!](https://memphishunger.org/find-events-near-you/).

Unfortunately, due to scheduling I was not able to stay until the end of the event, but I've gone back to the various websites, and the results are very impressive! I have to give a lot of credit to Brian Swanson, who organized GiveCamp, and who kept things running smoothly throughout the weekend. There were many others who also donated a lot of their time and energy, and it was truly inspirational to see all these people coming together to help make their part of the world a little bit better place.
