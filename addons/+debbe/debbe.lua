-- global SavedVariables
dbItems = {};
dbSettings = {};

-- speed optimization
local GetItemStats = GetItemStats;
local GetItemInfo = GetItemInfo;
local GetContainerNumSlots = GetContainerNumSlots;
local GetContainerItemLink = GetContainerItemLink;

-- other
local frame = CreateFrame("Frame");
local events = {};

function printf(...)
    return print(string.format(...));
end

function storeItem(itemLink)
    if not itemLink then
        return;
    end

    local stats = {};
    GetItemStats(itemLink, stats);
    local itemName, link, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEqupLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType = GetItemInfo(itemLink);
    local itemID = parseItemLink(itemLink);
    printf("Processing `%s`, type: `%s`", itemName, itemType);

    local info = {
        itemLink = link,
        itemName = itemName,
        itemRarity = itemRarity,
        itemLevel = itemLevel,
        itemMinLevel = itemMinLevel,
        itemType = itemType,
        itemSubType = itemSubType,
        itemStackCount = itemStackCount,
        itemEqupLoc = itemEqupLoc,
        itemIcon = itemIcon,
        itemSellPrice = itemSellPrice,
        itemClassID = itemClassID,
        itemSubClassID = itemSubClassID,
        bindType = bindType,
    };
    local data = {
        stats = stats,
        info = info,
    };

    for k, v in pairs(stats) do
        printf("%s: %s", k, v);
    end

    dbItems[itemID] = data;
    return data;
end

local ITEM_LINK_PATTERN = "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?";
function parseItemLink(itemLink)
    local _, _, Color, Ltype, itemID, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = itemLink:find(ITEM_LINK_PATTERN);
    return itemID;
end

function findItemLinks(msg)
    local result = {};
    for w in msg:gmatch("|c.+|r") do
        table.insert(result, w);
    end
    return result;
end

function events:CHAT_MSG_LOOT(msg, arg2, arg3, arg4, msgLootName) 
    print('CHAT MESSAGE LOOT');

    local links = findItemLinks(msg);
    for i, link in pairs(links) do
        storeItem(link);
    end
end

function events:QUEST_GREETING()
    print('QUEST GREETING');
end

function events:GOSSIP_SHOW()
    print('GOSSIP SHOW');
end

--[=====[ 
function events:PLAYER_TARGET_CHANGED()
    print('PLAYER TAGET CHANGED');
	ProcessUnit("target", _G.TARGET)
end

function events:UPDATE_MOUSEOVER_UNIT()
    print('UPDATE_MOUSEOVER_UNIT');
	local mouseoverID = UnitTokenToCreatureID("mouseover")

	if mouseoverID ~= UnitTokenToCreatureID("target") then
		ProcessUnit("mouseover", _G.MOUSE_LABEL)
	end
end
--]=====]

function scanBags()
  for bag = 0, 4 do
    for slot = 1, GetContainerNumSlots(bag) do
      local item = GetContainerItemLink(bag, slot);
      storeItem(item);
    end
  end
end

function debbeCmd(msg) 
    if msg == "" then
        print("help:");
        print("/debbe [item link] -- stores item in db");
        print("/debbe scan -- scans all bags for items and stores them in db");
    elseif msg == "scan" then
        scanBags();
    else
        storeItem(msg);
    end
end

--[=====[ 
function ProcessUnit(unitToken, sourceText)
	if UnitIsUnit("player", unitToken) then
		return
	end

	local npcID = UnitTokenToCreatureID(unitToken)

    if npcID then
        -- SetMapToCurrentZone();
        local unitIsDead = UnitIsDead(unitToken);

		local detectionData = {
			npcID = npcID,
			npcName = UnitName(unitToken),
			unitClassification = UnitClassification(unitToken),
            unitCreatureType = UnitCreatureType(unitToken),
            unitCreatureFamily = UnitCreatureFamily(unitToken),
			unitLevel = UnitLevel(unitToken),
            zone = GetZoneText(),
            subZone = GetSubZoneText(),
            race = GetUnitRace(),
        }
        printf("NPC: %d", npcID);
        printf("Location: %s (%s)", detectionData["zone"], detectionData["subZone"]);
	end
end

local ValidUnitTypeNames = {
    Creature = true,
    Vehicle = true,
}

function GUIDToCreatureID(GUID)
    local unitTypeName, _, _, _, _, unitID = ("-"):split(GUID)
    if ValidUnitTypeNames[unitTypeName] then
        return tonumber(unitID)
    end
end

function UnitTokenToCreatureID(unitToken)
    if unitToken then
        local GUID = UnitGUID(unitToken)
        if not GUID then
            return
        end

        return GUIDToCreatureID(GUID)
    end
end
--]=====]

SLASH_DEBBE1 = "/debbe"

function main()
    print('debbe addon loaded!');

    SlashCmdList["DEBBE"] = debbeCmd;

    frame:SetScript("OnEvent", function(self, event, ...)
        events[event](self, ...); -- call one of the functions above
    end);

    for k, v in pairs(events) do
        frame:RegisterEvent(k); -- Register all events for which handlers have been defined
    end
end

main();