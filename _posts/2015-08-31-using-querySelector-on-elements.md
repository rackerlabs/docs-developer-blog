---
layout: post
title: Using querySelector and querySelectorAll on elements
date: '2015-08-31 23:59'
comments: true
author: lvh
authorIsRacker: true
authorAvatar: "https://s.gravatar.com/avatar/1846c8040fcf70e9b55bb7bfcdb78bc4"
published: true
categories:
  - General
---

Modern browsers have APIs called `querySelector` and `querySelectorAll`. They
find one or more elements matching a CSS selector. I'm assuming basic
familiarity with CSS selectors: how you select elements, classes and ids. If
you haven't used them, the Mozilla Developer Network has an excellent
[introduction][csssel].

<!-- more -->

Imagine the following HTML page:

```html
<!DOCTYPE html>
<html>
<body>
    <img id="outside">
    <div id="my-id">
        <img id="inside">
        <div class="lonely"></div>
        <div class="outer">
            <div class="inner"></div>
        </div>
    </div>
</body>
</html>
```

`document.querySelectorAll("div")` returns a `NodeList` of all of the `<div>`
elements on the page. `document.querySelector("div.lonely")` returns that
single lonely div.

`document` supports both [`querySelector`][dqs] and
[`querySelectorAll`][dqsa], letting you find elements in the entire
document. Elements themselves also support both [`querySelector`][eqs] and
[`querySelectorAll`][eqsa], letting you query for elements that are
descendants of that element. For example, the following expression will find
images that are descendants of `#my-id`:

```javascript
document.querySelector("#my-id").querySelectorAll("img")
```

In the preceding sample HTML page, it finds `<img id="inside">` but not `<img
id="outside">`.

With that in mind, what do these two expressions do?

```javascript
document.querySelectorAll("#my-id div div");
document.querySelector("#my-id").querySelectorAll("div div");
```

You might reasonably expect them to be equivalent. After all, one asks for
`div` elements inside `div` elements inside `#my-id`, and the other asks for
`div` elements inside `div` elements that are *descendants* of
`#my-id`. However, when you look at [this JSbin][jsbin], you'll see that they
produce very different results:

```javascript
document.querySelectorAll("#my-id div div").length === 1;
document.querySelector("#my-id").querySelectorAll("div div").length === 3;
```

### What is going on here?

It turns out that [`element.querySelectorAll`][eqsa] doesn't match elements
starting from `element`. Instead, it matches elements matching the query that
are also descendants of `element`. Therefore, we're seeing three `div`
elements: `div.lonely`, `div.outer`, `div.inner`. We're seeing them because
they both match the `div div` selector and are all descendants of `#my-id`.

The trick to remembering this is that CSS selectors are absolute. They are not
relative to any particular element, not even the element you're calling
`querySelectorAll` on.

This even works with elements *outside* the element you're calling
`querySelectorAll` on. For example, this selector:

```javascript
document.querySelector("#my-id").querySelector("div div div")
```

... matches `div.inner` in this snippet ([JSbin][jsbin2]):

```html
<!DOCTYPE html>
<html>
  <body>
    <div>
      <div id="my-id">
        <div class="inner"></div>
      </div>
    </div>
  </body>
</html>
```

I think this API is surprising, and the front-end engineers I've asked seem to
agree with me. However, this is not a bug. It's definitely how the spec claims
it should work. [John Resig commented][jresig] how he and others felt this
behavior was quite confusing back when the spec came out.

If you can't easily rewrite the selector to be absolute like we did above,
there are two alternatives: the `:scope` CSS pseudo-selector, and
`query`/`queryAll`.

The `:scope` pseudo-selector matches against the current scope. The
name comes from the [CSS scoping][scope-spec], which limits the scope
of styles to part of the document. The element we're calling
`querySelectorAll` on also counts as a scope, so this expression only
matches `div.inner`:

```javascript
document.querySelector("#my-id").querySelectorAll(":scope div div");
```

Unfortunately, [browser support][scope-compat] for scoped CSS and the `:scope`
pseudo-selector is extremely limited. Only recent versions of Firefox support
it by default. Blink-based browsers like Chrome and Opera require the
well-hidden experimental features flag to be turned on. Safari has a buggy
implementation. Internet Explorer doesn't support it at all.

The other alternative is `element.query`/`queryAll`. These are alternative
methods to `querySelector` and `querySelectorAll` that exist on DOM parent
nodes. They also take selectors, except these selectors are interpreted
relative to the element being queried from.  Unfortunately, these methods are
even more obscure: they are not referenced on MDN or `caniuse.com`, and are
missing from the [current DOM4 working draft][dom4-query], dated 18
June 2015. They were still present in [an older version][older-dom4], dated 4
February 2014, as well as in the [WHATWG Living Document][living-dom] version
of the spec. They have also been implemented by at least two polyfills:

* [Dom4][dom4-polyfill]
* [dom-elements][dom-elements-polyfill]

### Conclusion

In conclusion, the DOM spec doesn't always necessarily do the most obvious
thing. It's important to know pitfalls like these, because they're difficult
to discover from just the behavior. Fortunately, you can often rewrite your
selector so that it isn't a problem. If you can't, there's always a polyfill
to give you the modern API you want. Alternatively, libraries like jQuery can
also help you get a consistent, friendly interface for querying the DOM.

[csssel]: https://developer.mozilla.org/en-US/docs/Web/Guide/CSS/Getting_started/Selectors
[dqs]: https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelector
[dqsa]: https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelectorAll
[eqs]: https://developer.mozilla.org/en-US/docs/Web/API/Element/querySelector
[eqsa]: https://developer.mozilla.org/en-US/docs/Web/API/Element/querySelectorAll
[jsbin]: https://jsbin.com/hineco/edit?html,js,output
[jsbin2]: https://jsbin.com/woropuc/edit?html,js,output
[spec]: https://dom.spec.whatwg.org/#dom-parentnode-queryselectorall
[jresig]: https://ejohn.org/blog/thoughts-on-queryselectorall/
[scope-spec]: https://html.spec.whatwg.org/multipage/semantics.html#attr-style-scoped
[scope]: https://developer.mozilla.org/en-US/docs/Web/CSS/%3Ascope
[scope-compat]: https://developer.mozilla.org/en-US/docs/Web/CSS/%3Ascope#Browser_compatibility
[dom4-query]: https://www.w3.org/TR/dom/#interface-parentnode
[older-dom4]: https://www.w3.org/TR/2014/WD-dom-20140204/#interface-parentnode
[dom4-polyfill]: https://webreflection.github.io/dom4/
[dom-elements-polyfill]: https://github.com/barberboy/dom-elements
[living-dom]: https://dom.spec.whatwg.org/#interface-parentnode
