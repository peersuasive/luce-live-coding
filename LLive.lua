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
local function cb(socket)
    local what = socket:recv()
    local data = socket:recv()
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

res = app:start(MainWindow, function(...)
    poller:poll(1)
end)

listen:close()
context:term()
return res
