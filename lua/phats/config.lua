print( "pHats" )

local phat = pHats:add( "prikolmen", "models/player/items/humans/top_hat.mdl", Vector( -2.5, 0, -2.5), Angle( -15, 0, 0 ) )
phat:addSteamID( "STEAM_0:1:70096775" )
-- hat:addModel( "" )

local ak47 = pHats:add( "ak47", "models/weapons/w_rif_ak47.mdl", Vector( -10, 5, -5 ), Angle( -70, 95, 10 ) )
ak47:addSteamID( "STEAM_0:1:70096775" )
ak47:SetAttachment( "chest" )

--local ehat = pHats:add( "erick", "models/player/items/humans/top_hat.mdl", Vector( 0, 0, 0), Angle( 0, 180, 180 ) )
--ehat:addSteamID( "STEAM_0:1:95980398" )
--ehat:addModel( "models/player/group03/male_07.mdl" )
