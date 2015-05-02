local ngx = require "ngx"
local cjson = require "cjson"
local random = require "random"

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

function generate_string(l)
    if l < 1 then return nil end -- Check for l < 1
    local s = "" -- Start string
    for i = 1, l do
        s = s .. string.char(math.random(32, 126)) -- Generate random number from 32 to 126, turn it into character and add to string
    end
    return s -- Return string
end

-- Setting defaults
local response_status = 200
local content_length = nil
local random_body = nil

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
    val = tonumber(val)
    if val then
        out[arg] = val
    end
end

arg = "body-delay"
val = get_property(arg)
if val then
    val = tonumber(val)
    if val then
        out[arg] = val
    end
end

arg = "response-status"
val = get_property(arg)
if val then
    val = tonumber(val)
    if val then
        if val >= 100 and val < 600 then
            val = math.floor(val)
            out[arg] = val
        end
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
    val = tonumber(val)
    if val then
        val = math.abs(math.floor(val))
        table.insert(cache_control, arg .. "=" .. val)
        out[arg] = val
    end
end

arg = "s-maxage"
val = get_property(arg)
if val then
    val = tonumber(val)
    if val then
        val = math.abs(math.floor(val))
        table.insert(cache_control, arg .. "=" .. val)
        out[arg] = val
    end
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

arg = "no-transform"
val = get_property(arg)
if val then
    table.insert(cache_control, arg)
    out[arg] = true
end

arg = "random-content"
val = get_property(arg)
if val then
    math.randomseed(os.time())
    val = tonumber(val)
    if val then
        length = math.abs(math.floor(val))
        out[arg] = random.token(length)
    end
end

arg = "predictable-content"
val = get_property(arg)
if val then

    -- Generate some seed which usually is unique per URL
    local seed = ngx.req.get_method() .. ngx.var.uri
    if host then
        seed = seed .. host
    end
    math.randomseed(#seed)
    val = tonumber(val)
    if val then
        length = math.abs(math.floor(val))
        out[arg] = random.token(length)
    end
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
    ngx.say("The following request headers and query parameters will make an impact on the response.")
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
    ngx.say("no-transform                     Set no-transform")
    ngx.say("")
    ngx.say("Misc")
    ngx.say("----")
    ngx.say("content-length                   Set the content-length header, otherwise chunked transfer encoding is used")
    ngx.say("random-content = {int}           Add random string to the response of given length")
    ngx.say("predictable-content = {int}      Add predictable string to the response of given length")
    ngx.say("response-status = {int}          Set the response status")
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
