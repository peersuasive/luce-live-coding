****************
Luce Live Coding
****************
----------------------
See what you code live
----------------------

This is really just a naive approach taking the MainComponent from the Document
of the main class and pushing it to another Document.
Still, it does the job.

Further development would be smarter. If there's a need for it.

Requirements
============

* Linux
* Lua 5.1/luajit 2.X (untested with lua 5.2)
* inotify-tools
* lzmq (https://github.com/zeromq/lzmq.git)  
* Luce, obviously

Install
=======

link luce-live/lluceLive somewhere in PATH

.. code:: bash

   ~ $ sudo ln -s $SRC/luce-live/lluceLive /usr/local/bin/

Usage
=====

Open a terminal and start the watcher:

.. code:: bash

   ~/src/killer_app/src $ lluceLive main.lua classes/*

It'll start the LLive server and watch changes in main.lua and classes/*

Better use vim or emacs for this.

Adapt to your needs.

Tracking changes in included classes
====================================

Not really optimised yet,

``require`` needs to be overriden.

Add this at the beginning of main.lua and classes:

.. code:: lua

    local require, _require = require, _require
    if(LUCE_LIVE_CODING)then
        print( componentName )
        _require = _require and _require or require
        local function safe_require(p)
            package.loaded[p] = nil
            if ( pcall(_require,p) ) then
                return _require(p)
            end
        end
        require = safe_require
    end

See `lTox <https://github.com/peersuasive/ltox>`__ for a full example.

Roadmap
=======

* improve error message, show a console with colours, etc.
* track newly added classes on the fly  
* be more portable, at least OS X, at best Windows
* live coding on iOS, Android...  
* ...
