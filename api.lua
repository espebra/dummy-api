local ngx = require "ngx"
local cjson = require "cjson"

-- Setting defaults
local response_status = 200
local content_length = nil

-- Delay
local response_delay = 0
local header_delay = 0
local body_delay = 0

-- Cache control
local max_age = nil
local s_maxage = nil
local must_revalidate = nil
local public = nil
local private = nil

local help = nil

-- Output structure
out = {}
local cache_control = {}

-- Input parsing
for arg, val in pairs(ngx.req.get_uri_args()) do
    if type(val) == "table" then
        ngx.say(arg, ": ", table.concat(val, ", "))
    else
        if arg == "response-delay" then
            response_delay = tonumber(val)
            out[arg] = val
        elseif arg == "header-delay" then
            header_delay = tonumber(val)
            out[arg] = val
        elseif arg == "body-delay" then
            body_delay = tonumber(val)
            out[arg] = val
        elseif arg == "response-status" then
            if tonumber(val) >= 100 and tonumber(val) < 600 then
                response_status = tonumber(val)
                out[arg] = val
            end
        elseif arg == "content-length" then
            content_length = true
            out[arg] = val
        elseif arg == "max-age" then
            max_age = tonumber(val)
            table.insert(cache_control, "max-age=" .. max_age)
            out[arg] = val
        elseif arg == "s-maxage" then
            s_maxage = tonumber(val)
            table.insert(cache_control, "s-maxage=" .. s_maxage)
            out[arg] = val
        elseif arg == "must-revalidate" then
            table.insert(cache_control, arg)
            out[arg] = true
        elseif arg == "public" then
            table.insert(cache_control, arg)
            out[arg] = true
        elseif arg == "private" then
            table.insert(cache_control, arg)
            out[arg] = true
        elseif arg == "help" then
            help = true
        end
    end
end

for header, val in pairs(ngx.req.get_headers()) do
    if (header == "host") then
        out[header] = val
    end
end

out["method"] = ngx.req.get_method()
out["uri"] = ngx.var.uri

-- Print help text
if help then
    ngx.say("Test API")
    ngx.say("========")
    ngx.say("")
    ngx.say("Delay")
    ngx.say("-----")
    ngx.say("response-delay = {number}        Delay to first byte")
    ngx.say("header-delay = {number}          Delay to first header byte")
    ngx.say("body-delay = {number}            Delay to first body byte")
    ngx.say("")
    ngx.say("Cache-control")
    ngx.say("-------------")
    ngx.say("max-age = {number}               Set the response max-age value")
    ngx.say("s-maxage = {number}              Set the response s-maxage value")
    ngx.say("must-revalidate                  Set must-revalidate")
    ngx.say("public                           Set public")
    ngx.say("private                          Set private")
    ngx.say("")
    ngx.say("Misc")
    ngx.say("----")
    ngx.say("response-status = {number}       Set the response status")
    ngx.say("content-length                   Set the content-length")
    ngx.exit(200)
end

-- Time to  byte
if response_delay then
    ngx.sleep(response_delay)
end

-- Response status
ngx.status = response_status

-- Headers
ngx.header["Server"] = "API"
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
    ngx.flush()
    ngx.sleep(header_delay)
end

ok, err = ngx.send_headers()

-- Time to first body byte
if body_delay then
    ngx.flush()
    ngx.sleep(body_delay)
end

-- Print body
ngx.say(raw_body)

ok, err = ngx.eof()
