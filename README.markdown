git-wiki
========

git-wiki is a wiki that relies on [git][] to keep pages' history 
and [Sinatra][] to serve them. See [git-wiki's homepage][git-wiki]
for more informations.

git-wiki relies on the fellowing gems:
- git (the gem, as in `gem install git`)
- BlueCloth
- rubypants

Sinatra and [HAML][] are vendored as [git submodules][gs].
To get them, run the fellowing commands :

    % cd git-wiki
    % git submodule init
    % git submodule update
    # this step is needed because sinatra itself use git submodule
    % cd vendor/sinatra
    % git submodule init
    % git submodule update


Note that git-wiki is released under the terms of the [WTPL][] so really, you
can do what the fuck you want with it.

Tip: run git-wiki as a daemon
------------------------------

1. Install the gem [daemons][].

    `% sudo gem install daemons`

2. Create a new service (don't forget to modify the path to git-wiki)
<pre><code>% sudo cat > /etc/init.d/git-wiki &lt;&lt;EOF
&#35;!/usr/bin/env ruby
require 'rubygems'
require 'daemons'
Daemons.run('/home/simon/src/git-wiki/git-wiki.rb',
     :dir_mode   => :system,
     :log_output => true,
     :mode       => :exec
)
EOF</code></pre>

3. Install it as a boot service. On Ubuntu, run

    `% sudo /usr/sbin/update-rc.d git-wiki defaults`

[git]: http://git.or.cz/
[Sinatra]: http://sinatrarb.com
[git-wiki]: http://atonie.org/2008/02/git-wiki
[HAML]: http://haml.hamptoncatlin.com/
[gs]: http://www.kernel.org/pub/software/scm/git/docs/git-submodule.html
[WTPL]: http://sam.zoy.org/wtfpl/
[daemons]: http://daemons.rubyforge.org/
