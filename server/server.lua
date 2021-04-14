ESX = nil

local CopsConnected = 0

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)


function CountCops()

	local xPlayers = ESX.GetPlayers()

	CopsConnected = 0

	for i=1, #xPlayers, 1 do
		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
		if xPlayer.job.name == 'polis' then
			CopsConnected = CopsConnected + 1
		end
	end

	SetTimeout(120 * 1000, CountCops)
end

CountCops()


ESX.RegisterServerCallback("yatzzz_shoprobbery:time", function(source, cb, currentStore)
	local xPlayer  = ESX.GetPlayerFromId(source)

	if safes[currentStore] then
		local store = safes[currentStore]

        if (os.time() - store.lastrobbed) < Config.TimerBeforeNewRob and store.lastrobbed ~= 0 then
            TriggerClientEvent('mythic_notify:client:SendAlert', source, { type = 'error', text = 'Bu market zaten yakın zamanda soyuldu. Tekrar soyabilmek için '..(Config.TimerBeforeNewRob - (os.time() - store.lastrobbed)).. " saniye beklemelisin."})
            cb(false)
			return
        end
        
        if not rob then
            cb(true)
            rob = true
            safes[currentStore].lastrobbed = os.time()
        else
            TriggerClientEvent('mythic_notify:client:SendAlert', source, { type = 'error', text = "Bu market şuan zaten soyuluyor."})
            cb(false)
            return
        end
    end
end)

RegisterServerEvent("yatzzz_shoprobbery:setRobbableFALSE")
AddEventHandler("yatzzz_shoprobbery:setRobbableFALSE", function()
    rob = false
end)

RegisterServerEvent("yatzzz_shoprobbery:giveMoney")
AddEventHandler("yatzzz_shoprobbery:giveMoney", function(money)
    local xPlayer = ESX.GetPlayerFromId(source)

    xPlayer.addInventoryItem('cash', money)
end)

ESX.RegisterServerCallback('yatzzz_shoprobbery:getCops', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    cb(CopsConnected)
end)
    