---
layout: post
title: Displaying prepared code with syntax highlighting on Android
date: '2013-04-23 8:00'
comments: true
author: John Davidson
published: true
categories: []
---
{% img right 2013-04-23-displaying-prepared/android_logo.jpg 150 150 %}

I’m a fan of giving code snippets together with working demonstrations. I’m much more likely to trust code if I can see it and watch it work, as opposed to just reading it and hoping it still works. Has it been deprecated since it was written? Will it throw warnings? Did the author write this from memory, perhaps never even trying it? With a simple demonstration these questions disappear.

When I was asked to explain some Android features to my colleagues, I planned to compose demo apps with prepared, read-only code snippets. But as you can imagine, just dumping Java code into a TextView was a mess. The formatting was all wrong and (at least for me personally) reading code without syntax highlighting is a pain. Fortunately, there is a way to fix this.<!-- more -->
##Using Spanned formatting

This formatting solution still uses [TextView](https://developer.android.com/reference/android/widget/TextView.html), but rather than provide it with plain text content we pass my snippet as a [Spanned](https://developer.android.com/reference/android/text/Spanned.html) object. For small strings or dynamically-generated strings, we might programmatically compose our formatting from a [SpannableString](https://developer.android.com/reference/android/text/SpannableString.html), as in the following example:

<script src="https://gist.github.com/marcab/8fcd2df7f106b97c8071.js"></script>

Of course this is tedious at best, and for larger blocks this can be impractical. What we need is to generate formatted content from whole files. Luckily, Vim provides the highlighting we need as well as a way to export code in the format we are looking for.

```bash
vim src/com/example/myapp/MyFile.java
```

We’ll be using Vim’s `:TOhtml` command, but don’t execute it just yet. As the name suggests, this command exports your file to HTML with appropriate CSS styling to match what you see in your Vim window. Yes, this command is standard in Vim; no, it doesn’t require any plugins. Nice, eh?

Unfortunately for us, CSS styling is incompatible with Spanned styling. To get around this, we first tell Vim not to use CSS before exporting to HTML. Also, if the default color scheme isn’t acceptable, this is a good time to select another one.

To enter any of these commands in Vim, type a colon, the command text and then enter.

```
:colorscheme evening
:let html_use_css=0
:TOhtml
```

Now you should be looking at a split screen with your source and HTML files. Save your new file and exit. Just in case you’re not a Vim user, the command for that is:

```
:wq
:q
```

Now we have all the content we need, but we also have some we don’t. We want to keep the body content, but discard everything else. Using your preferred text editor, cut out the content of the body element and paste it into a txt file in /res/raw, creating this directory if necessary. Finally, you should have a file that looks something like this.

<script src="https://gist.github.com/marcab/145bad7283b82738e1ea.js" type="text/javascript"></script>

Then we can put this file into a Textview as follows in our Activity.

<script src="https://gist.github.com/marcab/4e729bd8e675e650d167.js" type="text/javascript"></script>

You’ll probably want to set the TextView’s `android:textColor` and `android:background` to make your content stand out. Here’s a screenshot of the final effect from my demo app.

{% img center 2013-04-23-displaying-prepared/android.png 450 550 %}

Not bad, eh?

Feel free to check out the [source code](https://github.com/marcab/list-accounts) for this demo.

_John Davidson is an Android developer at Rackspace's San Francisco office working on mobile products and services.  Of the mobile platforms he's tried, he prefers Android for the freedom it gives its users and developers, which is also why he's a fan of [CyanogenMod](https://www.cyanogenmod.org/) and other Android-based projects.  He speaks a little Mandarin (poorly) but is studying to improve.  You can follow John on Twitter at [@DavidsonJohnR](https://twitter.com/DavidsonJohnR)_
