local types = import("$.entity.EntityType")

function Init(abilityData)
	plugin.registerEvent(abilityData, "MHASSASSIN-cancelMove1", "PlayerMoveEvent", 0)
	plugin.registerEvent(abilityData, "MHASSASSIN-cancelMove2", "VehicleMoveEvent", 0)
	plugin.registerEvent(abilityData, "MHASSASSIN-cancelOrKill", "EntityDamageEvent", 0)
end

function onEvent(funcTable)
	if funcTable[1] == "MHASSASSIN-cancelMove1" then cancelMove1(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
	if funcTable[1] == "MHASSASSIN-cancelMove2" then cancelMove2(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
	if funcTable[1] == "MHASSASSIN-cancelOrKill" and funcTable[2]:getEventName() == "EntityDamageByEntityEvent" then cancelOrKill(funcTable[3], funcTable[2], funcTable[4], funcTable[1]) end
end

function onTimer(player, ability)
	if player:getVariable("MHASSASSIN-canMove") == nil then 
		player:setVariable("MHASSASSIN-canMove", true)
		game.broadcastMessage("§4[§cLAbility§4] " .. player:getPlayer():getName() .. "§c님이 어쌔신이 되었습니다!")
	end
	
	runnerCheck(player)
end

function runnerCheck(player)
	local players = util.getTableFromList(game.getPlayers())
	
	player:setVariable("MHASSASSIN-canMove", true)
	for i = 1, #players do
		if game.hasAbility(players[i], "LA-MH-RUNNER") and getLookingAt(players[i]:getPlayer(), player:getPlayer()) then player:setVariable("MHASSASSIN-canMove", false) end
	end
end

function cancelMove1(LAPlayer, event, ability, id)
	if game.checkCooldown(LAPlayer, game.getPlayer(event:getPlayer()), ability, id) then
		if game.getPlayer(event:getPlayer()):getVariable("MHASSASSIN-canMove") == false then
			event:setCancelled(true)
		end
	end
end

function cancelMove2(LAPlayer, event, ability, id)
	local passengers = util.getTableFromList(event:getVehicle():getPassengers())
	for i = 1, #passengers do
		if passengers[i]:getType():toString() == "PLAYER" then
			if game.checkCooldown(LAPlayer, game.getPlayer(passengers[i]), ability, id) then
				if game.getPlayer(passengers[i]):getVariable("MHASSASSIN-canMove") == false then
					event:getVehicle():removePassenger(passengers[i])
				end
			end
		end
	end
end

function cancelOrKill(LAPlayer, event, ability, id)
	if event:getDamager():getType():toString() == "PLAYER" and event:getEntity():getType():toString() == "PLAYER" then
		if game.checkCooldown(LAPlayer, game.getPlayer(event:getDamager()), ability, id) then
			if game.getPlayer(event:getDamager()):getVariable("MHASSASSIN-canMove") == false then
				event:setCancelled(true)
			elseif game.hasAbility(game.getPlayer(event:getEntity()), "LA-MH-RUNNER") then
				event:setDamage(9999999)
			end
		end
	end
end

function getLookingAt(player, player1)
	local eye = player:getEyeLocation()
	local toEntity = player1:getEyeLocation():toVector():subtract(eye:toVector())
	local dot = toEntity:normalize():dot(eye:getDirection())
	
	if player:getWorld():getEnvironment() ~= player1:getWorld():getEnvironment() then dot = 0
	elseif player:getPlayer():getLocation():distance(player1:getLocation()) > 40 then dot = 0 end

	if not player:hasLineOfSight(player1) then dot = 0 end
	
	return dot > 0.6
end