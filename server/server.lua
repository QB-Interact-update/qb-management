local uhohs = {}
local backwardsCompatibility = {}

local function uhOh(identifier, reason)
    uhohs[identifier] = (uhohs[identifier] or 0) + 1
    if uhohs[identifier] > 3 then
        DropPlayer(identifier, reason)
    end
    print(Lang:t('UhOh.reason', { identifier = identifier, reason = reason, count = uhohs[identifier] }))
end

local function sort(tbl, key)
    table.sort(tbl, function(a, b)
        return a[key] < b[key]
    end)
    return tbl
end

local function checkDistance(src, loc, dist)
    if backwardsCompatibility[src] then
        print("^1 WARNING: qb-management used the backwards compatibility ^0")
        return true
    end
    local pcoords = GetEntityCoords(GetPlayerPed(src))
    local distance = #(pcoords - vector3(loc.x, loc.y, loc.z))
    if distance <= dist then
        return true
    end
    uhOh(src, 'Distance Check Failed')
    return false
end

local function getNearbyPlayers(src, dist, type, organization)
    local players = {}
    local pcoords = GetEntityCoords(GetPlayerPed(src))
    for _, playerId in pairs(exports['qb-core']:GetPlayers()) do
        local otherPcoords = GetEntityCoords(GetPlayerPed(playerId))
        local distance = #(pcoords - otherPcoords)
        if distance <= dist then
            local player = exports['qb-core']:GetPlayer(playerId)
            if type == 'job' then
                if not exports['qb-multijob']:hasJob(player.PlayerData.citizenid, organization) then
                    players[#players + 1] = {
                        name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
                        citizenid = player.PlayerData.citizenid,
                    }
                end
            end
            if type == 'gang' then
                if player.PlayerData.gang.name ~= organization then
                    players[#players + 1] = {
                        name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
                        citizenid = player.PlayerData.citizenid,
                    }
                end
            end
        end
    end
    --players[#players+1] = {
    --    name = 'Tony Papapauly',
    --    citizenid = 'AFA36957'
    --}
    return players
end

local function verifyJobBoss(src, jobName)
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return false end

    local job = Player.PlayerData.job
    if job.name ~= jobName or not job.isboss then
        uhOh(src, 'Job Boss Check Failed')
        return false
    end

    return true
end

local function verifyGangBoss(src, gangName)
    local Player = exports['qb-core']:GetPlayer(src)
    if not Player then return false end

    local gang = Player.PlayerData.gang
    if gang.name ~= gangName or not gang.isboss then
        uhOh(src, 'Gang Boss Check Failed')
        return false
    end

    return true
end

exports['qb-core']:CreateCallback('qb-management:server:openBossMenu', function(source, cb, sentData)
    local src = source
    if sentData.type == 'job' then
        if not checkDistance(src, Config.BossMenus['Jobs'][sentData.name][sentData.index], 3.0) then return end
        if not verifyJobBoss(src, sentData.name) then return end

        local employees = exports['qb-multijob']:getEmployees(sentData.name)
        sort(employees, 'name')
        cb({employees = employees, job = Jobs[sentData.name], nearby = getNearbyPlayers(src, 25.0, 'job', sentData.name), success = true })
        return
    end
    if sentData.type == 'gang' then
        if not checkDistance(src, Config.BossMenus['Gangs'][sentData.name][sentData.index], 3.0) then return end
        if not verifyGangBoss(src, sentData.name) then return end

        local gangMembers = MySQL.query.await('SELECT * FROM players WHERE JSON_EXTRACT(gang, "$.name") = ?', { sentData.name })
        local members = {}
        for index, data in pairs (gangMembers) do
            local charinfo, gang = json.decode(data.charinfo), json.decode(data.gang)
            local member = exports['qb-core']:GetPlayerByCitizenId(data.citizenid) or exports['qb-core']:GetOfflinePlayerByCitizenId(data.citizenid)
            members[#members + 1] = {
                name = charinfo.firstname .. ' ' .. charinfo.lastname,
                citizenid = data.citizenid,
                online = member.PlayerData.source and true or false,
                jobData = {
                    label = gang.label,
                    grade = gang.grade.level,
                    gradeLabel = gang.grade.name,
                    name = gang.name,
                }
            }
        end
        sort(members, 'name')
        cb({employees = members, job = Gangs[sentData.name], nearby = getNearbyPlayers(src, 25.0, 'gang', sentData.name), success = true })
    end
end)

