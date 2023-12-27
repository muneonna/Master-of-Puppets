_addon.author   = 'Muneonna';
_addon.name     = 'Master-of-Puppets';
_addon.version  = '1.3';

require 'common';

-- Obtain Player and Pet Stats

-- Global variables to store player stats
local playerstr, playerdex, playervit, playeragi, playerint, playermnd, playerchr = 0, 0, 0, 0, 0, 0, 0

-- Global variables to store pet stats - always assume bad burden by default
local petstr, petdex, petvit, petagi, petint, petmnd, petchr = 99, 99, 99, 99, 99, 99, 99

-- Function to get and display player stats
local function display_player_stats()
    local player = AshitaCore:GetDataManager():GetPlayer();

    -- Retrieve and display player stats
    playerstr = player:GetStat(0) + player:GetStat(7);
    playerdex = player:GetStat(1) + player:GetStat(8);
    playervit = player:GetStat(2) + player:GetStat(9);
    playeragi = player:GetStat(3) + player:GetStat(10);
    playerint = player:GetStat(4) + player:GetStat(11);
    playermnd = player:GetStat(5) + player:GetStat(12);
    playerchr = player:GetStat(6) + player:GetStat(13);


    print(string.format("Player STR: %d, DEX: %d, VIT: %d, AGI: %d, INT: %d, MND: %d, CHR: %d",
        playerstr, playerdex, playervit, playeragi, playerint, playermnd, playerchr));
end

-- Function to display pet stats
local function display_pet_stats()
    print(string.format("Pet STR: %d, DEX: %d, VIT: %d, AGI: %d, INT: %d, MND: %d, CHR: %d", 
            petstr, petdex, petvit, petagi, petint, petmnd, petchr));
end

-- Function to register pet stats
local function register_pet_stats(args)
    if #args == 9 and tonumber(args[3]) and tonumber(args[4]) and tonumber(args[5]) and tonumber(args[6]) and tonumber(args[7]) and tonumber(args[8]) and tonumber(args[9]) then
        petstr, petdex, petvit, petagi, petint, petmnd, petchr = tonumber(args[3]), tonumber(args[4]), tonumber(args[5]), tonumber(args[6]), tonumber(args[7]), tonumber(args[8]), tonumber(args[9])
        print("Pet stats registered successfully.")
    else
        print("Error: Please provide exactly seven numerical values.")
    end
end

-- Function to display help
local function display_help()
    print("------------------------------------------------------------------------------------------------------")
    print("- Usage: /mops [registerpet xx xx xx xx xx xx xx]")
    print("- If you do not register a pet, the addon will assume bad burden for all maneuvers.")
    print("- You can use this in a macro.")
    print("------------------------------------------------------------------------------------------------------")
    print("- registerpet:    Registers pet stats for burden calculation. Must be used with seven numerical values.")
    print("- pet:             Displays pet stats.")
    print("- me:             Displays player stats.")
    print("- help:            Displays this help message.")
    print("- knownissues:   Displays known issues.")
    print("------------------------------------------------------------------------------------------------------")
end

-- Function to display known issues
local function display_known_issues()
    print("Known Issues:")
    print("1. Gear swaps may cause incorrect burden identification.")
    print("2. Zoning with a pet does not update pet burden properly.")
    print("3. Dark Maneuver burden is calculated strictly as bad burden.")
    print("4. Need to work in a way to reset burden without resetting the addon.")
    print("5. I would like to make a command that activates/deactivates burden readouts.")
    print("6. Heatsink is unaccounted for.")
    print("7. Multiple Puppetmasters in the same party may cause incorrect burden identification.")
end

-- Modify the command handler
ashita.register_event('command', function(cmd, nType)
    local args = cmd:args();
    if #args > 0 and args[1] == '/mops' then
        if args[2] == 'registerpet' then
            register_pet_stats(args)
            return true;
        elseif args[2] == 'pet' then
            display_pet_stats()
            return true;
        elseif args[2] == 'me' then
            display_player_stats()
            return true;
        elseif args[2] == 'knownissues' then
            display_known_issues()
            return true;
        elseif args[2] == 'help' then
            display_help()
            return true;
        else
            -- Display both player and pet stats
            display_player_stats()
            display_pet_stats()
            return true;
        end
    end
    return false;
end);

