if CAddonPlayerRules == nil then
   CAddonPlayerRules = class({})
end

-- Activate 在自定义游戏启动时被引导调用，创建并初始化我们的规则实例
function Activate()
    -- 存在 GameRules 的字段中以便调试时能方便访问
    GameRules.Addon = CAddonPlayerRules()
    GameRules.Addon:InitGameMode()
end

-- 初始化游戏模式：设置各种自定义规则和定时器
function CAddonPlayerRules:InitGameMode()
    print("Addon is loaded.")

    -- 玩家队伍最大人数设置（天辉/夜魇）
    -- 如果你想要更少或更多玩家，修改下面两个值
    self.iDesiredRadiant = 5
    self.iDesiredDire = 5

    -- 自定义游戏离开是否安全：
    -- false = 启用离开惩罚（不安全离开会被计入）、true = 不启用惩罚
    self.SafeToLeave = false

    -- 死亡是否掉落金钱：false = 不掉落，true = 掉落
    self.GOLDLOSS = true

    -- 是否启用第一滴血奖励
    self.FirstBlood = true

    -- 玩家初始金钱（出生时得到的金钱）
    self.StartingGold = 600

    -- 金钱每次滴答奖励数目（每次加多少）
    self.GoldPer = 1

    -- 金钱滴答时间间隔（秒）
    self.GoldTick = 0.6

    -- 英雄选择时间（秒）
    self.HeroSelectionTime = 60

    -- 树木从被摧毁到重生所需的秒数
    self.TreeRegrowTime = 300

    -- 应用到 Dota2 引擎的设置
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, self.iDesiredRadiant)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, self.iDesiredDire)

    local mode = GameRules:GetGameModeEntity()

    -- 把 OnThink 注册到游戏主循环，每隔 2 秒先进行一次全局检查
    -- 注意：SetThink 可以接受方法名和 self（字符串方式）或直接传入函数。
    mode:SetThink("OnThink", self, "GlobalThink", 2)

    -- 设置死亡是否掉落金钱
    GameRules:GetGameModeEntity():SetLoseGoldOnDeath(self.GOLDLOSS)

    -- 设置是否允许安全离开（修复：使用 self.SafeToLeave 而不是未定义的全局变量）
    GameRules:SetSafeToLeave(self.SafeToLeave)

    -- 设置第一滴血开关
    GameRules:SetFirstBloodActive(self.FirstBlood)

    -- 设置玩家起始金钱（修复：原代码遗漏了参数）
    GameRules:SetStartingGold(self.StartingGold)

    -- 金钱滴答相关设置
    GameRules:SetGoldPerTick(self.GoldPer)
    GameRules:SetGoldTickTime(self.GoldTick)

    -- 英雄选择及树木重生时间
    GameRules:SetHeroSelectionTime(self.HeroSelectionTime)
    GameRules:SetTreeRegrowTime(self.TreeRegrowTime)

    -- 你可以在这里注册更多的事件监听器，例如：
    -- ListenToGameEvent("entity_killed", Dynamic_Wrap(self, "OnEntityKilled"), self)
    -- 上面的写法将在类中查找 OnEntityKilled 方法，并在实体被击杀时调用它
end

-- OnThink 是我们周期性运行的定时器回调
-- 返回值为下一次调用的时间（秒）。返回 nil 或 -1 可以停止定时器
function CAddonPlayerRules:OnThink()
    -- 这里放入你想要每 X 秒检查一次的逻辑，例如日志、状态检查或自动事件触发
    -- 注意：不要把耗时操作放在这里，会影响游戏性能

    -- 示例：打印一次简单的心跳（仅用于调试）
    -- print("CAddonPlayerRules:OnThink heartbeat")

    -- 返回 1，会在 1 秒后再次调用 OnThink。根据需要调整间隔。
    return 1
end

-- 示例：如何在类里定义一个事件处理函数（取消注释并根据需要实现）
-- function CAddonPlayerRules:OnEntityKilled(event)
--     -- event 包含被击杀实体、攻击者等信息，详见 Dota 2 API 事件文档
--     local killed_ent = EntIndexToHScript(event.entindex_killed)
--     local killer_ent = EntIndexToHScript(event.entindex_attacker)
--     -- 在这里处理逻辑，例如记分、掉落等
-- end
