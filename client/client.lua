
local holdData = {}

local function openUi()
    local confirmation = exports['qb-core']:TriggerCallback('qb-management:server:openBossMenu', holdData)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openBossMenu',
        data = {
            employees = confirmation.employees,
            job = confirmation.job,
            nearby = confirmation.nearby,
        }
    })
end

local function initZones()
    for jobName, v in pairs (Config.BossMenus.Jobs) do
        for index, pos in pairs (v) do
            local options = {
                {
                    label = Lang:t('Targets.open_management', {job = Jobs[jobName].label}),
                    icon = Lang:t('Targets.open_management_icon'),
                    action = function()
                        holdData = {
                            index = index,
                            name = jobName,
                            type = 'job'
                        }
                        openUi()
                    end,
                    canInteract = function()
                        local playerJob = exports['qb-core']:GetPlayerData().job
                        if playerJob and playerJob.name == jobName and playerJob.isboss then
                            return true
                        end
                        return false
                    end
                }
            }
            if Config.UseTarget then 
                exports['qb-target']:AddBoxZone("bossmenu_"..jobName..index, pos, 1.5, 1.5, {
                    name = "bossmenu_"..jobName..index,
                    heading = 0,
                    debugPoly = false,
                    minZ = pos.z - 1,
                    maxZ = pos.z + 1,
                }, {
                    options = options,
                    distance = 2.5
                })
            else
                exports['qb-interact']:addInteractZone({
                    name = "bossmenu_"..jobName..index,
                    coords = pos,
                    width = 2.0,
                    length = 2.0,
                    options = options,
                    height = 2,
                    debugPoly = false,
                })
            end
        end
    end
    for gangName, v in pairs (Config.BossMenus.Gangs) do
        for index, pos in pairs (v) do
            local options = {
                {
                    label = Lang:t('Targets.open_management', {job = Gangs[gangName].label}),
                    icon = Lang:t('Targets.open_management_icon'),
                    action = function()
                        holdData = {
                            index = index,
                            name = gangName,
                            type = 'gang'
                        }
                        openUi()
                    end,
                    canInteract = function()
                        local playerGang = exports['qb-core']:GetPlayerData().gang
                        if playerGang and playerGang.name == gangName and playerGang.isboss then
                            return true
                        end
                        return false
                    end
                }
            }
            if Config.UseTarget then 
                exports['qb-target']:AddBoxZone("bossmenu_"..gangName..index, pos, 1.5, 1.5, {
                    name = "bossmenu_"..gangName..index,
                    heading = 0,
                    debugPoly = false,
                    minZ = pos.z - 1,
                    maxZ = pos.z + 1,
                }, {
                    options = options,
                    distance = 2.5
                })
            else
                exports['qb-interact']:addInteractZone({
                    name = "bossmenu_"..gangName..index,
                    coords = pos,
                    width = 2.0,
                    length = 2.0,
                    options = options,
                    height = 2,
                    debugPoly = false,
                })
            end
        end
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    initZones()
    Wait(1000)
    SendNUIMessage({
        action = 'getLanguage',
        data = {
            language = Translations.UI
        }
    })
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    initZones()
    Wait(1000)
    SendNUIMessage({
        action = 'getLanguage',
        data = {
            language = Translations.UI
        }
    })
end)

RegisterNuiCallback('hideUI', function(data, cb)
    SetNuiFocus(false, false)
    holdData = {}
    cb('ok')
    TriggerServerEvent('qb-management:server:AllowAccess')
end)

RegisterNuiCallback('updateGrade', function(data, cb)
    exports['qb-core']:TriggerCallback('qb-management:server:updateEmployeeGrade', holdData, data)
    cb('ok')
end)

RegisterNuiCallback('fireEmployee', function(data, cb)
    exports['qb-core']:TriggerCallback('qb-management:server:fireEmployee', holdData, data.citizenid)
    cb('ok')
end)

RegisterNuiCallback('hireEmployee', function(data, cb)
    exports['qb-core']:TriggerCallback('qb-management:server:hireEmployee', holdData, data.citizenid)
    cb('ok')
end)

RegisterNuiCallback('openStorage', function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent('qb-management:server:openStorage', holdData)
    holdData = {}
    cb('ok')
end)

RegisterNuiCallback('openWardrobe', function(data, cb)
    SetNuiFocus(false, false)
    TriggerEvent('qb-clothing:client:openOutfitMenu')
    holdData = {}
    cb('ok')
end)

RegisterNetEvent('qb-bossmenu:client:OpenMenu', function()
    if not exports['qb-core']:GetPlayerData().job.isboss then
        exports['qb-core']:Notify(Lang:t('Notify.not_boss'), 'error')
        return
    end
    local confirmation = exports['qb-core']:TriggerCallback('qb-management:server:OpenMenu')
    if not confirmation then
        return
    end
    holdData = {
        index = 1,
        name = exports['qb-core']:GetPlayerData().job.name,
        type = 'job'
    }
    SendNUIMessage({
        action = 'openBossMenu',
        data = {
            employees = confirmation.employees,
            job = confirmation.job,
            nearby = confirmation.nearby,
        }
    })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('qb-gangmenu:client:OpenMenu', function()
    if not exports['qb-core']:GetPlayerData().gang.isboss then
        exports['qb-core']:Notify(Lang:t('Notify.not_boss'), 'error')
        return
    end
    local confirmation = exports['qb-core']:TriggerCallback('qb-management:server:OpenMenuGang')
    if not confirmation then
        return
    end
    holdData = {
        index = 1,
        name = exports['qb-core']:GetPlayerData().gang.name,
        type = 'gang'
    }
    SendNUIMessage({
        action = 'openBossMenu',
        data = {
            employees = confirmation.employees,
            job = confirmation.job,
            nearby = confirmation.nearby,
        }
    })
    SetNuiFocus(true, true)
end)

RegisterCommand('getData', function()
    print(json.encode(exports['qb-core']:GetPlayerData(), {indent=true}))
end)