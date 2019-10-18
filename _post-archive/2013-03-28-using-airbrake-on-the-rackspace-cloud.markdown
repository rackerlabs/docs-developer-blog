---
layout: post
title: Using Airbrake on the Rackspace Cloud
date: '2013-03-28 08:15'
comments: true
author: Ben Arent
categories: []
---
For a developer, the DevOps journey can be full of surprises. For example, server automation for setup lets developers have full control to fine tune and tweak applications for maximum performance; but once the server and app are up, the quest for a high quality application continues. 

Comprehensive manual testing has given way to automated testing, and practices such as test-driven design have enabled developers to push code without worrying about breaking the build. Even companies with complete test coverage push fixes daily. Bugs can be reported by customers or those reports can be automated using an error tracking tool such as Airbrake. 

Airbrake is an application that collects, de-dupes and notifies developers of errors in an application. The Airbrake system captures every unique error and all of its occurrences based on detailed parameters, backtrace and environment.<!-- more -->  

{% img center 2013-03-28-using-airbrake/airbrake1.png %}

One of the best things about Airbrake is its ecosystem of “reporters” -  a range of open source notifiers that receive comprehensive crash reports on an application. There are notifier solutions for mainstream languages like [Ruby](https://github.com/airbrake/airbrake), [Java](https://github.com/airbrake/airbrake-java), [Php](https://github.com/airbrake/airbrake-php),[Node](https://github.com/felixge/node-airbrake) and [Javascript](https://github.com/airbrake/airbrake-js), and Airbrake is increasingly useful when trying to debug less common languages like [Erlang](https://github.com/kenpratt/erlbrake), [Scala](https://github.com/stackmob/stackmob-airbrake) or even [iOS](https://github.
com/airbrake/airbrake-ios) and [Android](https://github.com/airbrake/airbrake-android) mobile apps.

Having all errors consolidated in one place provides developers a comprehensive overview of complete application health. But it doesn't stop there. Airbrake’s API is flexible to use on backend services such as [resque](https://blog.airbrake.io/how-to/catching-resque-errors-with-airbrake/) and [sidekiq](https://github.com/mperham/sidekiq/wiki/Middleware#default-middleware), or other DevOps tools like [Chef](https://github.com/morgoth/airbrake_handler).

Airbrake setup depends on the language. Once a Gem, Package, Jar or Code is installed, an API key from [Airbrake](https://airbrake.io) is required. Most reporters have comprehensive tools for testing and setup.

##Fine tuning Airbrake for the Rackspace Open Cloud. 

There are a few ways that you can fine tune airbrake depending on your application. Here are a few tips:

1. Send 'current_user' with an error. Associating an error with an individual customer makes debugging easier and gives you power to proactively support customers.  
2. Watching your database. Airbrake reporters will catch all errors in an application, including critical errors like database locks and SQL queries in scaling applications.
3. Setup environments. Airbrake lets you divide your application into testing, staging and production environments. 
4. Integration. Airbrake lets you receive notifications in many ways; from chat services like HipChat and Campfire to ticketing tools such as JIRA and PivotalTracker.

##Using Airbrake in a Rails Application

###Rails 3.x

Add the airbrake gem to your Gemfile. In Gemfile:

```
gem 'airbrake'
```

Then from your project's RAILS_ROOT, and in your development environment, run:

```
bundle install
rails generate airbrake --api-key your_key_here
```

**That's it!**

The generator creates a file under `config/initializers/airbrake.rb` configuring Airbrake with your API key. This file should be checked into your version control system so that it is deployed to your staging and production environments.

The default behaviour of the gem is to only operate in Rails environments that are NOT development, test & cucumber.

You can change this by altering this array:

```ruby
config.development_environments = ["development", "test", "cucumber", "custom"]
```

###Rails 2.x

Add the airbrake gem to your app. In config/environment.rb:

```ruby
config.gem 'airbrake'
```

or if you are using bundler:

```
gem 'airbrake', :require => 'airbrake/rails'
```

Then from your project's RAILS_ROOT, and in your development environment, run:

```
rake gems:install
rake gems:unpack GEM=airbrake
script/generate airbrake --api-key your_key_here
```

Of course, credentials and other sensitive configuration values should not be committed to source-control. In Git exclude the .env file with:

```
echo .env >> .gitignore
```

As always, if you choose not to vendor the airbrake gem, make sure every server you deploy to has the gem installed or your application won't start.

The generator creates a file under config/initializers/airbrake.rb configuring Airbrake with your API key. This file should be checked into your version control system so that it is deployed to your staging and production environments. When developing locally it is best to turn off the integration with Airbrake to minimize dependencies on remote services.

##Airbrake Zero is a journey, not a destination. 
Like an inbox is a constant reminder of pending messages and tasks, Airbrake can be a constant reminder of errors and issues in an application - some created by customers, some from third party services throwing unpredictable errors and some from internal database issues. But don’t get overwhelmed, the first step is to identify these issues; the next is to take action. 

Getting to Airbrake Zero (or having all errors cleared) may be impossible for a large application, but now you'll have the insight to make DevOps even faster. So, go forth, “move fast and fix things.”

Sign up for Airbrake at [https://airbrake.io](https://airbrake.io)!

{% img center 2013-03-28-using-airbrake/airbrake2.png %}

