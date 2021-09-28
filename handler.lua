local cjson = require("cjson.safe").new()
local BasePlugin = require "kong.plugins.base_plugin"
local ErrorFrameworkHandler = BasePlugin:extend()

local kong = kong
local ngx = ngx
local find = string.find
local lower = string.lower
local concat = table.concat
local apim_system_name = kong

ErrorFrameworkHandler.PRIORITY = 802
ErrorFrameworkHandler.VERSION = "1.0.0"

function ErrorFrameworkHandler:new()
    ErrorFrameworkHandler.super.new(self, "error-framework")
end

    -- Utility Function --
local function is_json_body(content_type)
    return content_type and find(lower(content_type), "application/json" , nil , true)
end

local function read_json_body(body)
    if  body then
        return cjson.decode(body)
    end
end

local function split(s, delimiter)
    local splitResult = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do 
        table.insert(splitResult, match);
    end
    return splitResult;
end

local function splitTable(s)
    local splitTableResult = {};
    for _, v in pairs(s) do 
        local i, _ = string.find(v , "_")
        splitTableResult[string.sub(v, 1 , i-1)] = string.sub(v, i+1, string.len(v))
    end
    return splitTableResult
end


    --- Plugin implementation ---
local function transform_json_body(conf, buffered_data)
    local system, error_message, error_detail
    local status = tostring(kong.response.get_status())

    -- Retrieve default values
    local defaultErrorType = {}
    local defaultErrorTypeList = split(conf.defaulterror, ",")	
    defaultErrorType = splitTable(defaultErrorTypeList)

    --- JSON Payload errors ---
if is_json_body(kong.response.get_header("Content-Type")) then
    local json_body = read_json_body(buffered_data)
    local errorType = {}
    for name, value in ipairs(conf.error.values) do 
        if string.find(value, ("errorStatus_".. status)) then
            local errorTypeList = split(value, ",")
            errorType = splitTable(errorTypeList)
        end
    end

    local targetErrorType = {}
    for name, value in ipairs(conf.targeterror.values) do
        if string.find(value, ("errorStatus_".. status)) then
            local targetErrorTypeList = split(value, ",")
            targetErrorType = splitTable(targetErrorTypeList)
        end
    end
     
    -- Error occured at the upstream application --
    if kong.response.get_source() == "service" then
        system = errorType["system"] or targetErrorType["system"]
    -- no response body ---
        if json_body == nil then
            error_message = errorType["message"] or defaultErrorType["message"]
            error_detail = errorType["detail"] or defaultErrorType["detail"]

        else
    -- Retrieve error from the upstream response if required --
            status = assert(load("return "..targetErrorType["codePath"], nil, "t" , json_body ))()
            error_message = assert(load("return "..targetErrorType["messagePath"], nil, "t" , json_body ))()
            error_detail = assert(load("return "..targetErrorType["detailPath"], nil, "t" , json_body ))()
        end
    -- Error occured in KONG --
    else
        system = apim_system_name
        if json_body == nil then
            error_message = errorType["message"]
        elseif json_body["message"] then
            error_message = json_body["message"]
        else
            error_message = errorType["message"]
        end
        
        if json_body == nil then
            error_message = errorType["detail"]
        elseif json_body["detail"] then
            error_message = json_body["detail"]
        else
            error_message = errorType["detail"]
        end
    end
else
    -- Non JSON Payloads --
    local errorType = {}
    for name, value in inpairs(conf.error.values) do 
        if string.find(value, ("errorStatus_".. status) then
            local errorTypeList = split(value, ",")
            errorType = splitTable(errorTypeList)
        end
    end

    error_message = errorType["message"]
    error_detail = errorType["detail"]
    if kong.response.get_source() == "service" then
        system = errorType["system"]
    else
        system = apim_system_name






