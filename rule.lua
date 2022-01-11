local material = import("$.Material") -- 건들면 안됨!

local useChangeMethod = true -- 체인지 기능 사용 여부
local useAssassin = true -- 어쌔신 사용 여부

local godModeTick = 1200 -- 무적 시간 (틱)
local lockTick = 1200 -- 무적 시간 (틱)
local raffleTick = 12000 -- 무적 시간 (틱)

local startItem = {  -- 시작 시 지급 아이템
	newInstance("$.inventory.ItemStack", {material.COMPASS, 1})
}

function Init()
	math.randomseed(os.time()) -- 건들면 안됨!
	
	plugin.getPlugin().gameManager:setVariable("gameCount", 0)
	plugin.getPlugin().gameManager:setVariable("isGodMode", false)
	plugin.getPlugin().gameManager:setVariable("isLockMode", false)
	
	plugin.skipInformationOption(true) -- 모든 게임 시작과정을 생략하고 게임을 시작할 지 정합니다.
	plugin.raffleAbilityOption(false) -- 시작 시 능력을 추첨할 지 결정합니다.
	plugin.skipYesOrNoOption(false) -- 플레이어에게 능력 재설정을 가능하게 할 것인지 정합니다.
	plugin.abilityAmountOption(1, false) -- 능력의 추첨 옵션입니다. 숫자로 능력의 추첨 개수를 정하고, true/false로 다른 플레이어와 능력이 중복될 수 있는지를 정합니다. 같은 플레이어에게는 중복된 능력이 적용되지 않습니다.
	plugin.abilityItemOption(false, material.IRON_INGOT) -- 능력 발동 아이템 옵션입니다. true/false로 모든 능력의 발동 아이템을 통일 할 것인지 정하고, Material을 통해 통일할 아이템을 설정합니다.
	plugin.abilityCheckOption(true) -- 능력 확인 옵션입니다. 플레이어가 자신의 능력을 확인할 수 있는 지 정합니다.
	plugin.cooldownMultiplyOption(1.0) -- 능력 쿨타임 옵션입니다. 해당 값만큼 쿨타임 값에 곱해져 적용됩니다. (예: 0.5일 경우 쿨타임이 기본 쿨타임의 50%, 2.0일 경우 쿨타임이 기본 쿨타임의 200%)

	plugin.registerRuleEvent("EntityDamageEvent", "godMode")
	plugin.registerRuleEvent("PlayerMoveEvent", "lockMode")
	plugin.registerRuleEvent("PlayerRespawnEvent", "giveItem")
	plugin.registerRuleEvent("PlayerDeathEvent", "eliminate")
	plugin.registerRuleEvent("EntityDeathEvent", "dragonKill")
end

function onEvent(funcID, event)
	if funcID == "eliminate" then eliminate(event) end -- ok
	if funcID == "godMode" and plugin.getPlugin().gameManager:getVariable("isGodMode") == true then cancelDamage(event) end -- ok
	if funcID == "lockMode" and plugin.getPlugin().gameManager:getVariable("isLockMode") == true then cancelMove(event) end -- ok
	if funcID == "giveItem" then giveItem(event:getPlayer(), false) end -- ok
	if funcID == "dragonKill" then dragonKill(event) end -- ok
end

function onTimer()
	local count = plugin.getPlugin().gameManager:getVariable("gameCount")
	if count == nil then
		plugin.getPlugin().gameManager:setVariable("useChangeMethod", useChangeMethod)
		plugin.getPlugin().gameManager:setVariable("gameCount", 0)
		plugin.getPlugin().gameManager:setVariable("isGodMode", false)
		plugin.getPlugin().gameManager:setVariable("isLockMode", false)
		count = 0
	end
	
	if count == 0 then
		game.broadcastMessage("§2[§aLAbility§2] §a게임이 시작되었습니다.")
		teleport()
		setGodMode(true)
		heal()
		changeGamemode()
		giveItemToAll(true)
	end

	checkDirection()
	
	if count == raffleTick then setRunner() setLockMode(true) end
	if count == godModeTick then setGodMode(false) end
	if count == raffleTick + lockTick then setLockMode(false) end
	count = count + 2
	plugin.getPlugin().gameManager:setVariable("gameCount", count)
end

function Reset()
	changeGamemode()
	runnerKey = newInstance("$.NamespacedKey", {plugin.getPlugin(), "runnerBossBar" })
	if plugin.getServer():getBossBar(runnerKey) ~= nil then
		plugin.getServer():getBossBar(runnerKey):setVisible(false)
		plugin.getServer():removeBossBar(runnerKey)
	end
end

function giveItemToAll(clearInv)
	local players = util.getTableFromList(game.getPlayers())
	for i = 1, #players do
		giveItem(players[i]:getPlayer(), clearInv)
	end
end

function giveItem(player, clearInv)
	if game.getPlayer(player).isSurvive then 
		game.sendMessage(player, "§2[§aLAbility§2] §a기본 아이템을 지급받습니다.")
		if clearInv then player:getInventory():clear() end
		player:getInventory():addItem(startItem)
	end
end

