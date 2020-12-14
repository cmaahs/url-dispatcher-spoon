# url-dispatcher-spoon

I use this to handle launching links into my isolated Firefox windows, and launching conference app links.

## Mac OS Configuration

In order to use this, one has to switch the DEFAULT handler for HTTP/HTTPS to be Hammerspoon.  I was initially
skeptical, though after having used it as my default for almost a year now, I've not really had any problems
with it.
## Conference URLs

This wasn't the original use for me, though this has been the greatest use.  You can see my [no-more-lateness](https://github.com/cmaahs/no-more-lateness)
project for an example of how I am inspecting my google calendar and then auto-launching my conference applications
automatically.  Since I already had a good way to identify running application windows by using Hammerspoon LUA code,
I decided not to pursue figuring out that code in Go, and rather, just hand off the URLs to Hammerspoon.  This gave
two benefits.  The first we already covered, it is easy to inspect an applications windows.  The second is that
launching URLs via HTTP/HTTPS for these conferences opens a TAB in the default browser, and it ends up covering up the
current tab you were reading.  I find this annoying.  This way I simply send the URL request to an isolated Firefox
browser I don't usually have a bunch of tabs open in, allowing me to switch to it and choose to close all but the tab
I'm currently on.

## Isolated Firefox Windows

I install a bunch of different Firefox apps, each running under it's own Firefox profile, and having custom icons.
This way I can have a unique icon on my task bar to allow me to switch to a WEB based app in a similar way I would
a normally running app.  So for instance, I have a github specific Firefox window, so in my URL Dispatcher it looks
for 'github.com' links (usually clicked from Slack) and opens those links in the correct window.  Of course clicking
github.com links in another browser window (like Chrome) clearly will just open in browser session the link was
clicked from.  Still, the problems are less than the annoyance of having to search through browser windows/tabs to
find what I'm trying to get back to.  Obviously not for everyone!
