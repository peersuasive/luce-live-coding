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

require       "pl"
local zmq     = require "zmq"
require       "zmq.zhelpers"
local zmsg    = require"zmq.pmsg"
require       "zmq.poller"

local app, luce = require"luce.LApplication"("Luce Live Coding")

local context = zmq.init(1)
local poller  = zmq.poller(1)
local listen  = context:socket(zmq.SUB)
listen:setopt(zmq.SUBSCRIBE, LUCE_EVENT)
assert( listen:bind("tcp://127.0.0.1:20027"), "Can't bind socket" )

local function MainWindow(params)
    local app, luce = app, luce
    local Colours = luce.Colours
    local wsize = {250,20}
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
local current = nil
local function cb(socket)
    socket:recv()
    local data = socket:recv()
    if(data == current )then
        print"(no change)"
        return
    end
    current = data
    local chunk, e = loadstring(data)
    if not(chunk) then
        print(string.format("ERROR: %s", e))
    else
        local r, status, err = pcall(luce.reload, luce, chunk)
        if not(r) then 
            print(string.format("LLLLL...That was a joke. Not loaded: you got a mistake somewhere: %s", status))
        elseif not (status) then
            print(string.format("LLLLL...That was a joke. Not loaded: you got a mistake somewhere: %s", err))
        else
            print("LLLLL...Loaded!")
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
