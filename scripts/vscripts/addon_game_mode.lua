if CAddonPlayerRules == nil then
   CAddonPlayerRules = class({})
end

function Activate()
    GameRules.one = CAddonPlayerRules()
    GameRules.one:InitGameMode()
end

function CAddonPlayerRules:InitGameMode()
    print("Addon is loaded.")
    --天辉，玩家最大选择人数
    self.iDesiredRadiant = 5
    --天辉，玩家最大选择人数
    self.iDesiredDire = 5
    --自定义游戏能否安全离开，false为启用惩罚，true为不启用惩罚
    self.SafeToLeave = false
    --死亡金钱，是否会掉落，false为不掉落，true为掉落
    self.GOLDLOSS = true
    --第一滴血奖励，false为不启用，true为启用
    self.FirstBlood = true
    --玩家开始金钱
    self.StartingGold = 600
    --金钱奖励数目，每滴答一下奖励多少金钱
    self.GoldPer = 1
    --金钱奖励时间，隔多少秒滴答一下
    self.GoldTick = 0.6
    --选择英雄最大多少秒
    self.HeroSelectionTime = 60
    --树木从破坏到重生需要多少秒
    self.TreeRegrowTime = 300

    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, self.iDesiredRadiant)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, self.iDesiredDire)
    GameRules:GetGameModeEntity():SetThink("OnThink", self, "GlobalThink", 2)
    GameRules:GetGameModeEntity():SetLoseGoldOnDeath(self.GOLDLOSS)
    GameRules:SetSafeToLeave(SafeToLeave)
    GameRules:SetFirstBloodActive(self.FirstBlood)
    GameRules:SetStartingGold()
    GameRules:SetGoldPerTick(self.GoldPer)
    GameRules:SetGoldTickTime(self.GoldTick)
    GameRules:SetHeroSelectionTime(self.HeroSelectionTime)
    GameRules:SetTreeRegrowTime(self.TreeRegrowTime)
end
