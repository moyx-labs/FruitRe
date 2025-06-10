local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Event = ReplicatedStorage.Assets.Okay

-- ฟังก์ชันถอดรหัส buffer
local function readBuffer(buffer, pos, refs)
    if not buffer or buffer.len(buffer) == 0 then
        return nil, pos, "Empty buffer"
    end
    local typeMarker = buffer.readi8(buffer, pos)
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
        return nil, pos, "Unsupported type marker: " .. typeMarker
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
            if not payload or buffer.len(payload) == 0 then
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
            print("Decoded Payload:", table.concat(decoded, ", "))
        end)
        if not success then
            warn("Error decoding buffer:", result)
        end
    end
    return oldFireServer(self, ...)
end)