-- Burden Tracker

-- Define the maneuvers for each element
local maneuvers = {'Fire Maneuver', 'Ice Maneuver', 'Wind Maneuver', 'Earth Maneuver', 'Thunder Maneuver', 'Water Maneuver', 'Light Maneuver', 'Dark Maneuver' }
-- Initialize burden counters for each element
local burdens = { fire = 0, ice = 0, wind = 0, earth = 0, thunder = 0, water = 0, light = 0, dark = 0 }
-- Associate each maneuver with it's stat.
local maneuver_stats = {
    ['Fire Maneuver'] = 'STR',
    ['Thunder Maneuver'] = 'DEX',
    ['Earth Maneuver'] = 'VIT',
    ['Wind Maneuver'] = 'AGI',
    ['Ice Maneuver'] = 'INT',
    ['Water Maneuver'] = 'MND',
    ['Light Maneuver'] = 'CHR',
    ['Dark Maneuver'] = 'Dark' -- Using 'Dark' as a placeholder for special handling
}

-- Constants for burden values and decay
local GOOD_BURDEN = 15;
local BAD_BURDEN = 20;
local DARK_MANEUVER_GOOD_BURDEN = 10;
local DARK_MANEUVER_BAD_BURDEN = 15;
local decay_rate = 1; -- One point of burden is removed every three seconds
local last_decay_time = os.clock();
local decay_interval = 3; -- Burden decays every 3 seconds

-- If the player has a higher stat for the associated maneuver, add good burden. If they have a lower stat, add bad burden. If it's dark maneuver, always use bad burden.
local function getBurden(maneuver)
    -- Retrieve the player's current stat values
    local playerStats = {
        STR = AshitaCore:GetDataManager():GetPlayer():GetStat(0) + AshitaCore:GetDataManager():GetPlayer():GetStat(7),
        DEX = AshitaCore:GetDataManager():GetPlayer():GetStat(1) + AshitaCore:GetDataManager():GetPlayer():GetStat(8),
        VIT = AshitaCore:GetDataManager():GetPlayer():GetStat(2) + AshitaCore:GetDataManager():GetPlayer():GetStat(9),
        AGI = AshitaCore:GetDataManager():GetPlayer():GetStat(3) + AshitaCore:GetDataManager():GetPlayer():GetStat(10),
        INT = AshitaCore:GetDataManager():GetPlayer():GetStat(4) + AshitaCore:GetDataManager():GetPlayer():GetStat(11),
        MND = AshitaCore:GetDataManager():GetPlayer():GetStat(5) + AshitaCore:GetDataManager():GetPlayer():GetStat(12),
        CHR = AshitaCore:GetDataManager():GetPlayer():GetStat(6) + AshitaCore:GetDataManager():GetPlayer():GetStat(13)
    }

    -- Retrieve the pet's stat values from the global variables
    local petStatValues = {
        STR = petstr,
        DEX = petdex,
        VIT = petvit,
        AGI = petagi,
        INT = petint,
        MND = petmnd,
        CHR = petchr
    }

    -- Determine the stat type for the maneuver
    local statType = maneuver_stats[maneuver]
    
    -- Determine the burden based on the maneuver and stat comparison
    if statType == 'Dark' then
        -- Dark Maneuvers have their own fixed burden values
        return DARK_MANEUVER_BAD_BURDEN
    else
        -- For other maneuvers, compare player's stat to the pet's stat
        if playerStats[statType] >= petStatValues[statType] then
            return GOOD_BURDEN
        else
            return BAD_BURDEN
        end
    end
end


-- User customization settings
local user_settings = {
    threshold = 32, -- Threshold for warning
    overload_threshold = 48, -- Overload threshold
    show_window = true, -- Toggle to show/hide the burden window
    window_size = { width = 400, height = 180 }, -- Window size
    maneuver_sound = 'maneuver.wav', -- Sound to play on maneuver use
    overload_sound = 'overload_warning.wav', -- Sound to play on overload warning
    play_sound = false -- Toggle to enable/disable sound alerts
}

