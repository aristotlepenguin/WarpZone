local WarpZone  = RegisterMod("WarpZone", 1)
local debug_str = "Placeholder"
local json = require("json")

local saveData = {}

local itemsSeen = {}


CollectibleType.COLLECTIBLE_6D = Isaac.GetItemIdByName("The Sticky D6")


local SfxManager = SFXManager()



function WarpZone:OnGameStart(isSave)
    if WarpZone:HasData()  and isSave then
        saveData = json.decode(WarpZone:LoadData())
        itemsSeen = saveData[1]
    end

    if not isSave then
        itemsSeen = {}

        local player = Isaac.GetPlayer(0)
    end

end
WarpZone:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, WarpZone.OnGameStart)


function WarpZone:preGameExit()
    saveData[1] = itemsSeen
    local jsonString = json.encode(saveData)
    WarpZone:SaveData(jsonString)
  end

  WarpZone:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, WarpZone.preGameExit)


function WarpZone:DebugText()
    local player = Isaac.GetPlayer(0)
    Isaac.RenderText(debug_str, 100, 60, 1, 1, 1, 255)
end
WarpZone:AddCallback(ModCallbacks.MC_POST_RENDER, WarpZone.DebugText)






