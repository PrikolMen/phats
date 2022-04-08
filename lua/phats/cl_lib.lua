do
    local pHat = {}
    pHat.__index = pHat
    debug.getregistry().pHat = pHat

    function pHat:__tostring()
        return "pHat - " .. self["__name"]
    end

    pHat["__color"] = color_white:ToVector()

    do
        local IsColor = IsColor
        function pHat:SetColor( color )
            assert( IsColor( color ), "bad argument #1 (Color expected)" )
            self["__color"] = color:ToVector()
            self["__alpha"] = color["a"] / 255 or nil
            return self
        end
    end

    do
        function pHat:GetColor()
            return self["__color"][1], self["__color"][2], self["__color"][3]
        end
    end

    function pHat:SetSize( size, delay )
        self["__size"] = type( size ) == "number" and size or nil
        self["__size_delay"] = type( delay ) == "number" and delay or 0
        return self
    end

    function pHat:SetAttachment( attachmentName )
        self["__attachment"] = type( attachmentName ) == "string" and attachmentName or "eyes"
        return self
    end

    function pHat:IsValid()
        return self["__name"] != nil
    end

    function pHat:addSteamID( str )
        assert( type(str) == "string", "bad argument #1 (string expected)" )
        assert( str:Replace(" ", "") != "", "bad argument #1 (string is empty)" )
        table.insert( self.steamids, str )
        return self
    end

    function pHat:addSteamID64( str )
        assert( type(str) == "string", "bad argument #1 (string expected)" )
        assert( str:Replace(" ", "") != "", "bad argument #1 (string is empty)" )
        table.insert( self.steamids, util.SteamIDFrom64( str ) )
        return self
    end

    function pHat:addModel( str )
        assert( type(str) == "string", "bad argument #1 (string expected)" )
        assert( str:Replace(" ", "") != "", "bad argument #1 (string is empty)" )
        table.insert( self.models, Model( str ) )
        return self
    end

    function pHat:addHasWeapon( str )
        assert( type(str) == "string", "bad argument #1 (string expected)" )
        assert( str:Replace(" ", "") != "", "bad argument #1 (string is empty)" )
        table.insert( self.weapons, str )
        return self
    end

    function pHat:check( ply )
        if IsValid( ply ) then
            if IsValid( ply[ self["__plyIndex"] ] ) then
                return false
            end

            local plySteamID = ply:SteamID()
            local steamid_state = table.IsEmpty( self.steamids )
            for num, steamid in ipairs( self.steamids ) do
                if (steamid == plySteamID) then
                    steamid_state = true
                end
            end

            local plyModel = ply:GetModel()
            local models_state = table.IsEmpty( self.models )
            for num, model in ipairs( self.models ) do
                if (model == plyModel) then
                    models_state = true
                end
            end

            local weapons_state = table.IsEmpty( self.weapons )
            for num, class in ipairs( self.weapons ) do
                if ply:HasWeapon( class ) then
                    weapons_state = true
                end
            end

            return steamid_state and models_state and weapons_state
        end

        return false
    end

    do
        local LocalToWorld = LocalToWorld
        function pHat:CalcPosition( ply )
            local attachment_id = ply:LookupAttachment( self["__attachment"] )
            if (attachment_id > 0) then
                local attachment = ply:GetAttachment( attachment_id )
                if (attachment != nil) then
                    return LocalToWorld( self["__pos"], self["__ang"], attachment["Pos"], -attachment["Ang"] )
                end
            end

            return LocalToWorld( self["__pos"], self["__ang"], ply:EyePos(), -ply:GetAngles() )
        end
    end

    function pHat:draw( ply, flags )
        local hat = ply[ self["__plyIndex"] ]
        if IsValid( hat ) then
            if not ply:Alive() then
                local ragdoll = ply:GetRagdollEntity()
                if IsValid( ragdoll ) then
                    ply = ragdoll
                end
            end

            local r, g, b = render.GetColorModulation()
            render.SetColorModulation( self:GetColor() )
                local oldBlend = render.GetBlend()
                local alpha = self["__alpha"]
                if (alpha != nil) then
                    render.SetBlend( alpha )
                end

                    local origin, angle = self:CalcPosition( ply )
                    hat:SetRenderOrigin( origin )
                    hat:SetRenderAngles( angle )
                    hat:DrawModel( flags )

                render.SetBlend( oldBlend )
            render.SetColorModulation( r, g, b )
        else
            ply[ self["__plyIndex"] ] = ClientsideModel( self["__model"] )

            local hat = ply[ self["__plyIndex"] ]
            if IsValid( hat ) then
                hat:SetupBones()
                hat:SetNoDraw( true )

                hat["__player"] = ply
                hook.Add("Think", hat, function( self )
                    if not IsValid( self["__player"] ) then
                        self:Remove()
                    end
                end)

                local size = self["__size"]
                if type( size ) == "number" then
                    hat:SetModelScale( size, self["__size_delay"] )
                end
            else
                pHats:remove( self["__name"] )
            end
        end
    end

    do
        local function UpdateHats()
            for num, ply in ipairs( player.GetHumans() ) do
                for num, hat in ipairs( pHats.Created ) do
                    if hat:check( ply ) then
                        hook.Add("PostPlayerDraw", ply, function( self, ply, flags )
                            if (self:EntIndex() == ply:EntIndex()) and IsValid( hat ) then
                                hat:draw( self, flags )
                            end
                        end)
                    end
                end
            end
        end

        timer.Create("pHats_search", 15, 0, UpdateHats)

        concommand.Add("pHats_update", UpdateHats)

        concommand.Add("pHats_clear", function()
            for num, hat in ipairs( pHats.Created ) do
                hat["__name"] = nil
                table.remove( pHats.Created, num )
            end
        end)

        concommand.Add("pHats_list", function()
            PrintTable( pHats.Created )
        end)

        hook.Add("HUDPaint", "pHatsInit", function()
            hook.Remove("HUDPaint", "pHatsInit")
            UpdateHats()
        end)
    end

    do
        local vector_origin = vector_origin
        local angle_zero = angle_zero

        function pHats:add( name, model, origin, angle )
            assert( type( name ) == "string", "bad argument #1 (string expected)" )
            assert( name:Replace(" ", "") != "", "bad argument #1 (string is empty)" )

            for num, hat in ipairs( self.Created ) do
                if (hat["__name"] == name) then
                    print("Hat with name '" .. name .. "' - already exist!")

                    hat["__model"] = isstring( model ) and model or hat["__model"]
                    hat["__pos"] = isvector( origin ) and origin or hat["__pos"]
                    hat["__ang"] = isangle( angle ) and angle or hat["__ang"]

                    return hat
                end
            end

            assert( type( model ) == "string", "bad argument #2 (string expected)" )
            assert( model:Replace(" ", "") != "", "bad argument #2 (string is empty)" )

            local hat = setmetatable({
                ["__name"] = name,
                ["__model"] = model,
                ["__pos"] = isvector( origin ) and origin or vector_origin,
                ["__ang"] = isangle( angle ) and angle or angle_zero,
                ["__attachment"] = "eyes",
                ["steamids"] = {},
                ["weapons"] = {},
                ["models"] = {}
            }, pHat )

            hat["__plyIndex"] = "pHat_" .. name

            table.insert( self.Created, hat )

            return hat
        end
    end

    function pHats:remove( name )
        for num, hat in ipairs( self.Created ) do
            if (hat["__name"] == name) then
                table.remove( self.Created, num )
                hat["__name"] = nil
                return true
            end
        end

        return false
    end

end