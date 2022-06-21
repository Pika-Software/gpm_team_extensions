local packageName = "Team Extensions"
local logger = GPM.Logger( packageName )
local hook_Run = hook.Run

--[[-------------------------------------------------------------------------
	Team System Extensions
---------------------------------------------------------------------------]]

local TEAM_SPECTATOR = TEAM_SPECTATOR
local TEAM_UNASSIGNED = TEAM_UNASSIGNED

do

    local team_SetUp = environment.saveFunc( "team.SetUp", team.SetUp )
    function team.SetUp( ... )
        if hook_Run( "PreTeamCreating", ... ) then
            return
        end

        team_SetUp( ... )

        hook_Run( "OnTeamCreated", ... )
    end

end

--[[-------------------------------------------------------------------------
	Console Debug Log
---------------------------------------------------------------------------]]
hook.Add("OnTeamCreated", packageName, function( index, name, color )
    logger:debug( "Team #{1} created - {2}", index, name )
end)

--[[-------------------------------------------------------------------------
	Player Extensions
---------------------------------------------------------------------------]]

local PLAYER = FindMetaTable( "Player" )

function PLAYER:IsConnecting()
	return self:Team() == TEAM_CONNECTING
end

if SERVER then

    local RealTime = RealTime
    local team_Joinable = team.Joinable

    function PLAYER:JoinInTeam( teamid )
        if not GAMEMODE.TeamBased then
            GAMEMODE.TeamBased = true
        end

        if (self:Team() == teamid) then
            self:ChatPrint( "You're already on that team" )
            return false
        end

        if not team_Joinable( teamid ) then
            self:ChatPrint( "You can't join that team" )
            return false
        end

        local oldTeamid = self:Team()
        if (hook_Run( "PlayerChangedTeam", self, oldTeamid, teamid ) == true) then
            return false
        end

        self:SetTeam( teamid )
        self.LastTeamSwitch = RealTime()

        return true
    end

end

--[[-------------------------------------------------------------------------
	Entity Extensions
---------------------------------------------------------------------------]]

local ENTITY = FindMetaTable("Entity")

if SERVER then

    local team_Valid = team.Valid
	function ENTITY:SetTeam( teamID )
		self:SetNWInt( "__team", team_Valid( teamID ) and teamID or TEAM_UNASSIGNED )
	end

end

function ENTITY:Team()
	return self:GetNWInt( "__team", TEAM_UNASSIGNED )
end

--[[-------------------------------------------------------------------------
	Global Extensions
---------------------------------------------------------------------------]]

function PLAYER:IsSpectator()
	local team_id = self:Team()
	return team_id == TEAM_CONNECTING or team_id == TEAM_SPECTATOR
end

function ENTITY:IsUnassigned()
	return self:Team() == TEAM_UNASSIGNED
end

do

    local team_GetColor = team.GetColor
    function ENTITY:TeamColor()
        return team_GetColor( self:Team() )
    end

end
