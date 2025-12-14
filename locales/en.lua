Translations = {
    UhOh = {
        reason = "Player %{identifier} Has Failed A Security Check: %{reason}, They have %{count} strikes.",
    },
    Notify = {
        not_boss = "You Are Not A Boss!",
        doesnt_have_job = "This Person Doesnt Have This Job",
        doesnt_have_gang = "This Person Doesnt Have This Gang",
        rank_updated = "Member Rank Updated Successfully", -- gang only, job uses existing message from qb-multijob
        removed_from_gang = "Member Removed From Gang Successfully",
        added_to_gang = "Member Added To Gang Successfully",
        has_job_already = "This Person Already Has This Job",
        has_gang_already = "This Person Already Belongs To This Gang",
    },
    Stash = ' Boss Stash', -- Note the space before 'Boss' for job/gang name concatenation automatically
    Targets = {
        open_management = "Open %{job} Management",
        open_management_icon = "fa-solid fa-briefcase"
    },
    UI = {
        currency = "$",
        header = " Management", -- Note the space before 'Management' for job/gang name concatenation automatically
        buttons = {
            recruit = "Recruit Player",
            stash = "Open Storage",
            wardrobe = "Open Wardrobe",
            fire = "Fire",
            cancel = "Cancel",
            confirm_fire = "Fire Member"
        },
        employeeCard = {
            rank = "Rank:",
            pay = "Pay:",
            highest = "Highest Rank",
            fire = "Fire",
        },
        no_employees = "No members found.",
        no_employees_desc = "Recruit Some People To Get Started!",
        hire_employee_panel = {
            title = "Recruit Player",
            description = "Select A Player To Recruit",
            hire = "Hire",
            no_players = "No Nearby People To Recruit."
        },
        fire_employee_panel = {
            title = "Confirm Termination",
            description = "Are You Sure You To Get Rid Of ", -- Note the space after 'Of' for name concatenation automatically
            cant_be_undone = "This Action Can't Be Undone!",
            confirm_fire = "Fire"
        },
        promotion_panel = {
            title = "Confirm Promotion",
            description = "Are You Sure You Want To Promote ",
            description2 = " to ",
            warning = "This Is The Highest Rank In The Organization And Grants Full Management Access!",
            confirm_promote = "Confirm Promotion"
        },
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})