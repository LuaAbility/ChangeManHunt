local cooldown = 19200

function Init(abilityData) end

function onTimer(player, ability)
	if player:getVariable("MHRUNNER-passiveCount") == nil then 
		player:setVariable("MHRUNNER-passiveCount", 0) 
		initBossbar(player)
		game.broadcastMessage("§2[§aLAbility§2] " .. player:getPlayer():getName() .. "§a님이 러너가 되었습니다!")
	end
	local count = player:getVariable("MHRUNNER-passiveCount")
	if count % 20 == 0 then showMessage(player, count) end
	if count >= cooldown then count = 0 shuffle(player) end
	count = count + 2
	player:setVariable("MHRUNNER-passiveCount", count)
end

function showMessage(player, count)
	local remainCount = cooldown - count
	local players = util.getTableFromList(game.getPlayers())
	if plugin.getPlugin().gameManager:getVariable("useChangeMethod") == true then
		for i = 1, #players do
			if game.hasAbility(players[i], "LA-MH-RUNNER") then game.sendActionBarMessage(players[i]:getPlayer(), "§6[Runner] " .. "§2남은 시간 : ".. remainCount / 20 .. "초")
			elseif game.hasAbility(players[i], "LA-MH-ASSASSIN") then game.sendActionBarMessage(players[i]:getPlayer(), "§4[Assassin] " .. "§2남은 시간 : ".. remainCount / 20 .. "초" )
			else game.sendActionBarMessage(players[i]:getPlayer(), "§c[Hunter] " .. "§2남은 시간 : ".. remainCount / 20 .. "초" ) end
		end
		runnerKey = newInstance("$.NamespacedKey", {plugin.getPlugin(), "runnerBossBar" })
		plugin.getServer():getBossBar(runnerKey):setTitle("§6러너 : §a" .. player:getPlayer():getName())
		plugin.getServer():getBossBar(runnerKey):setProgress(remainCount / cooldown)
	else
		for i = 1, #players do
			if game.hasAbility(players[i], "LA-MH-RUNNER") then game.sendActionBarMessage(players[i]:getPlayer(), "§6[Runner]" )
			elseif game.hasAbility(players[i], "LA-MH-ASSASSIN") then game.sendActionBarMessage(players[i]:getPlayer(), "§4[Assassin]" )
			else game.sendActionBarMessage(players[i]:getPlayer(), "§c[Hunter]" ) end
		end
	end
end

function shuffle(player)
	if plugin.getPlugin().gameManager:getVariable("useChangeMethod") == true then 
		math.randomseed(os.time())
		local players = util.getTableFromList(game.getPlayers())
		local targetIndex = math.random(1, #players)
		while game.hasAbility(players[targetIndex], "LA-MH-RUNNER") do targetIndex = math.random(1, #players) end
		
		util.runLater(function() 
			game.removeAbilityAsID(player, "LA-MH-RUNNER") 
			game.addAbility(players[targetIndex], "LA-MH-RUNNER")
		end, 1)
		
		if game.hasAbility(players[targetIndex], "LA-MH-ASSASSIN") then
			util.runLater(function() game.removeAbilityAsID(players[targetIndex], "LA-MH-ASSASSIN") end, 1)
			game.broadcastMessage("§2[§aLAbility§2] §a어쌔신이 러너가 되었습니다!")
			game.broadcastMessage("§2[§aLAbility§2] §a어쌔신을 재추첨합니다.")
		
			local newTargetIndex = math.random(1, #players)
			while #util.getTableFromList(players[newTargetIndex]:getAbility()) > 0 do newTargetIndex = math.random(1, #players) end
		
			util.runLater(function() game.addAbility(players[newTargetIndex], "LA-MH-ASSASSIN") end, 1)
		end
	end
end

function initBossbar(player)
	local players = util.getTableFromList(game.getPlayers())
	local runnerKey = newInstance("$.NamespacedKey", {plugin.getPlugin(), "runnerBossBar" })
	local runnerBossbar = plugin.getServer():getBossBar(runnerKey)
	if runnerBossbar == nil then runnerBossbar = plugin.getServer():createBossBar(runnerKey, "§6러너 : §a" .. player:getPlayer():getName(), import("$.boss.BarColor").BLUE, import("$.boss.BarStyle").SEGMENTED_20, { } ) end
	for i = 1, #players do
		runnerBossbar:addPlayer(players[i]:getPlayer())
	end
end