exports['qb-core']:CreateCallback('qb-management:server:updateEmployeeGrade', function(source, cb, heldData, employeeData)
    local src = source
    if heldData.type == 'job' then
        if not checkDistance(src, Config.BossMenus['Jobs'][heldData.name][heldData.index], 3.0) then return end
        if not verifyJobBoss(src, heldData.name) then return end
        print(heldData.name, employeeData.citizenid, employeeData.grade)
        local employeeHasJob = exports['qb-multijob']:hasJob(employeeData.citizenid, heldData.name)
        if not employeeHasJob then
            TriggerClientEvent('QBCore:Notify', src, Lang:t("Notify.doesnt_have_job"), 'error')
            return
        end
        local success, message, type = exports['qb-multijob']:updateRank(employeeData.citizenid, heldData.name, employeeData.grade)
        TriggerClientEvent('QBCore:Notify', src, message, type)
        return
    end
    if heldData.type == 'gang' then
        if not checkDistance(src, Config.BossMenus['Gangs'][heldData.name][heldData.index], 3.0) then return end
        if not verifyGangBoss(src, heldData.name) then return end

        local member = exports['qb-core']:GetPlayerByCitizenId(employeeData.citizenid) or exports['qb-core']:GetOfflinePlayerByCitizenId(employeeData.citizenid)
        if not member.PlayerData.gang or member.PlayerData.gang.name ~= heldData.name then
            TriggerClientEvent('QBCore:Notify', src, Lang:t("Notify.doesnt_have_gang"), 'error')
            return
        end

        member.Functions.SetGang(heldData.name, employeeData.grade)
        member.Functions.Save()
        TriggerClientEvent('QBCore:Notify', src, Lang:t("Notify.rank_updated"), 'success')
        return
    end
end)

exports['qb-core']:CreateCallback('qb-management:server:fireEmployee', function(source, cb, heldData, citizenid)
    local src = source

    if heldData.type == 'job' then
        if not checkDistance(src, Config.BossMenus['Jobs'][heldData.name][heldData.index], 3.0) then return end
        if not verifyJobBoss(src, heldData.name) then return end

        local employeeHasJob = exports['qb-multijob']:hasJob(citizenid, heldData.name)
        if not employeeHasJob then
            TriggerClientEvent('QBCore:Notify', src, Lang:t("Notify.doesnt_have_job"), 'error')
            return
        end

        local success, message, type = exports['qb-multijob']:removeJob(citizenid, heldData.name)
        TriggerClientEvent('QBCore:Notify', src, message, type)
        return
    end
    if heldData.type == 'gang' then
        if not checkDistance(src, Config.BossMenus['Gangs'][heldData.name][heldData.index], 3.0) then return end
        if not verifyGangBoss(src, heldData.name) then return end

        local member = exports['qb-core']:GetPlayerByCitizenId(citizenid) or exports['qb-core']:GetOfflinePlayerByCitizenId(citizenid)
        if not member.PlayerData.gang or member.PlayerData.gang.name ~= heldData.name then
            TriggerClientEvent('QBCore:Notify', src, Lang:t("Notify.doesnt_have_gang"), 'error')
            return
        end
        member.Functions.SetGang('none', 0)
        member.Functions.Save()
        TriggerClientEvent('QBCore:Notify', src, Lang:t("Notify.removed_from_gang"), 'success')
        return
    end
end)

