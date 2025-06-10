local function readBuffer(buffer, pos, refs)
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
    elseif typeMarker == -3 then
        local len = buffer.readu16(buffer, pos)
        pos = pos + 2
        local tbl = {}
        for _ = 1, len do
            local key, value
            key, pos = readBuffer(buffer, pos, refs)
            value, pos = readBuffer(buffer, pos, refs)
            tbl[key] = value
        end
        return tbl, pos
    elseif typeMarker == -4 then
        local len = buffer.readi8(buffer, pos)
        local enumName = buffer.readstring(buffer, pos + 1, len)
        local value = buffer.readu8(buffer, pos + 1 + len)
        return Enum[enumName]:FromValue(value), pos + 2 + len
    elseif typeMarker == -5 then
        local value = buffer.readi16(buffer, pos)
        return BrickColor.new(value), pos + 2
    elseif typeMarker == -6 then
        local len = buffer.readi8(buffer, pos)
        local enumName = buffer.readstring(buffer, pos + 1, len)
        return Enum[enumName], pos + 1 + len
    elseif typeMarker == 1 then
        return buffer.readu8(buffer, pos), pos + 1
    elseif typeMarker == 2 then
        return buffer.readi16(buffer, pos), pos + 2
    elseif typeMarker == 3 then
        return buffer.readi32(buffer, pos), pos + 4
    elseif typeMarker == 4 then
        return buffer.readf64(buffer, pos), pos + 8
    elseif typeMarker == 5 then
        return buffer.readu8(buffer, pos) == 1, pos + 1
    elseif typeMarker == 6 then
        local len = buffer.readu8(buffer, pos)
        local str = buffer.readstring(buffer, pos + 1, len)
        return str, pos + 1 + len
    elseif typeMarker == 7 then
        local len = buffer.readu16(buffer, pos)
        local str = buffer.readstring(buffer, pos + 2, len)
        return str, pos + 2 + len
    elseif typeMarker == 8 then
        local len = buffer.readi32(buffer, pos)
        local str = buffer.readstring(buffer, pos + 4, len)
        return str, pos + 4 + len
    elseif typeMarker == 9 then
        local x = buffer.readf32(buffer, pos)
        local y = buffer.readf32(buffer, pos + 4)
        local z = buffer.readf32(buffer, pos + 8)
        return Vector3.new(x, y, z), pos + 12
    elseif typeMarker == 10 then
        local x = buffer.readf32(buffer, pos)
        local y = buffer.readf32(buffer, pos + 4)
        return Vector2.new(x, y), pos + 8
    elseif typeMarker == 11 then
        local components = {}
        for i = 1, 12 do
            components[i] = buffer.readf32(buffer, pos + (i - 1) * 4)
        end
        return CFrame.new(table.unpack(components)), pos + 48
    elseif typeMarker == 12 then
        local r = buffer.readu8(buffer, pos)
        local g = buffer.readu8(buffer, pos + 1)
        local b = buffer.readu8(buffer, pos + 2)
        return Color3.fromRGB(r, g, b), pos + 3
    else
        error("Unsupported type marker: " .. typeMarker)
    end
end

return readBuffer
