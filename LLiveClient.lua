#!/usr/bin/env luajit
--[[----------------------------------------------------------------------------

liveClient.lua

Luce Live Coding Client

    @alias meta

    @author Christophe Berbizier (cberbizier@peersuasive.com)
    @license GPLv3
    @copyright 

(c) 2014, Peersuasive Technologies

------------------------------------------------------------------------------]]

local LUCE_EVENT = "PSM.EVENTS.LUCE.RELOAD "
local LUCE_ERROR = "PSM.EVENTS.LUCE.ERROR "

local port = 20087

local zmq     = require"lzmq"
local zpoller = require"lzmq.poller"
local assert = zmq.assert

-- load class
-- grab MainWindow
--
-- send chunk to live:20027
-- NOTE: should better use gadokai, of course

local _assert = assert
local function assert(truth, msg, ...)
    if(truth)then return truth end
    print(string.format("ERROR: "..(msg or""), ...))
end


-- NOTE: could put safe_require around here...


_G.LUCE_LIVE_CODING = 1
local luceLiveEnv = {
    LUCE_LIVE_CODING = 1,
    print   = print,
    require = require,
    --[[ FIXME: called but doesn't reload -- find why
    require = function(p)
        local _require = _require or require
        print("loaded ?", package.loaded[p])
        for k,v in next, package.loaded do print(k,v) end
        package.loaded[p] = nil
        if ( pcall(_require,p) ) then
            print"CALL"
            return _require(p)
        end
    end,
    --]]
    assert  = assert,
}
luceLiveEnv._G = luceLiveEnv

local function prepare_chunk(file)
    local f, err = loadfile(file)
    if not f then return f, err end
    setfenv(f, luceLiveEnv)
    local r, chunk, errOrControl, ms = pcall(f)
    if(r and chunk)then
        return string.dump(chunk), errOrControl and string.dump(errOrControl) or "", tostring(ms)
    else
        return nil, chunk, errOrControl
    end
end

local poller  = zpoller.new(1)
local context = zmq.context(1)
local client  = context:socket(zmq.PUB)
assert( client:connect("tcp://127.0.0.1:"..port) )
poller:poll(1) -- workaround bug in 4.X when pub isn't on the binding side

-- send

local status = 0
local chunk = arg[1]
local force = arg[2] or "false"
local chunk, errOrControl, ms = prepare_chunk(chunk)
if(chunk)then
    client:send(LUCE_EVENT, zmq.SNDMORE)
    client:send(chunk, zmq.SNDMORE)
    client:send(errOrControl or "", zmq.SNDMORE)
    client:send(tostring(ms or 0), zmq.SNDMORE)
    client:send(force)
else
    print(string.format("ERROR: %s", err))
    client:send(LUCE_ERROR, zmq.SNDMORE)
    client:send(errOrControl or "[no message]", zmq.SNDMORE)
    client:send("0", zmq.SNDMORE)
    client:send(force)
end

client:close()
context:term()

return status
