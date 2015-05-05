--[[
Copyright (c) 2015, Espen Braastad
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
  list of conditions and the following disclaimer in the documentation and/or
  other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]

local ngx = require "ngx"
local cjson = require "cjson"
local random = require "random"

local function get_property(key)
    local key = key:lower()
    for header, val in pairs(ngx.req.get_headers()) do
        header = header:lower()
        if header == key then
            return val
        end
    end
    for arg, val in pairs(ngx.req.get_uri_args()) do
        arg = arg:lower()
        if arg == key then
            return val
        end
    end
    return nil
end

local function get_seed()
    local counters = ngx.shared.counters
    local seed = nil
    if not counters then
        return false
    end

    local seed, flags = counters:incr("seed", 1)
    if not seed then
        succ, err, forcible = counters:set("seed", 1)
        seed = 1
    end

    return seed
end

-- Setting defaults
local response_status = 200
local content_length = nil

-- Delay
local header_delay = 0
local body_delay = 0

-- Misc
local help = nil

-- Output structure
local out = {}
local cache_control = {}
ngx.header["Server"] = "Dummy API"

out['request-headers'] = ngx.req.get_headers()
out['request-parameters'] = ngx.req.get_uri_args()

-- Input parsing
local arg = "header-delay"
local val = get_property(arg)
if val then
    val = tonumber(val)
    if val then
        out[arg] = val
        header_delay = val
    end
end

local arg = "body-delay"
local val = get_property(arg)
if val then
    val = tonumber(val)
    if val then
        out[arg] = val
        body_delay = val
    end
end

local arg = "response-status"
local val = get_property(arg)
if val then
    val = tonumber(val)
    if val then
        if val >= 100 and val < 600 then
            val = math.floor(val)
            out[arg] = val
            response_status = val
        end
    end
end

local arg = "content-length"
local val = get_property(arg)
if val then
    content_length = true
    out[arg] = true
end

local arg = "max-age"
local val = get_property(arg)
if val then
    val = tonumber(val)
    if val then
        val = math.abs(math.floor(val))
        table.insert(cache_control, arg .. "=" .. val)
        out[arg] = val
    end
end

local arg = "s-maxage"
local val = get_property(arg)
if val then
    val = tonumber(val)
    if val then
        val = math.abs(math.floor(val))
        table.insert(cache_control, arg .. "=" .. val)
        out[arg] = val
    end
end

local arg = "must-revalidate"
local val = get_property(arg)
if val then
    table.insert(cache_control, arg)
    out[arg] = true
end

local arg = "public"
local val = get_property(arg)
if val then
    table.insert(cache_control, arg)
    out[arg] = true
end

local arg = "private"
local val = get_property(arg)
if val then
    table.insert(cache_control, arg)
    out[arg] = true
end

local arg = "no-cache"
local val = get_property(arg)
if val then
    table.insert(cache_control, arg)
    out[arg] = true
end

local arg = "no-store"
local val = get_property(arg)
if val then
    table.insert(cache_control, arg)
    out[arg] = true
end

local arg = "no-transform"
local val = get_property(arg)
if val then
    table.insert(cache_control, arg)
    out[arg] = true
end

local arg = "random-content"
local val = get_property(arg)
if val then
    val = tonumber(val)
    if val then
        if val > 0 and val <= 10000000 then
            local seed = get_seed()
            math.randomseed(seed)
            length = math.abs(math.floor(val))
            out[arg] = random.token(length)
        end
    end
end

local arg = "predictable-content"
local val = get_property(arg)
if val then
    -- Generate some seed which usually is unique per URL
    local seed = ngx.req.get_method() .. ngx.var.uri
    if host then
        seed = seed .. host
    end
    math.randomseed(#seed)
    val = tonumber(val)
    if val then
        if val > 0 and val <= 10000000 then
            length = math.abs(math.floor(val))
            out[arg] = random.token(length)
        end
    end
end

local arg = "help"
local val = get_property(arg)
if val then
    help = true
end

local arg = "host"
local val = get_property(arg)
if val then
    out[arg] = val
end

out["method"] = ngx.req.get_method()
out["uri"] = ngx.var.uri

-- Print help text
if help then
    ngx.print([[
Dummy API
=========
The following request headers and query parameters will make an impact on the response.

Delay
-----
header-delay = {float}       Delay to first header byte
body-delay = {float}         Delay to first body byte

Cache-control
-------------
max-age = {int}              Set the response max-age value
s-maxage = {int}             Set the response s-maxage value
must-revalidate              Set must-revalidate
public                       Set public
private                      Set private
no-store                     Set no-store
no-cache                     Set no-cache
no-transform                 Set no-transform

Misc
----
content-length               Set the content-length header, otherwise chunked transfer encoding is used
random-content = {int}       Add random string to the response of given length
predictable-content = {int}  Add predictable string to the response of given length
response-status = {int}      Set the response status
]])
    ngx.exit(200)
end

-- Response status
ngx.status = response_status

-- Headers
ngx.header["Content-Type"] = "application/json"

if #cache_control > 0 then
    ngx.header["Cache-control"] = table.concat(cache_control, ", ")
end

-- Encode body here
local raw_body = cjson.encode(out)
if content_length then
    ngx.header["Content-length"] = #raw_body
end

-- Time to first header
if header_delay then
    if header_delay > 0 then
        ngx.flush()
        ngx.sleep(header_delay)
    end
end

ok, err = ngx.send_headers()

-- Time to first body byte
if body_delay then
    if body_delay > 0 then
        ngx.flush()
        ngx.sleep(body_delay)
    end
end

-- Print body
ngx.print(raw_body)

ok, err = ngx.eof()
