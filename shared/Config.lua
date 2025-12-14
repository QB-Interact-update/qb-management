Config = {}
Config.UseTarget = GetConvar('UseTarget', 'false') == 'true'
Jobs, Gangs = exports['qb-core']:GetSharedJobs(), exports['qb-core']:GetSharedGangs()

Config.Warn = true -- Warn in server console if a an old event is used without certain security checks

Config.BossMenus = {
    Jobs = {
        police = {
            vector3(447.16, -974.31, 30.47),
        },
         ambulance = {
            vector3(311.21, -599.36, 43.29),
        },
        cardealer = {
            vector3(-32.94, -1114.64, 26.42),
        },
        mechanic = {
            vector3(-347.59, -133.35, 39.01),
        }
    },
    Gangs = {
        lostmc = {
            vector3(0,0,0),
        },
        ballas = {
            vector3(0, 0, 0),
        },
        vagos = {
            vector3(0, 0, 0),
        },
        cartel = {
            vector3(0, 0, 0),
        },
        families = {
            vector3(0, 0, 0),
        },
    }
}