exports['qb-core']:CreateCallback('qb-management:server:hireEmployee', function(source, cb, heldData, citizenid)
    local src = source
    if heldData.type == 'job' then
        if not checkDistance(src, Config.BossMenus['Jobs'][heldData.name][heldData.index], 3.0) then return end
        if not verifyJobBoss(src, heldData.name) then return end

        local employeeHasJob = exports['qb-multijob']:hasJob(citizenid, heldData.name)
        if employeeHasJob then
            TriggerClientEvent('QBCore:Notify', src, Lang:t("Notify.has_job_already"), 'error')
            return
        end
        local success, message, type = exports['qb-multijob']:addJob(citizenid, heldData.name, 0)
        TriggerClientEvent('QBCore:Notify', src, message, type)
        return
    end
    if heldData.type == 'gang' then
        if not checkDistance(src, Config.BossMenus['Gangs'][heldData.name][heldData.index], 3.0) then return end
        if not verifyGangBoss(src, heldData.name) then return end

        local member = exports['qb-core']:GetPlayerByCitizenId(citizenid) or exports['qb-core']:GetOfflinePlayerByCitizenId(citizenid)
        if member.PlayerData.gang and member.PlayerData.gang.name == heldData.name then
            TriggerClientEvent('QBCore:Notify', src, Lang:t("Notify.has_gang_already"), 'error')
            return
        end

        member.Functions.SetGang(heldData.name, 0)
        member.Functions.Save()
        TriggerClientEvent('QBCore:Notify', src, Lang:t("Notify.added_to_gang"), 'success')
        return
    end
end)
RegisterNetEvent('qb-management:server:openStorage', function(sentData)
    local src = source
    if sentData.type == 'job' then
        if not checkDistance(src, Config.BossMenus['Jobs'][sentData.name][sentData.index], 3.0) then return end
        if not verifyJobBoss(src, sentData.name) then return end

        local data = {
            label = Jobs[sentData.name].label .. Lang:t('Stash'),
            maxweight = 4000000,
			slots = 25,
        }
        exports['qb-inventory']:OpenInventory(src, 'boss_' .. sentData.name, data)
    end
    if sentData.type == 'gang' then
        if not checkDistance(src, Config.BossMenus['Gangs'][sentData.name][sentData.index], 3.0) then return end
        if not verifyGangBoss(src, sentData.name) then return end

        local data = {
            label = Gangs[sentData.name].label .. Lang:t('Stash'),
            maxweight = 4000000,
            slots = 25,
        }
        exports['qb-inventory']:OpenInventory(src, 'boss_' .. sentData.name, data)
    end
end)

local function printWarning()
    if not Config.Warn then return end
    print("^1 WARNING: qb-management used the backwards compatibility")
    print("^1 This Method Does Not Do A Distance Check")
    print("^1 And Comment Out The Boss Menu Trigger From The Script You Are Using To Open The Menu")
    print("^1 Please Update The Coords To qb-management/shared/Config.lua To Include The Distance Check")
    print("^1 This Method Is Not As Secure, And Only Left In To Not Force Devs To Immediately Update Their Scripts ^0")
    print("^1 ------------------------------------------------------------------------------------------------------- ^0")
end

exports['qb-core']:CreateCallback('qb-management:server:OpenMenu', function(source, cb)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    printWarning()
    if Player.PlayerData.job.isboss then
        local employees = exports['qb-multijob']:getEmployees(Player.PlayerData.job.name)
        sort(employees, 'name')
        local language = {
            employees = employees,
            job = Jobs[Player.PlayerData.job.name],
            nearby = getNearbyPlayers(src, 25.0, 'job', Player.PlayerData.job.name),
        }
        cb(language)
        backwardsCompatibility[src] = true
        return
    end
    cb(false)
end)

exports['qb-core']:CreateCallback('qb-management:server:OpenMenuGang', function(source, cb)
    local src = source
    local Player = exports['qb-core']:GetPlayer(src)
    printWarning()
    if Player.PlayerData.gang.isboss then
        local gangMembers = MySQL.query.await('SELECT * FROM players WHERE JSON_EXTRACT(gang, "$.name") = ?', { Player.PlayerData.gang.name })
        local members = {}
        for index, data in pairs (gangMembers) do
            local charinfo, gang = json.decode(data.charinfo), json.decode(data.gang)
            local member = exports['qb-core']:GetPlayerByCitizenId(data.citizenid) or exports['qb-core']:GetOfflinePlayerByCitizenId(data.citizenid)
            members[#members + 1] = {
                name = charinfo.firstname .. ' ' .. charinfo.lastname,
                citizenid = data.citizenid,
                online = member.PlayerData.source and true or false,
                jobData = {
                    label = gang.label,
                    grade = gang.grade.level,
                    gradeLabel = gang.grade.name,
                    name = gang.name,
                }
            }
        end
        sort(members, 'name')
        local gangData = {
            employees = members,
            job = Gangs[Player.PlayerData.gang.name],
            nearby = getNearbyPlayers(src, 25.0, 'gang', Player.PlayerData.gang.name),
        }
        cb(gangData)
        backwardsCompatibility[src] = true
        return
    end
    cb(false)
end)

RegisterNetEvent('qb-management:server:AllowAccess', function()
    local src = source
    if backwardsCompatibility[src] then
        backwardsCompatibility[src] = nil
    end
    print("^2 qb-management:server:AllowAccess - Removed Backwards Compatibility for source: " .. src .. "^0")
end)