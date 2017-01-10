---
layout: post
title: Styling Gertty for Fun and Profit
date: 2017-01-11 10:00
comments: false
author: Ian Cordasco
published: true
authorIsRacker: true
categories:
    - OpenStack
---

In my position in Private Cloud, I tend to spend a lot of time using
OpenStack's instance of [Gerrit][] to review proposed changes. When reviewing
OpenStack changes, I prefer keyboard shortcuts and terminal interfaces so I
can explore the affect of a change via my preferred text editor.
To accommodate this workflow I use [Gertty][]. I run it inside [tmux][] so
that I can switch to another window and look at the code using [vim][] and
tinker with the tests.

<!-- more -->

And as far as preferences go, I use the [Solarized][] theme created a few
years ago by Ethan Schoonover for pretty much everything.  Naturally, I use
Solarized in my terminal emulator of choice on whatever operating system I
happen to be using.

If you're familiar with terminal-based applications, you know they can change
the color of pieces of text and indeed Gertty takes advantage of this. I've
encountered a problem with Gertty's default colour palette: it is not readable
with Solarized.  For example, if you try to list all of the projects in
OpenStack (including the ones you are subscribed to) it looks like this:

![Gertty listing all projects where only the subscribed are
visible](http://i.imgur.com/lTzrq7n.png)

Further, some of the content in reviews is not ideal for use with the
Solarized theme (line numbers, for example, are not legible). So, I spent a
little bit hacking, and was able to come up with a usable (but not great)
palette for you to include in your Gertty configuration.

```yaml
---
# .gertty.yaml
palettes:
  - name: solarized
    comment: ['dark blue', '']
    comment-name: ['white,bold', '']
    context-button: ['white,bold', '']
    filename: ['light gray', '']
    focused-filename: ['light magenta', '']
    focused: ['black', 'light gray']
    focused-added-line: ['light gray', 'dark green']
    focused-added-word: ['white', 'dark gray']
    focused-context-button: ['dark magenta,bold', '']
    focused-removed-line: ['light gray', 'dark red']
    focused-line-number: ['dark gray', 'light gray']
    focused-link: ['light gray', 'dark blue']
    focused-unsubscribed-project: ['light magenta,bold', 'white']
    focused-reviewed-change: ['white,bold', 'dark magenta']
    focused-starred-change: ['white,bold', 'dark blue']
    footer: ['brown', '']
    line-number: ['light gray', '']
    reviewed-change: ['dark magenta', '']
    starred-change: ['dark green', '']
    test-SUCCESS: ['dark green', '']
    test-FAILURE: ['light red', '']
    unsubscribed-project: ['light magenta', '']

palette: solarized
```

With this palette I can now see projects there were previously hidden:

![Gertty listing all projects where all are truly
visible](http://i.imgur.com/LcSoRrw.png)

If all you came here for was a working snippet for the Solarized color them, I
suggest you stop here. If you're interested in how the above works, read on!

# Defining Palettes

In case you're not familiar with YAML, the above snippet defines `palettes` as
a list with a single object (dictionary, hash, or whatever you want to refer
to that as). We could absolutely define more than one palette in this list. We
would just have another list item (denoted by a `-`) after the end of the
first palette and we would begin again in a similar vein. That would look
like:

```yaml
palettes:
  - name: foo
    # interface styles
  - name: bar
    # interface styles
```

Each palette for Gertty requires a name; in our case we use "solarized".
Everything else in our object now refers to the styling of some piece of the
interface. The interface name is on the left (e.g., `comment`, `comment-name`,
`focused-filename`, etc.) and the styling for that element is on the right
(e.g., `['dark blue', '']`, `['white,bold', '']`, `['light magenta,bold',
'white']`). We can get a comprehensive list of interface names by running:

```
$ gertty --print-palette
```

Figuring out which colors is not as simple, but luckily not difficult. First,
we need to realize that Gertty relies on [Urwid][] to handle drawing it's
interface in a terminal. If we know how Urwid deals with colors, we can then
start tinkering with our palette. Fortunately, [Urwid's documentation][] is
pretty good in this respect. So the last bit of information to understand is
the fact that each interface takes a list of foreground and background colors
to apply to it's element. Let's look at examples.

Above, we have an example that looks like:

```yaml
['dark blue', '']
```

The `[` and `]` denote a list (or array) here. Inside we have two strings:

- `'dark blue'`
- `''`

The first string in every list will be the **foreground** color. In other
words, this is the color of the text that's rendered. The second string will
be the background color. If an empty string is specified for either, it is the
"default" color. So in this particular example, the text that's rendered will
be dark blue and the background will be the default. Another example is:

```yaml
['white,bold', '']
```

In this case, the foreground color will be white and it will be made to look
bold. Finally, we have:

```yaml
['light magenta,bold', 'white']
```

In this case, our background color will be white and our foreground color will
be light magenta and it will also be made to look bold.

With the above understand and Urwid's color documentation, you should now be
able to write your own palette for your favorite colorscheme.

# Extra Screen Captures

![Capture of a code review for
openstack-dev/hacking](http://i.imgur.com/PkME2AD.png)

*This blog post originally appeared on [Ian's blog][].*

[Gerrit]:                https://www.gerritcodereview.com/
[Gertty]:                https://pypi.python.org/pypi/gertty
[tmux]:                  https://tmux.github.io/
[vim]:                   http://www.vim.org/
[Solarized]:             http://ethanschoonover.com/solarized
[Urwid]:                 http://urwid.org/
[Urwid's documentation]: http://urwid.org/manual/displayattributes.html#foreground-and-background-settings
[Ian's blog]:            http://coglib.com/~icordasc/blog