-- Function to add burden for a maneuver
local function addBurden(maneuver)
    -- Delay fetching and updating player stats by one second after a maneuver is used
        -- Calculate the burden amount based on updated stats
        local burdenAmount = getBurden(maneuver)
        local key = maneuver:lower():gsub(' maneuver', ''):gsub(' ', '')

        -- Apply the calculated burden
        if burdens[key] ~= nil then
            burdens[key] = burdens[key] + burdenAmount
                -- Comment this line out if you don't want to see the burden amount in the chat log
                -- print(string.format("Added %d burden to %s, total is now %d.", burdenAmount, key, burdens[key]))
        else
                print(string.format("Invalid maneuver type: %s", maneuver))
        end

        -- Optionally, play a sound or give a warning if a threshold is reached
        if user_settings.play_sound and burdens[key] >= user_settings.threshold then
            ashita.misc.play_sound(user_settings.maneuver_sound)
        end
end



-- Function to decay burden over time
local function decayBurden()
    local current_time = os.clock();
    if (current_time - last_decay_time) >= decay_interval then
        for element, value in pairs(burdens) do
            burdens[element] = math.max(value - decay_rate, 0);
        end
        last_decay_time = current_time;
    end
end

--- Incoming text event to detect maneuver activation
ashita.register_event('incoming_text', function(mode, text, modifiedmode, modifiedtext, blocked)
    for _, maneuver in ipairs(maneuvers) do
        local pattern = string.format('.* uses %s.*', maneuver);
        if text:match(pattern) then

            local maneuverType = maneuver:lower():gsub(' maneuver', ''):gsub(' ', '');
            local burdenAmount = getBurden(maneuver)
            addBurden(maneuver, burdenAmount)
            
            -- Optionally, play a sound or give a warning if a threshold is reached
            if user_settings.play_sound and burdens[maneuverType] >= user_settings.threshold then
                ashita.misc.play_sound(user_settings.maneuver_sound)
            end

            -- Optionally, block the text from appearing in the chat log
            -- return true;
        end
    end
    if text:match('.* uses Activate') then
        for element, _ in pairs(burdens) do
            burdens[element] = 33;
        end
        return true;
    end
    -- Allow the text to be processed normally if no maneuver was detected
    return false;
end);

-- Prerender event for burden decay
ashita.register_event('prerender', function()
    decayBurden();
end);

-- Render the burden on screen using imgui
ashita.register_event('render', function()
    if not user_settings.show_window then
        return;
    end

    imgui.SetNextWindowSize(user_settings.window_size.width, user_settings.window_size.height, ImGuiSetCond_Always);
    if imgui.Begin('Master-of-Puppets') then
        imgui.Columns(2, 'burdenColumns');
        imgui.SetColumnOffset(1, 150);

        for element, value in pairs(burdens) do
            local burden_percentage = (value / user_settings.overload_threshold) * 100;
            burden_percentage = math.min(burden_percentage, 100);

            imgui.Text(element);
            imgui.NextColumn();
            
            local color = { r = 0.4, g = 1.0, b = 0.4, a = 0.6 };
            if burden_percentage >= 100 then
                color = { r = 1.0, g = 0.4, b = 0.4, a = 0.6 };
                if user_settings.play_sound then
                    ashita.misc.play_sound(user_settings.overload_sound);
                end
            elseif burden_percentage >= user_settings.threshold then
                color = { r = 1.0, g = 1.0, b = 0.0, a = 0.6 };
            end

            imgui.PushStyleColor(ImGuiCol_PlotHistogram, color.r, color.g, color.b, color.a);
            imgui.ProgressBar(burden_percentage / 100, -1, 14, string.format('%d%%', burden_percentage));
            imgui.PopStyleColor(1);
            imgui.NextColumn();
        end

        imgui.Columns(1);
        imgui.End();
    end
end);