git-wiki
========

git-wiki is a wiki that relies on git to keep pages' history
and [Sinatra][] to serve them.

Features of this fork
---------------------

### Support for images

You can add images to /img folder of your git repository. Subfolders are
also supported. At least gif, png and jpg supported - content type is
set automatically by Sinatra. You can reference the images then from
your wiki pages like `![My picture](/img/2009/my_picture.jpg)`

No web interface at this time - use `git commit`.


### Custom h1 header

If your wiki page contains a markdown h1 header, then
this one is used on the page.

If not, then h1 is created out of the file name (as in original git-wiki).


Plans
-----

* support for attachments
* nicer CSS
* support for deeper Wiki page folder structure
* do not rely on wiki words
* support for special programmed pages - via haml or liquid template
  engine


Original README by Simon Rozet
------------------------------

I wrote git-wiki as a quick and dirty hack, mostly to play with Sinatra.
It turned out that Sinatra is an awesome little web framework and that this
hack isn't as useless as I first though since I now use it daily.

However, it is definitely not feature rich and will probably never be because
I mostly use it as a web frontend for `git`, `ls` and `vim`.

If you want history, search, etc. you should look at other people's [forks][].

Install
-------

The following [gems][] are required to run git-wiki:

- [Sinatra][]
- [mojombo-grit][]
- [HAML][]
- [RDiscount][]

Run with `mkdir ~/wiki && (cd ~/wiki && git init) && ./run.ru -sthin -p4567`
and point your browser at <http://0.0.0.0:4567/>. Enjoy!

See also
--------

- [How to use vim to edit &lt;textarea&gt; in lynx][tip]
- [WiGit][] think git-wiki except implemented in PHP
- [ikiwiki][] is a wiki compiler supporting git


  [Sinatra]: http://www.sinatrarb.com
  [GitHub]: http://github.com/sr/git-wiki
  [forks]: http://github.com/sr/git-wiki/network
  [al3x]: http://github.com/al3x/gitwiki
  [gems]: http://www.rubygems.org/
  [mojombo-grit]: http://github.com/mojombo/grit
  [HAML]: http://haml.hamptoncatlin.com
  [RDiscount]: http://github.com/rtomayko/rdiscount
  [tip]: http://wiki.infogami.com/using_lynx_&_vim_with_infogami
  [WiGit]: http://el-tramo.be/software/wigit
  [ikiwiki]: http://ikiwiki.info

Quotes
------

<blockquote>
<p>[...] the first wiki engine I'd consider worth using for my own projects.</p>
<p><cite>
<a href="http://www.dekorte.com/blog/blog.cgi?do=item&amp;id=3319">
Steve Dekorte</a>
</cite></p>
</blockquote>

<blockquote>
<p>Oh, it looks like <a href="http://atonie.org/2008/02/git-wiki">Git Wiki</a>
may be the starting point for what I need...</p>
<p><cite><a href="http://tommorris.org/blog/2008/03/09#pid2761430">
Tom Morris on "How to build the perfect wiki"</a></cite></p>
</blockquote>

<blockquote>
<p>What makes git-wiki so cool is because it is backed by a git store,
you can clone your wiki just like you could any other git repository.
I’ve always wanted a wiki that I could a.) pull offline when I didn’t
have access to the Internets and b.) edit (perhaps in bulk)
in my favorite text editor. git-wiki allows both.</p>
<p><cite><a href="http://github.com/willcodeforfoo/git-wiki/wikis">
Cloning your wiki</a></cite></p>
</blockquote>

<blockquote>
<p>Numerous people have written diff and merge systems for wikis;
TWiki even uses RCS. If they used git instead, the repository would be tiny, and
you could make a personal copy of the entire wiki to take on the plane with you,
then sync your changes back when you're done.</p>
<p><cite><a href="http://www.advogato.org/person/apenwarr/diary/371.html">
Git is the next Unix</a></cite></p>
</blockquote>


MIT license
-----------
Copyright (c) 2009 Vladimir Dobriakov, vladimir.dobriakov@innoq.com
Copyright (c) Simon Rozet
 
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
 
The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.
 
