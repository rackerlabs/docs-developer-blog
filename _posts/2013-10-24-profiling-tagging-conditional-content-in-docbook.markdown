---
layout: post
title: 'DocBook tips: Profiling (conditional content)'
date: '2013-10-24 10:00'
comments: true
author: Diane Fleming
published: true
categories:
  - General
---

Diane Fleming works heavily on the OpenStack API documentation - in this post
she covers profiling for Docbook.

<!-- more -->

*   [What is profiling](#whatisprofiling)
*   [Basic steps](#basicsteps)
*   [Example](#example)
*   [Gotcha](#gotcha)

<h2 id="whatisprofiling">What is profiling?</h2>

DocBook uses the term *profiling* to describe conditional text. DocBook provides a set of
profiling attributes that you can include on DocBook tags to mark some elements as conditional.

Let's say you want to create two versions of a document from one set of XML source files:
One version of the document is for beginning programmers and the other is for advanced programmers.

The following [basic steps](#basicsteps) and [example](#example) show you how to use profiling to accomplish this.

<h2 id="basicsteps">Basic steps</h2>

The simplest implementation of profiling requires three easy steps:
Choose a [profiling attribute](http://www.sagehill.net/docbookxsl/Profiling.html#MarkProfileText), create profiles in your pom.xml file, and mark elements as conditional by using the selected profiling attribute.

<ol>
<li><p>Choose the profiling attribute that makes sense for your document. Because you want to
create document versions based on the audience, this example uses the <code>audience</code> profiling attribute.</p>
<p>Then, create a string to represent each audience. For example, you might use <code>beginner</code>
for beginning programmers and <code>advanced</code> for advanced programmers.</p>
<p/></li>
<li><p>Add the following profiles to the appropriate configurations in your pom.xml file:</p>
<pre><code>&lt;configuration&gt;
    &lt;includes&gt;os-devguide.xml&lt;/includes&gt;
    &lt;profileAudience&gt;beginner&lt;/profileAudience&gt;
&lt;/configuration&gt;
&lt;configuration&gt;
    &lt;includes&gt;os-devguide.xml&lt;/includes&gt;
    &lt;profileAudience&gt;advanced&lt;/profileAudience&gt;
&lt;/configuration&gt;</code></pre>

</li>
<li><p>In the XML source files, tag the content that you want to appear in the beginner version
of the document as follows:</p>
<pre><code>&lt;section audience="beginner"&gt;
  &lt;title&gt;Programming Concepts&lt;/title&gt;
  ...
&lt;/section&gt;</code></pre>
<p>Tag the content that you want to appear in the advanced version of the document as follows:</p>
<pre><code>&lt;section audience="advanced"&gt;
  &lt;title&gt;Advanced Concepts&lt;/title&gt;
  ...
&lt;/section&gt;</code></pre>
<p>For content that is common to both versions of the book, tag that content as you normally would:
No need for conditions.</p>
<p/>
</li>
</ol>
<h2 id="example">Example</h2>
<p>The following example shows these profiling attributes in context.</p>
<p>Two books are generated from the same pom.xml file. One execution defines a beginner guide,
and the other defines an advanced guide.</p>
<pre><code>&lt;?xml version="1.0" encoding="UTF-8"?&gt;
&lt;executions&gt;
    &lt;execution&gt;
        &lt;id&gt;os-devguide-beginner&lt;/id&gt;
        &lt;goals&gt;
        &lt;goal&gt;generate-webhelp&lt;/goal&gt;
        &lt;/goals&gt;
        &lt;phase&gt;generate-sources&lt;/phase&gt;
        &lt;configuration&gt;
            &lt;includes&gt;os-devguide.xml&lt;/includes&gt;
            &lt;profileAudience&gt;beginner&lt;/profileAudience&gt;
        &lt;/configuration&gt;
    &lt;/execution&gt;
    &lt;execution&gt;
        &lt;id&gt;os-devguide-advanced&lt;/id&gt;
        &lt;goals&gt;
        &lt;goal&gt;generate-webhelp&lt;/goal&gt;
        &lt;/goals&gt;
        &lt;phase&gt;generate-sources&lt;/phase&gt;
        &lt;configuration&gt;
            &lt;includes&gt;os-devguide.xml&lt;/includes&gt;
            &lt;profileAudience&gt;advanced&lt;/profileAudience&gt;
        &lt;/configuration&gt;
    &lt;/execution&gt;
&lt;/executions&gt;
</code></pre>
<p>In the XML source file, you might include three sections that are tagged as follows:</p>
<pre><code>&lt;section audience="beginner"&gt;
  &lt;title&gt;Programming Concepts&lt;/title&gt;
  ...
&lt;/section&gt;
&lt;section&gt;
  &lt;title&gt;Concepts for Everyone&lt;/title&gt;
  ...
&lt;/section&gt;
&lt;section audience="advanced"&gt;
  &lt;title&gt;Advanced Concepts&lt;/title&gt;
  ...
&lt;/section&gt;</code></pre>
<p>The beginner guide shows the first and second sections. The advanced guide shows the second and third sections. If you have a configuration in your pom.xml file without a profile, that book shows only the second section.</p>
<p>You can use the profiling attribute on most tags. For example, you might tag a paragraph like this:</p>
<pre><code>&lt;para&gt;If you are a &lt;phrase audience="beginner"&gt;beginner&lt;/phrase&gt;
&lt;phrase audience="advanced"&gt;advanced programmer&lt;/phrase&gt;,
read &lt;phrase audience="beginner"&gt;Programming Concepts&lt;/phrase&gt;
&lt;phrase audience="advanced"&gt;Advanced Concepts&lt;/phrase&gt; section.&lt;/para&gt;</code></pre>
<p>In the beginner guide, the following text appears: <code>If you are a beginner, read Programming Concepts.</code></p>
<p>In the advanced guide, this text appears: <code>If you are an advanced programmer, read Advanced Concepts.</code></p>
<h2 id="gotcha">Gotcha</h2>
<p>When you use profiling, make sure to place conditional tags on the correct elements.</p>
<p>For example, the following mark-up can produce an error:</p>
<pre><code>&lt;procedure&gt;
&lt;title&gt;My procedure&lt;/title&gt;
    &lt;step&gt;&lt;para audience="beginner"&gt;A step for beginners.&lt;/para&gt;&lt;/step&gt;
    &lt;step&gt;&lt;para audience="advanced"&gt;A step for advanced programmers.&lt;/para&gt;&lt;/step&gt;
    &lt;step&gt;&lt;para&gt;A step for everyone.&lt;/para&gt;&lt;/step&gt;
&lt;/procedure&gt;</pre></code>
<p>Why? If your pom.xml file does not specify any profiles, the &lt;step&gt; tags have no content because the
interior &lt;para&gt; tags are ignored. Empty steps cause a build error.</p>
<p>To correct the error, use the following mark-up:</p>
<pre><code>&lt;procedure&gt;
&lt;title&gt;My procedure&lt;/title&gt;
    &lt;step audience="beginner"&gt;&lt;para&gt;A step for beginners.&lt;/para&gt;&lt;/step&gt;
    &lt;step audience="advanced&gt;&lt;para"&gt;A step for advanced programmers.&lt;/para&gt;&lt;/step&gt;
    &lt;step&gt;&lt;para&gt;A step for everyone.&lt;/para&gt;&lt;/step&gt;
&lt;/procedure&gt;</pre></code>
<p>This example works even if the pom.xml file does not provide profiles for these audiences:
The conditionalized steps are ignored. However, because the procedure contains one step that is not
conditionalized, the procedure successfully displays with one step.</p>