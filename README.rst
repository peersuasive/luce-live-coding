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

Install
=======

link luce-live/lluceLive somewhere in PATH

.. code:: bash

   ~ $ sudo ln -s $SRC/luce-live/lluceLive /usr/local/bin/


Usage
=====

Open a terminal and start the watcher:

.. code:: bash

   ~/src/killer_app/src $ lluceLive main.lua

It'll start the LLive server and watch changes in main.lua.

Better use vim or emacs for this.

Adapt to your needs.


Requirements
============

* Lua 5.1 / luajit 2.X (**not ready yet for lua 5.2**)
* Linux
* inotify-tools
* ØMQ 4.X
* lua-zmq (Neopallium's)
* Luce, obviously

Roadmap
=======

* improve error message, show a console with colours, etc.
* be more portable, at least OS X, at best Windows
* if possible, update only what's changed
* live coding on iOS, Android...  
* ...
