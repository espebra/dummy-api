local ngx = require "ngx"
local cjson = require "cjson"

function get_property(key)
    for header, val in pairs(ngx.req.get_headers()) do
        if header == key then
            return val
        end
    end
    for arg, val in pairs(ngx.req.get_uri_args()) do
        if arg == key then
            return val
        end
    end
    return nil
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
out = {}
local cache_control = {}

-- Input parsing
arg = "header-delay"
val = get_property(arg)
if val then
    header_delay = tonumber(val)
    out[arg] = header_delay
end

arg = "body-delay"
val = get_property(arg)
if val then
    body_delay = tonumber(val)
    out[arg] = body_delay
end

arg = "response-status"
val = get_property(arg)
if val then
    if tonumber(val) >= 100 and tonumber(val) < 600 then
        response_status = math.floor(tonumber(val))
        out[arg] = response_status
    end
end

arg = "content-length"
val = get_property(arg)
if val then
    content_length = true
    out[arg] = true
end

arg = "max-age"
val = get_property(arg)
if val then
    max_age = math.abs(math.floor(tonumber(val)))
    table.insert(cache_control, arg .. "=" .. max_age)
    out[arg] = max_age
end

arg = "s-maxage"
val = get_property(arg)
if val then
    s_maxage = math.abs(math.floor(tonumber(val)))
    table.insert(cache_control, arg .. "=" .. s_maxage)
    out[arg] = s_maxage
end

arg = "must-revalidate"
val = get_property(arg)
if val then
    table.insert(cache_control, arg)
    out[arg] = true
end

arg = "public"
val = get_property(arg)
if val then
    table.insert(cache_control, arg)
    out[arg] = true
end

arg = "private"
val = get_property(arg)
if val then
    table.insert(cache_control, arg)
    out[arg] = true
end

arg = "no-cache"
val = get_property(arg)
if val then
    table.insert(cache_control, arg)
    out[arg] = true
end

arg = "no-store"
val = get_property(arg)
if val then
    table.insert(cache_control, arg)
    out[arg] = true
end

arg = "help"
val = get_property(arg)
if val then
    help = true
end

arg = "host"
val = get_property(arg)
if val then
    out[arg] = val
end

out["method"] = ngx.req.get_method()
out["uri"] = ngx.var.uri

-- Print help text
if help then
    ngx.say("Dummy API")
    ngx.say("=========")
    ngx.say("")
    ngx.say("The following request headers and query parameters will make an")
    ngx.say("impact on the response.")
    ngx.say("")
    ngx.say("Delay")
    ngx.say("-----")
    ngx.say("header-delay = {float}           Delay to first header byte")
    ngx.say("body-delay = {float}             Delay to first body byte")
    ngx.say("")
    ngx.say("Cache-control")
    ngx.say("-------------")
    ngx.say("max-age = {int}                  Set the response max-age value")
    ngx.say("s-maxage = {int}                 Set the response s-maxage value")
    ngx.say("must-revalidate                  Set must-revalidate")
    ngx.say("public                           Set public")
    ngx.say("private                          Set private")
    ngx.say("no-store                         Set no-store")
    ngx.say("no-cache                         Set no-cache")
    ngx.say("")
    ngx.say("Misc")
    ngx.say("----")
    ngx.say("response-status = {int}          Set the response status")
    ngx.say("content-length                   Set the content-length, otherwise chunked encoding is used")
    ngx.exit(200)
end

-- Response status
ngx.status = response_status

-- Headers
ngx.header["Server"] = "Dummy API"
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
