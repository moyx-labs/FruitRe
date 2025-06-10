print("ss")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Event = ReplicatedStorage.Assets.Okay

-- ฟังก์ชันถอดรหัส buffer
local function readBuffer(buffer, pos, refs)
    if not buffer then
        return nil, pos, "Buffer is nil"
    end
    if typeof(buffer) ~= "buffer" then
        return nil, pos, "Payload is not a buffer: " .. typeof(buffer)
    end
    if buffer.len(buffer) == 0 then
        return nil, pos, "Buffer is empty"
    end
    local success, typeMarker = pcall(buffer.readi8, buffer, pos)
    if not success then
        return nil, pos, "Failed to read buffer: " .. tostring(typeMarker)
    end
    pos = pos + 1
    if typeMarker == 0 then
        return nil, pos
    elseif typeMarker == -1 then
        if refs and #refs > 0 then
            local index = buffer.readu8(buffer, pos)
            local instance = refs[index]
            if typeof(instance) == "Instance" then
                return instance, pos + 1
            end
            return nil, pos + 1
        end
        return nil, pos + 1
    elseif typeMarker == -2 then
        local len = buffer.readu16(buffer, pos)
        pos = pos + 2
        local array = {}
        for _ = 1, len do
            local value
            value, pos = readBuffer(buffer, pos, refs)
            table.insert(array, value)
        end
        return array, pos
    elseif typeMarker == 6 then
        local len = buffer.readu8(buffer, pos)
        local str = buffer.readstring(buffer, pos + 1, len)
        return str, pos + 1 + len
    elseif typeMarker == 2 then
        return buffer.readi16(buffer, pos), pos + 2
    else
        return nil, pos, "Unsupported type marker: " .. tostring(typeMarker)
    end
end

-- Hook FireServer
local oldFireServer
oldFireServer = hookmetamethod(Event, "__namecall", function(self, ...)
    local args = {...}
    if getnamecallmethod() == "FireServer" then
        local success, result = pcall(function()
            print("Identifier Buffer:", buffer.tostring(args[1]) or "nil")
            print("Payload Buffer:", buffer.tostring(args[2]) or "nil")
            local payload = args[2]
            if not payload then
                warn("Payload is nil")
                return
            end
            if typeof(payload) ~= "buffer" then
                warn("Payload is not a buffer: " .. typeof(payload))
                return
            end
            if buffer.len(payload) == 0 then
                warn("Payload buffer is empty")
                return
            end
            local decoded = {}
            local pos = 0
            while pos < buffer.len(payload) do
                local value, new_pos, err = readBuffer(payload, pos)
                if err then
                    warn("Decode error:", err)
                    break
                end
                pos = new_pos
                table.insert(decoded, tostring(value))
            end
            if #decoded > 0 then
                print("Decoded Payload:", table.concat(decoded, ", "))
            else
                print("No decoded payload")
            end
        end)
        if not success then
            warn("Error decoding buffer:", tostring(result))
        end
    end
    return oldFireServer(self, ...)
end)
