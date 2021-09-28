local cjson = require("cjson.safe").new()
local BasePlugin = require "kong.plugins.base_plugin"

local ErrorFrameworkHandler = BasePlugin:extend()

local kong = kong
local ngx = ngx
local find = string.find
local lower = string.lower
local concat = table.concat
local apim_system_name = "KONG"

ErrorFrameworkHandler.PRIORITY = 802
ErrorFrameworkHandler.VERSION = "1.0.0"

function ErrorFrameworkHandler:new()
    ErrorFrameworkHandler.super.new(self, "error-framework")
end

-- Utility function --
local function is_json_body(content_type)
    return content_type and find(lower(content_type), "application/json", nil, true)
end


local function read_json_body(body)
    if body then
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
    for _ ,v in pairs(s) do
      local i, _ = string.find(v, "_")
      splitTableResult[string.sub(v, 1, i-1)] = string.sub(v, i+1, string.len(v))
    end
    return splitTableResult
  end


-- Plugin implementation --
local function transform_json_body(conf, buffered_data)
    local system, error_message, error_detail
    local status = tostring(kong.response.get_status())

-- Retrieve default values
    local defaultErrorTypeList = split(conf.defaulterror, ",")
    local defaultErrorType = splitTable(defaultErrorTypeList)

-- JSON Payloads errors --
    if is_json_body(kong.response.get_header("Content-Type")) then
        local json_body = read_json_body(buffered_data)

        local errorType = {}
        for name, value in ipairs(conf.error.values) do
            if string.find(value, ("errorStatus_" .. status)) then
                local errorTypeList = split(value, ",")
                errorType = splitTable(errorTypeList)
            end                    
        end

        local targetRrrorType = {}
        for name, value in ipairs(conf.targeterror.values) do
            if string.find(value, ("errorStatus_" .. status)) then
                local targetRrrorTypeList = split(value, ",")
                targetRrrorType = splitTable(targetRrrorTypeList)
            end                    
        end

        -- Error occured at the upstream application --        
        if kong.response.get_source() == "service" then

            -- Empty body ---            
            if json_body == nil then
                system = errorType["system"]
                error_message = errorType["message"] or defaultErrorType["message"]
                error_detail = errorType["detail"]or defaultErrorType["detail"]

            -- Retrieve error from upstream response --                
            else
                system = targetRrrorType["system"]
                if targetRrrorType["codePath"]  then
                    status = assert(load("return " .. targetRrrorType["codePath"], nil, "t", json_body))() 
                else
                    status = errorType["errorStatus"]
                end
                if targetRrrorType["messagepath"]  then
                   error_message = assert(load("return " .. targetRrrorType["messagepath"], nil, "t", json_body))() 
                elseif errorType["message"] then
                    error_message = errorType["message"]
                else
                    error_message = defaultErrorType["message"]
                end
                if targetRrrorType["detailpath"]  then
                     error_detail = assert(load("return " .. targetRrrorType["detailpath"], nil, "t", json_body))() 
                elseif errorType["detail"] then
                    error_detail = errorType["detail"]
                else
                   error_detail = defaultErrorType["detail"]
                end
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
                error_detail = errorType["detail"] 
            elseif json_body["detail"] then
                error_detail = json_body["detail"]
            else 
                error_detail = errorType["detail"]
            end
        end
    else
        -- Non JSON Payloads --
        local errorType = {}
        for name, value in ipairs(conf.error) do
            if string.find(value, ("errorStatus_" .. status)) then
                local errorTypeList = split(conf.parameters, ",")
                errorType = splitTable(errorTypeList)
            end                    
        end

        error_message = errorType["message"] or defaultErrorType["message"]
        error_detail = errorType["detail"] or defaultErrorType["detail"]

        if kong.response.get_source() == "service" then
            system = errorType["system"]
        else
            system = apim_system_name
        end
    end

    local error_body = {}

    error_body.traceId= kong.request.get_header("traceid")
    error_body.timestamp = "timestamp"

    local error = {}
    error.httpCode = status
    error.message = error_message
    error.detail = error_detail
    error.system = system

    local error_source_array = {}
    error_source_array[1] = error
    error_body.error = error_source_array

    return cjson.encode(error_body)
end

function ErrorFrameworkHandler:access(conf)
    ErrorFrameworkHandler.super.access(self)
    kong.service.request.clear_header("Accept-Encoding")

end


function ErrorFrameworkHandler:header_filter(conf)
    ErrorFrameworkHandler.super.header_filter(self)
    local http_status = kong.response.get_status()
    if ((http_status < 200) or (http_status > 299)) then
        kong.response.clear_header("Content-Length")
        if not (is_json_body(kong.response.get_header("Content-Type"))) then
            kong.response.set_header("Content-Type", "application/json")
        end
    end
end

function ErrorFrameworkHandler:body_filter(conf)
    ErrorFrameworkHandler.super.body_filter(self)
    local http_status = kong.response.get_status()

    if ((http_status < 200) or (http_status > 299)) then
        local ctx = ngx.ctx
        local chunk, eof = ngx.arg[1], ngx.arg[2]

        ctx.rt_body_chunks = ctx.rt_body_chunks or {}
        ctx.rt_body_chunk_number = ctx.rt_body_chunk_number or 1

        if eof then
            local chunks = concat(ctx.rt_body_chunks)
            local body = transform_json_body(conf, chunks)
            ngx.arg[1] = body or chunks
        else
            ctx.rt_body_chunks[ctx.rt_body_chunk_number] = chunk
            ctx.rt_body_chunk_number = ctx.rt_body_chunk_number + 1
            ngx.arg[1] = nil
        end
    end
end

return ErrorFrameworkHandler
