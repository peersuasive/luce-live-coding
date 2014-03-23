#!/usr/bin/env psm
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

require       "pl"
local zmq     = require "zmq"
require       "zmq.zhelpers"
local zmsg    = require"zmq.pmsg"

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

_G.LUCE_LIVE_CODING = 1
local luceLiveEnv = {
    LUCE_LIVE_CODING = 1,
    print   = print,
    require = require,
    assert  = assert,
}
luceLiveEnv._G = luceLiveEnv

local function prepare_chunk(file)
    print("file", file)
    local f, err = loadfile(file)
    if not f then return f, err end
    setfenv(f, luceLiveEnv)
    local chunk, err = f()
    if(chunk)then
        return string.dump(chunk)
    else
        return nil, err
    end
end

local context = zmq.init(1)
local client  = context:socket(zmq.PUB)
assert( client:connect("tcp://127.0.0.1:20027") )
--s_sleep(500)

-- send

local status = 0
local chunk, err = prepare_chunk(...)
if(chunk)then
    client:send(LUCE_EVENT, zmq.SNDMORE)
    client:send(chunk)
else
    status = 1
    print("ERROR:", chunk, err)
end

client:close()
context:term()

return status
