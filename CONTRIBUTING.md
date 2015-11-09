# Contributing to our Blog

First, thanks for your interest in contributing and helping us craft quality content for our official Developer Blog. Second, in order to make contributing a pleasant experience while maintaining a visual and content standard, complete these steps before writing and submitting a blog entry for publishing.

#### Writing your blog entry

1. Fork this repo, then clone your fork.

1. Before you start working, make sure your content is up-to-date and merged with the right branch:

  ```bash
  git remote add upstream git@github.com:rackerlabs/docs-developer-blog.git
  git checkout master
  git fetch upstream
  git checkout -b name-of-your-branch
  git merge upstream/master
  ```

1. Create a file inside `_posts/` with the following naming convention `YYYY-MM-DD-title-of-your-post.md` where `YYYY-MM-DD` is the date you want you entry to be published. The published URL for your post becomes `https://developer.rackspace.com/blog/title-of-your-post/` when published, whereas the file itself is named `YYYY-MM-DD-title-of-your-post.md`.

1. Add Jekyll front matter (i.e. metadata) to the top of the file you created in the previous step, for example:

  ```yaml
  ---
  layout: post
  title: "Blog Entry Title"
  date: YYYY-MM-DD 23:59
  comments: false
  author: Author(s) name(s)
  published: true
  categories:
      - This Category
      - That Category
      - Other Category
  ---
  ```

  Make sure that the dates in the file name and front matter match.

1. If you're willing to answer comments about your post, set `comments: true`. Be sure to subscribe to your post comments by clicking on the **Subscribe** link at the very bottom of the post once it's published.

1. Format your blog entry using [markdown](http://daringfireball.net/projects/markdown/basics). If you are not comfortable authoring in markdown, send a message to @rgbkrk for other options.

#### Writing your Post

**Please include an excerpt marker** after your first paragraph or so to separate the preview text that appears on the blog index page from the full article. To do so, use the following HTML comment:

```html
The excerpt.

<!-- more -->

The rest of your article.
```

The marker comment must be on its own line, at column 1, and separated from content on either side by a single blank line.

**To include images in your post**, place them in a subdirectory of `_assets/img/` within a subdirectory that has the same name as the file containing your post. Within your post, use the following markup:

```markdown
![Alt text here]({% asset_path YYYY-MM-DD-title-of-your-post/filename.png %})
```

#### Previewing your Post

To view your post locally and make sure that it's rendering correctly, you will need:

 * [Ruby](https://www.ruby-lang.org/en/downloads/), preferably version 2.2.2
 * [bundler](http://bundler.io/), version 1.9.4

From the directory that you cloned the blog to, run:

```bash
bundle install

bundle exec jekyll serve --watch
```

Once you see the message "Server running....", visit [http://127.0.0.1:4000/blog/](http://127.0.0.1:4000/blog/) to see the rendered blog.

#### Submitting your Blog entries

Follow these steps to submit your entry for publication.

1. Submit a PR (pull request) against `master` branch.
2. Include this information in your PR message, even if you've submitted blog entries previously:

 - author(s) mini bio, soft capped to 75 words
 - author(s) social media contact info
 - accept or decline to allow redaction, editing or structure changes by technical writer staff
 - desired date of publishing
 - whether or not you're willing to answer comments about your post (see step #5 above)
