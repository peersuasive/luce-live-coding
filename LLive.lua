#!/usr/bin/env psm
--[[----------------------------------------------------------------------------

live.lua

Luce Live Coding

    @alias meta

    @author Christophe Berbizier (cberbizier@peersuasive.com)
    @license GPLv3
    @copyright 

(c) 2014, Peersuasive Technologies

------------------------------------------------------------------------------]]

local LUCE_EVENT = "PSM.EVENTS.LUCE.RELOAD "
local LUCE_ERROR = "PSM.EVENTS.LUCE.ERROR "

local port = 20087

require       "pl"
local zmq     = require "zmq"
require       "zmq.zhelpers"
local zmsg    = require"zmq.pmsg"
require       "zmq.poller"
local htime    = function() local s, u, n = htime.time(); return s..u end

local app, luce = require"luce.LApplication"("Luce Live Coding", ...)

local context = zmq.init(1)
local poller  = zmq.poller(1)
local listen  = context:socket(zmq.SUB)
listen:setopt(zmq.SUBSCRIBE, LUCE_EVENT)
listen:setopt(zmq.SUBSCRIBE, LUCE_ERROR)
assert( listen:bind("tcp://127.0.0.1:"..port), "Can't bind socket" )

local function MainWindow(params)
    local app, luce = app, luce
    local Colours = luce.Colours
    local wsize = {250,40}
    local dw = luce:Document("Luce Live Coding: dw")
    local mc = luce:MainComponent("Luce Live Coding: mc")
    mc:paint(function(g)
        g:setFont(12.0)
        g:setColour( Colours.grey )
        g:drawText("Luce Live Coding - waiting for input", 
                        mc:getLocalBounds(), luce.JustificationType.centred, true);
    end)
    local K  = string.byte 
    local kc = setmetatable(luce.KeyPress.KeyCodes,{__index=function()return 0 end})
    dw:keyPressed(function(k)
        local k, m = k:getKeyCode(), k:getModifiers()
        if (k==K"Q" or k==K"q") and m:isCommandDown() then
            app:exit(0)
        elseif (k==K"w" or k==K"W") and (m:isCommandDown() ) then
            app:exit(0)
        else
            return false
        end
        return true
    end)
    mc:setSize(wsize)
    dw:setContentOwned(mc, true)
    dw:setBounds{0,0,wsize[1], wsize[2]}
    dw:setVisible(true)
    return dw
end

local res = 0
local force = false
local current = nil
local remote_control = nil
local ms = 0
local function cb(socket)
    local what = socket:recv()
    local data = socket:recv()
    local rcontrol = socket:recv()
    ms = tonumber(socket:recv()) * 1000
    local force = socket:recv()
    force = (force ~= "false") and (force ~= "0")
    if(what == LUCE_ERROR)then
        print(string.format("***** %s *****", os.date()))
        print(string.format("ERROR: %s", data))
        return
    end
    if not(force) and (data == current)then
        print"(no change)"
        return
    end
    current = data
    local chunk, e = loadstring(data)
    print(string.format("***** %s *****", os.date()))
    if not(chunk) then
        print(string.format("ERROR: %s", e))
    else
        if(rcontrol ~= "")then
            local rcontrol_chunk, e2 = loadstring(rcontrol)
            if not(rcontrol_chunk)then
                print(string.format("ERROR: %s", e2))
                return
            end
            remote_control = rcontrol_chunk
        end
        local r, status, err = pcall(luce.reload, luce, chunk)
        if not(r) then 
            print(string.format("ERROR: %s", status))
        elseif not (status) then
            print(string.format("ERROR: %s", err))
        else
            print("OK")
        end
    end
end
poller:add(listen, zmq.POLLIN, cb)

local stopNow = false
local lastTime, now = htime(), 0
res = app:start(MainWindow, { function(...)
    local now = htime()
    poller:poll(0)
    if (remote_control) and ((ms==0) or (ms>0 and ms < (now - lastTime))) then
        remote_control()
        lastTime = now
    end
end, 1})

listen:close()
context:term()
return res
