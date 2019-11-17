--[[

    [o*] : hydroxide_auxiliary.lua

        ~ This file contains functions which are used in, but can also be used outside, Hydroxide

]]

local env = {
    get_upvalues = debug.getupvalues or getupvalues or getupvals or false,
    get_upvalue = debug.getupvalue or getupvalue or getupval or false,
    get_metatable = getrawmetatable or debug.getmetatable or false,
    get_protos = debug.getprotos or getprotos or false,
    get_stack = debug.getstack or getstack or false,
    get_reg = getreg or debug.getregistry or false,
    get_gc = getgc or false,
    get_thread_context = (syn and syn.get_thread_identity) or getthreadcontext or getcontext or false,
    set_thread_context = (syn and syn.set_thread_identity) or setthreadcontext or setcontext or false,
    set_upvalue = debug.setupvalue or setupvalue or setupval or false,
    set_readonly = setreadonly or make_writeable or false,
    is_readonly = isreadonly or false,
    is_l_closure = islclosure or false,
    is_x_closure = is_synapse_function or is_protosmasher_closure or issentinelclosure or false,
    hook_function = hookfunction or hookfunc or false,
    new_cclosure = newcclosure or false,
    to_clipboard = (syn and syn.write_clipboard) or writeclipboard or toclipboard or setclipboard or false,
    check_caller = checkcaller or false,
    write_file = writefile or false,
    load_file = loadfile or (readfile and function(file)return loadstring(readfile(file)) end) or false,
}

local supported = true
for i,v in next, env do
    if not v then
        warn("Your exploit requires: " .. i)
        supported = false
    end
end

if not supported then
    error("Your exploit doesn't support the Hydroxide auxiliary unit!")
end

getgenv().oh = {}
oh.env = env
oh.events = {}
oh.initialize = function()
    oh.ui.Parent = game:GetService("CoreGui")
    oh.running = true
end

oh.exit = function()
    if oh.running then
        for i,v in next, oh.events do
            v:Disconnect()
            v = nil
        end

        oh.ui:Destroy()
        oh.running = false
    end
end

-- Hydroxide's file import function
getgenv().import = function(file_name)
    if type(file_name) == "string" then 
        if oh.load_from_file then -- Load from the exploit's workspace folder if this flag is true
            local result = env.load_file("Hydroxide/" .. file_name)
            return (type(result) == "function" and result()) or result
        else -- Load from the Hydroxide repository 
            return loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/nrv-ous/Hydroxide/in-dev/" .. file_name))()
        end
    else -- If it's not a string, we assume it's a roblox asset id
        return game:GetObjects("rbxassetid://" .. file_name)[1]
    end
end

-- Safer tostring method (to prevent __tostring protection)
getgenv().to_string = function(data)
    local result -- Our finalized data
    local readonly -- (if our data is a table) Flag to see if our table is marked as readonly or not
    local metatable = env.get_metatable(data) -- Check if our data has a metatable
    local __tostring = metatable and rawget(metatable, "__tostring") -- Save the tostring method if it exists

    if (type(data) == "table" or type(data) == "userdata") and __tostring and __tostring ~= metatable then -- If the tostring method exists, and our data is a table or userdata then remove the __tostring method
        if env.is_readonly(metatable) then -- If the table is read only, then make it writeable
            readonly = true
            env.set_readonly(metatable, false)
        end

        rawset(metatable, "__tostring", nil)
    end

    result = tostring(data) -- Since we've removed the __tostring method, the data *should* be safe to call from tostring now

    if __tostring ~= metatable and __tostring then -- If we erased the __tostring method, then set it back (to prevent detection)
        rawset(metatable, "__tostring", __tostring)
        if readonly then -- If our table was readonly, and modified, then set it back for safety
            env.set_readonly(metatable, true)
        end
    end

    return result
end

-- Hydroxide's upvalue scanning function
getgenv().scan_upvalue = function(upvalue, check_tables)
    local results = {} -- Our final results

    for _, closure in pairs(env.get_gc()) do -- Iterate through all running functions in the game
        if type(closure) == "function" and not env.is_x_closure(closure) then -- Make sure our function is actually a function, and is not a function created by our exploit
            for idx, val in pairs(env.get_upvalues(closure)) do -- Search through all the upvalues of the current function
                if check_tables and type(val) == "table" then -- If the upvalue is a table, then search for any matching keys or values
                    for key, value in pairs(val) do
                        if to_string(key) == tostring(upvalue) or to_string(value) == tostring(upvalue) then -- If we find any matching keys or values, then save the table 
                            if not results[closure] then
                                results[closure] = {}
                            end
                            
                            results[closure][idx] = val
                        end
                    end
                elseif (type(val) == "string" and val:lower():find(upvalue:lower(), 1, true)) or tonumber(upvalue) == val or ((not type(val) == "table" or type(val) == "function") and tostring(value) == to_string(val)) then -- If our upvalue is any other type, check if it matches what we searched for, and save it if it matches
                    if not results[closure] then
                        results[closure] = {}
                    end
    
                    results[closure][idx] = val
                end
            end
        end
    end

    return results 
end
