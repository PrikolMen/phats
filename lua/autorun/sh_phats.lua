if SERVER then
    AddCSLuaFile("phats/config.lua")    
    AddCSLuaFile("phats/cl_lib.lua")    
else
    pHats = pHats or {
        ["Created"] = {}
    }

    include("phats/cl_lib.lua")
    include("phats/config.lua")
end