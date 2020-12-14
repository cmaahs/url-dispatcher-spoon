--- === URLDispatcher ===
---
--- Route URLs to different applications with pattern matching
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/URLDispatcher.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/URLDispatcher.spoon.zip)
---
--- Sets Hammerspoon as the default browser for HTTP/HTTPS links, and
--- dispatches them to different apps according to the patterns defined
--- in the config. If no pattern matches, `default_handler` is used.

local obj={}
obj.__index = obj

-- Metadata
obj.name = "URLDispatcher"
obj.version = "0.1"
obj.author = "Diego Zamboni <diego@zzamboni.org>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.red = hs.fnutils.copy(hs.alert.defaultStyle)
obj.red.fillColor = {
    alpha = 0.7,
    red   = 1
}
obj.red.strokeColor = {
    alpha = 1,
    red   = 1
}
obj.yellow = hs.fnutils.copy(hs.alert.defaultStyle)
obj.yellow.fillColor = {
    alpha = 1,
    red   = 1,
    green = 1,
}
obj.yellow.strokeColor = {
    alpha = 1,
    red   = 0,
    green = 0,
    blue  = 0
}
obj.yellow.textColor = {
  alpha = 1,
  red   = 0,
  green = 0,
  blue  = 0
}


--- URLDispatcher.default_handler
--- Variable
--- Bundle ID for default URL handler. (Defaults to `"com.apple.Safari"`)
obj.default_handler = "com.apple.Safari"

--- URLDispatcher.decode_slack_redir_urls
--- Variable
--- If true, handle Slack-redir URLs to apply the rule on the destination URL. Defaults to `true`
obj.decode_slack_redir_urls = true

--- URLDispatcher.url_patterns
--- Variable
--- URL dispatch rules.
--- A table containing a list of dispatch rules. Each rule should be its own table in the format: `{ "url pattern", "application bundle ID", "function" }`, and they are evaluated in the order they are declared. Note that the patterns are [Lua patterns](https://www.lua.org/pil/20.2.html) and not regular expressions. Defaults to an empty table, which has the effect of having all URLs dispatched to the `default_handler`. If "application bundle ID" is specified, that application will be used to open matching URLs. If no "application bundle ID" is specified, but "function" is provided (and is a Lua function) it will be called with the URL.
obj.url_patterns = { }

--- URLDispatcher.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
obj.logger = hs.logger.new('URLDispatcher')

-- Local functions to decode URLs
function hex_to_char(x)
   return string.char(tonumber(x, 16))
end

function unescape(url)
   return url:gsub("%%(%x%x)", hex_to_char)
end

local function split(str, sep)
   local result = {}
   local regex = ("([^%s]+)"):format(sep)
   for each in str:gmatch(regex) do
      table.insert(result, each)
   end
   return result
end

--- URLDispatcher:dispatchURL(scheme, host, params, fullUrl)
--- Method
--- Dispatch a URL to an application according to the defined `url_patterns`.
---
--- Parameters (according to the [httpCallback](http://www.hammerspoon.org/docs/hs.urlevent.html#httpCallback) specification):
---  * scheme - A string containing the URL scheme (i.e. "http")
---  * host - A string containing the host requested (e.g. "www.hammerspoon.org")
---  * params - A table containing the key/value pairs of all the URL parameters
---  * fullURL - A string containing the full, original URL
function obj:dispatchURL(scheme, host, params, fullUrl)
   local url = fullUrl
   self.logger.df("Dispatching URL '%s'", url)
   if self.decode_slack_redir_urls then
      local newUrl = string.match(url, 'https://slack.redir.net/.*url=(.*)')
      if newUrl then
         url = unescape(newUrl)
      end
   end
   for i,pair in ipairs(self.url_patterns) do
      local p = pair[1]
      local app = pair[2]
      local checkConf = pair[3]
      local func = pair[4]

      if string.match(app, "/Applications/Firefox*") then
         -- application path based
         local runningConf = false
         if string.match(url, p) then
            self.logger.df("Match found, opening with '%s'", app)
            local appname = split(app, "/")
            self.logger.df("AppName '%s'", appname[2])
            local justapp = split(appname[2], ".")
            self.logger.df("JustApp '%s'", justapp[1])
            local profile = split(justapp[1], "-")
            self.logger.df("Profile '%s'", profile[2])
            local launchcmd = app.." --new-tab -P "..profile[2].." "..url
            self.logger.df("Launching with '%s'", launchcmd)
            if checkConf then
               local zoom = hs.application.get'zoom.us'
               if zoom then
                   local zoomwin = zoom:allWindows()
                   local zoomcount = table_count(zoomwin)
                   -- hs.alert('Zoom Windows '.. tostring(zoomcount))
                   if zoomcount > 1 then
                       runningConf = true
                   end
               end
               local team = hs.application.get'Microsoft Teams'
               if team then
                  local teamwin = team:allWindows()
                  local teamcount = table_count(teamwin)
                  --  hs.alert('Team Windows '.. tostring(teamcount))
                  if teamcount > 0 then
                     runningConf = true
                 end
               end
               local webex = hs.application.get'Cisco Webex Meetings'
               if webex then
                  local webexwin = webex:allWindows()
                  local webexcount = table_count(webexwin)
                  -- hs.alert('Webex Windows'.. tostring(webexcount))
                  if webexcount > 0 then
                     runningConf = true
                  end
               end
            end
            if not runningConf then
                os.execute(launchcmd)
            else
               local screens = hs.screen.allScreens()
               for _, newScreen in ipairs(screens) do
                 hs.alert('New Meeting Trying to Auto Start', self.yellow, newScreen)
               end
            end
            return
         -- else
         --    if string.match(url, "https?://allianz%-agn%.webex%.com/allianz%-agn") then
         --       hs.alert("WTF")
         --    end
         end
      else
         -- bundle id based
         if string.match(url, p) then
            id = app
            if id ~= nil then
               self.logger.df("Match found, opening with '%s'", id)
               hs.application.launchOrFocusByBundleID(id)
               hs.urlevent.openURLWithBundle(url, id)
               return
            end
            if func ~= nil then
               self.logger.df("Match found, calling func '%s'", func)
               func(url)
               return
            end
         end
      end
   end
   self.logger.df("No match found, opening with default handler '%s'", self.default_handler)
   hs.application.launchOrFocusByBundleID(self.default_handler)
   hs.urlevent.openURLWithBundle(url, self.default_handler)
end

--- URLDispatcher:start()
--- Method
--- Start dispatching URLs according to the rules
function obj:start()
   if hs.urlevent.httpCallback then
      self.logger.w("An hs.urlevent.httpCallback was already set. I'm overriding it with my own but you should check if this breaks any other functionality")
   end
   hs.urlevent.httpCallback = function(...) self:dispatchURL(...) end
   hs.urlevent.setDefaultHandler('http')
   --   hs.urlevent.setRestoreHandler('http', self.default_handler)
   return self
end

return obj
