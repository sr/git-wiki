git-wiki: because who needs cool names when you use git?
========================================================

git-wiki is a wiki that relies on git to keep pages' history
and [Sinatra][] to serve them.

I wrote git-wiki as a quick and dirty hack, mostly to play with Sinatra.
It turned out that Sinatra is an awesome little web framework and that this hack
isn't as useless as I first though since I now use it daily.

However, it is definitely not feature rich and will probably never be because
I mostly use it as a web frontend for `git`, `ls` and `vim`.

If you want history, search, etc. you should look at other people's [forks][],
especially [al3x][]'s one.


## Install

The fellowing [gems][] are required to run git-wiki:

- sinatra
- mojombo-grit
- haml
- git
- BlueCloth
- rubypants

Run `rake bootstrap && ruby git-wiki.rb` and point your browser at <http://0.0.0.0:4567/>. Enjoy!

## Licence
               DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                       Version 2, December 2004

    Copyright (C) 2008 Simon Rozet <simon@rozet.name>
    Everyone is permitted to copy and distribute verbatim or modified
    copies of this license document, and changing it is allowed as long
    as the name is changed.

               DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
      TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

     0. You just DO WHAT THE FUCK YOU WANT TO.

## Quotes

<blockquote>
<p>[...] the first wiki engine I'd consider worth using for my own projects.</p>
<p><cite><a href="http://www.dekorte.com/blog/blog.cgi?do=item&amp;id=3319">Steve Dekorte</a></cite></p>
</blockquote>

<blockquote>
<p>Oh, it looks like <a href="http://atonie.org/2008/02/git-wiki">Git Wiki</a> may be the
starting point for what I need...</p>
<p><cite><a href="http://tommorris.org/blog/2008/03/09#pid2761430">
Tom Morris on "How to build the perfect wiki"</a></cite></p>
</blockquote>

<blockquote>
<p>What makes git-wiki so cool is because it is backed by a git store, you can clone your
wiki just like you could any other git repository. I’ve always wanted a wiki that I could
a.) pull offline when I didn’t have access to the Internets and b.) edit (perhaps in bulk)
in my favorite text editor. git-wiki allows both.</p>
<p><cite><a href="http://github.com/willcodeforfoo/git-wiki/wikis">Cloning your wiki</a></cite></p>
</blockquote>

<blockquote>
<p>Numerous people have written diff and merge systems for wikis; TWiki even uses RCS.
If they used git instead, the repository would be tiny, and you could make a personal
copy of the entire wiki to take on the plane with you, then sync your changes back when you're done.</p> 
<p><cite><a href="http://www.advogato.org/person/apenwarr/diary/371.html">Git is the next Unix</a></cite></p>
</blockquote>

## See also

- [WiGit](http://el-tramo.be/software/wigit) – git-wiki in PHP
- [ikiwiki](http://ikiwiki.info/) – a wiki compiler supporting git


  [Sinatra]: http://sinatrarb.com
  [GitHub]: http://github.com/sr/git-wiki
  [forks]: http://github.com/sr/git-wiki/network
  [al3x]: http://github.com/al3x/github
  [gems]: http://www.rubygems.org/