function cancelDamage(event)
	if event:getEntity():getType():toString() == "PLAYER" then
		event:setCancelled(true)
	end
end

function cancelMove(event)
	if not game.hasAbility(game.getPlayer(event:getPlayer()), "LA-MH-RUNNER") then
		event:setCancelled(true)
	end
end

function eliminate(event)
	if event:getEntity():getType():toString() == "PLAYER" then
		if game.hasAbility(game.getPlayer(event:getEntity()), "LA-MH-RUNNER") then
			event:getEntity():getWorld():strikeLightningEffect(event:getEntity():getLocation())
			game.eliminatePlayer(game.getPlayer(event:getEntity()))
			
			local players = util.getTableFromList(game.getPlayers())
			if useChangeMethod then
				if #players >= 2 then
					local targetIndex = math.random(1, #players)
					while game.hasAbility(players[targetIndex], "LA-MH-RUNNER") do targetIndex = math.random(1, #players) end
					
					util.runLater(function() game.addAbility(players[targetIndex], "LA-MH-RUNNER") end, 1)
					if game.hasAbility(players[targetIndex], "LA-MH-ASSASSIN") then
						util.runLater(function() game.removeAbilityAsID(players[targetIndex], "LA-MH-ASSASSIN") end, 1)
						game.broadcastMessage("§2[§aLAbility§2] §a어쌔신이 러너가 되었습니다!")
						game.broadcastMessage("§2[§aLAbility§2] §a어쌔신을 재추첨합니다.")
					
						local newTargetIndex = math.random(1, #players)
						while #util.getTableFromList(players[newTargetIndex]:getAbility()) > 0 do newTargetIndex = math.random(1, #players) end
					
						util.runLater(function() game.addAbility(players[newTargetIndex], "LA-MH-ASSASSIN") end, 1)
					end
				else 
					game.broadcastMessage("§6[§eLAbility§6] §e게임이 종료되었습니다.")
					game.broadcastMessage("§6[§eLAbility§6] §b" .. players[1]:getPlayer():getName() .. " §e님이 우승했습니다!")
					game.endGame()
				end
			else 
				game.broadcastMessage("§6[§eLAbility§6] §e게임이 종료되었습니다.")
				game.broadcastMessage("§6[§eLAbility§6] §c헌터§e 팀이 우승했습니다!")
				game.endGame()
			end
		end
	end
end

function dragonKill(event)
	if event:getEntity():getType():toString() == "ENDER_DRAGON" then
		local players = util.getTableFromList(game.getPlayers())
		for i = 1, #players do
			if not game.hasAbility(players[i], "LA-MH-RUNNER") then 
				players[i]:getPlayer():setHealth(0)
				players[i]:getPlayer():getWorld():strikeLightningEffect(players[i]:getPlayer():getLocation())
			else 
				game.broadcastMessage("§6[§eLAbility§6] §e엔더 드래곤이 격파되어 게임이 종료되었습니다.")
				game.broadcastMessage("§6[§eLAbility§6] §b" .. players[i]:getPlayer():getName() .. " §e님이 우승했습니다!")
			end
		end
		game.endGame()
	end
end

function setGodMode(enable)
	if enable then
		plugin.getPlugin().gameManager:setVariable("isGodMode", true)
		game.broadcastMessage("§6[§eLAbility§6] §e게임 시작 후 ".. (godModeTick / 20.0) .. "초 간 무적으로 진행됩니다.")
	else
		plugin.getPlugin().gameManager:setVariable("isGodMode", false)
		game.broadcastMessage("§4[§cLAbility§4] §c무적시간이 종료되었습니다. 이제 데미지를 입습니다.")
	end	
end

function setLockMode(enable)
	if enable then
		plugin.getPlugin().gameManager:setVariable("isLockMode", true)
		game.broadcastMessage("§6[§eLAbility§6] §c추첨 후 ".. (lockTick / 20.0) .. "초 간 러너를 제외한 플레이어는 움직일 수 없습니다.")
	else
		plugin.getPlugin().gameManager:setVariable("isLockMode", false)
		game.broadcastMessage("§4[§cLAbility§4] §c러너 도주 시간이 종료되었습니다.")
	end	
end

function setRunner()
	local players = util.getTableFromList(game.getPlayers())
	game.broadcastMessage("§2[§aLAbility§2] §a역할을 추첨합니다.")
	
	for i = 1, 100 do
		local randomIndex = math.random(1, #players)
		local temp = players[randomIndex]
		players[randomIndex] = players[1]
		players[1] = temp
	end
	
	local count = 1
	
	util.runLater(function() game.addAbility(players[1], "LA-MH-RUNNER") end, 1)
	if useAssassin then util.runLater(function() game.addAbility(players[2], "LA-MH-ASSASSIN") end, 1) end
end

function changeGamemode()
	local players = util.getTableFromList(game.getAllPlayers())
	for i = 1, #players do
		players[i]:getPlayer():setGameMode(import("$.GameMode").SURVIVAL)
	end
end

function heal()
	local players = util.getTableFromList(game.getAllPlayers())
	for i = 1, #players do
		players[i]:getPlayer():setHealth(players[i]:getPlayer():getAttribute(import("$.attribute.Attribute").GENERIC_MAX_HEALTH):getBaseValue())
		players[i]:getPlayer():setFoodLevel(20)
	end
end

function checkDirection()
	local players = util.getTableFromList(game.getPlayers())
	local runnerList = {}
	local hunterList = {}
	
	for i = 1, #players do
		if game.hasAbility(players[i], "LA-MH-RUNNER") then table.insert(runnerList, players[i])
		else table.insert(hunterList, players[i]) end
	end

	for i = 1, #players do
		local compassIndex = players[i]:getPlayer():getInventory():first(material.COMPASS)
		if compassIndex >= 0 then
			local distance = 99999999
			local targetIndex = 0
			
			if game.hasAbility(players[i], "LA-MH-RUNNER") then
				for j = 1, #hunterList do 
					if players[i]:getPlayer():getWorld():getEnvironment() == hunterList[j]:getPlayer():getWorld():getEnvironment() then
						local checkDistance = players[i]:getPlayer():getLocation():distance(hunterList[j]:getPlayer():getLocation())
						if checkDistance < distance then
							distance = checkDistance
							targetIndex = j
						end
					end
				end
				
				local compass = players[i]:getPlayer():getInventory():getItem(compassIndex)
				local compassMeta = compass:getItemMeta()
				if targetIndex > 0 then
					compassMeta:setLodestone(hunterList[targetIndex]:getPlayer():getLocation())
					compassMeta:setLodestoneTracked(players[i]:getPlayer():getWorld():getEnvironment():toString() == "NETHER")
					players[i]:getPlayer():setCompassTarget(hunterList[targetIndex]:getPlayer():getLocation()) 
				end
				
				if not compassMeta:hasEnchant(import("$.enchantments.Enchantment").VANISHING_CURSE) then compassMeta:addEnchant(import("$.enchantments.Enchantment").VANISHING_CURSE, 1, true) end
				compassMeta:setDisplayName("§6Hunter Tracker")
				compass:setItemMeta(compassMeta)
			else 
				for j = 1, #runnerList do 
					if players[i]:getPlayer():getWorld():getEnvironment() == runnerList[j]:getPlayer():getWorld():getEnvironment() then
						local checkDistance = players[i]:getPlayer():getLocation():distance(runnerList[j]:getPlayer():getLocation())
						if checkDistance < distance then
							distance = checkDistance
							targetIndex = j
						end
					end
				end
				
				local compass = players[i]:getPlayer():getInventory():getItem(compassIndex)
				local compassMeta = compass:getItemMeta()
				if targetIndex > 0 then
					compassMeta:setLodestone(runnerList[targetIndex]:getPlayer():getLocation())
					compassMeta:setLodestoneTracked(players[i]:getPlayer():getWorld():getEnvironment():toString() == "NETHER")
					players[i]:getPlayer():setCompassTarget(runnerList[targetIndex]:getPlayer():getLocation()) 
				end
				
				if not compassMeta:hasEnchant(import("$.enchantments.Enchantment").VANISHING_CURSE) then compassMeta:addEnchant(import("$.enchantments.Enchantment").VANISHING_CURSE, 1, true) end
				compassMeta:setDisplayName("§6Runner Tracker")
				compass:setItemMeta(compassMeta)
			end
		end
	end
end

function teleport()
	local players = util.getTableFromList(game.getPlayers())
	local locs = { }
	
	for i = 1, #players do
		local villageLocation = players[1]:getPlayer():getWorld():locateNearestStructure(newInstance("$.Location", {players[1]:getPlayer():getWorld(), 0, 80, 0}), import("$.StructureType").VILLAGE, 10000, true)
		local block = players[1]:getPlayer():getWorld():getBlockAt(villageLocation)
		
		while not checkBiome(block:getBiome()) and not containsLoc(locs, villageLocation) do
			villageLocation = players[1]:getPlayer():getWorld():locateNearestStructure(newInstance("$.Location", {players[1]:getPlayer():getWorld(), 0, 80, 0}), import("$.StructureType").VILLAGE, 10000, true)
			block = players[1]:getPlayer():getWorld():getBlockAt(villageLocation)
		end
		
		table.insert(locs, villageLocation)
		villageLocation:setY(villageLocation:getWorld():getHighestBlockYAt(villageLocation:getX(), villageLocation:getZ()) + 2)
		players[i]:getPlayer():teleport(villageLocation)
		players[i]:getPlayer():setBedSpawnLocation(villageLocation, true)
	end
end

function checkBiome(targetBiome)
	local biome = import("$.block.Biome")
	if string.find(targetBiome:toString(), "MEADOW") then return true end
	if string.find(targetBiome:toString(), "PLAINS") then return true end
	if string.find(targetBiome:toString(), "SAVANNA") then return true end
	if string.find(targetBiome:toString(), "TAIGA") then return true end
	if string.find(targetBiome:toString(), "MEADOW") then return true end
	return false
end

function containsLoc(tables, Loc)
	for i = 1, #tables do
		if tables[i] == Loc then return true end
	end
	return false
end