if CAddonPlayerRules == nil then
   CAddonPlayerRules = class({})
end

-- 自定义经验表构建函数
-- 参数：maxLevel -> 要生成到的最大英雄等级
-- 返回：一个 Lua table，索引为等级（从1开始），值为升级所需经验（用于 SetCustomXPRequiredToReachNextLevel）
-- 说明：不同 Dota 2 版本对表的解释可能略有差异，常见用法是将表的第 n 项设为"从等级 n-1 升到 n 所需的经验"。
function CAddonPlayerRules:BuildCustomXPTable(maxLevel)
    local xpTable = {}
    if not maxLevel or maxLevel < 1 then
        return xpTable
    end

    -- 等级1没有经验要求（已在等级1）
    xpTable[1] = 0

    -- 下面使用一个简单的增长公式：
    -- xpForLevel = base * (level-1) + growth * ((level-1)*(level-2)/2)
    -- 这个公式会让每一级增长逐渐增加（近似二次增长），可以根据需要替换成任意序列或手动表
    -- 参数调整示例：下面设置为较快升级节奏（可根据需求调整）
    local base = 250    -- 基础经验：低等级每级所需的基础经验（影响前期升级速度）。增大此值会使每一级基础需求变大。
    local growth = 180  -- 成长系数：决定经验需求的二次项增长速度（影响后期曲线陡峭度）。增大此值会使高级别所需经验成倍上升。

    for lvl = 2, maxLevel do
        local n = lvl - 1
        local xpForLevel = math.floor(base * n + growth * ((n * (n - 1)) / 2))
        xpTable[lvl] = xpForLevel
    end

    return xpTable
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

    -- =====================
    -- 可调节的游戏规则（开发者可根据需要修改）
    -- =====================

    -- 玩家队伍最大人数设置（天辉/夜魇）
    -- 如果你想要更少或更多玩家，修改下面两个值
    self.iDesiredRadiant = 5
    self.iDesiredDire = 5

    -- 自定义游戏离开是否安全：
    -- false = 启用离开惩罚（不安全离开会被计入）、true = 不启用惩罚
    self.SafeToLeave = false

    -- 死亡是否掉落金钱：false = 不掉落，true = 掉落
    self.GOLDLOSS = true

    -- 是否启用第一滴血奖励（引擎层级）
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

    -- 额外规则示例（仅变量，不直接修改核心引擎行为，可根据需要启用）
    self.PreGameTime = 90         -- 正式开始前的准备时间
    self.StrategyTime = 0         -- 策略选择时间（部分模式使用）
    self.PostGameTime = 60        -- 结束后显示时间

    -- 是否允许相同英雄重复选择（true = 允许，false = 不允许）
    self.AllowSameHero = false

    -- 最大英雄等级（若想使用自定义经验表，可在此限制等级）
    self.MaxHeroLevel = 30

    -- 内部状态：记录第一滴血是否已经发生（用于自定义处理）
    self.bFirstBloodHappened = false

    -- =====================
    -- 将配置应用到 Dota2 引擎/模式实体上
    -- =====================
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, self.iDesiredRadiant)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, self.iDesiredDire)

    local mode = GameRules:GetGameModeEntity()

    -- 把 OnThink 注册到游戏主循环，每隔 2 秒先进行一次全局检查
    -- 注意：SetThink 可以接受方法名和 self（字符串方式）或直接传入函数。
    mode:SetThink("OnThink", self, "GlobalThink", 2)

    -- 设置死亡是否掉落金钱
    GameRules:GetGameModeEntity():SetLoseGoldOnDeath(self.GOLDLOSS)

    -- 设置是否允许安全离开
    GameRules:SetSafeToLeave(self.SafeToLeave)

    -- 设置第一滴血开关
    GameRules:SetFirstBloodActive(self.FirstBlood)

    -- 设置玩家起始金钱
    GameRules:SetStartingGold(self.StartingGold)

    -- 金钱滴答相关设置
    GameRules:SetGoldPerTick(self.GoldPer)
    GameRules:SetGoldTickTime(self.GoldTick)

    -- 英雄选择及树木重生时间
    GameRules:SetHeroSelectionTime(self.HeroSelectionTime)
    GameRules:SetTreeRegrowTime(self.TreeRegrowTime)

    -- 额外时间设置（引擎支持时生效）
    -- 注意：下面函数在不同的 Dota 2 版本/环境中可能不同，若不存在请注释或移除
    if GameRules.SetPreGameTime then
        GameRules:SetPreGameTime(self.PreGameTime)
    end
    if GameRules.SetStrategyTime then
        GameRules:SetStrategyTime(self.StrategyTime)
    end
    if GameRules.SetPostGameTime then
        GameRules:SetPostGameTime(self.PostGameTime)
    end

    -- 注册事件监听器：在实体被击杀、游戏状态变化、玩家连接/断开时做处理
    ListenToGameEvent("entity_killed", Dynamic_Wrap(self, "OnEntityKilled"), self)
    ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(self, "OnGameRulesStateChange"), self)
    ListenToGameEvent("player_disconnect", Dynamic_Wrap(self, "OnPlayerDisconnect"), self)

    -- 如果需要允许相同英雄复选/随机选择，可以在这里设置（示例为注释）
    -- if mode.SetAllowSameHeroSelection ~= nil then
    --     mode:SetAllowSameHeroSelection(self.AllowSameHero)
    -- end

    -- 应用自定义英雄等级上限（如果引擎支持）
    if mode.SetCustomHeroMaxLevel then
        mode:SetCustomHeroMaxLevel(self.MaxHeroLevel)
    end

    -- 构建并应用自定义经验表（如果引擎支持 SetCustomXPRequiredToReachNextLevel）
    if mode.SetCustomXPRequiredToReachNextLevel then
        self.CustomXPTable = self:BuildCustomXPTable(self.MaxHeroLevel)
        -- 打印前几级经验以便调试
        for i = 1, math.min(10, #self.CustomXPTable) do
            -- 注意：表的键从1开始，对应等级
            print(string.format("XP table level %d => %d", i, self.CustomXPTable[i]))
        end
        mode:SetCustomXPRequiredToReachNextLevel(self.CustomXPTable)
        print("Custom XP table applied up to level " .. tostring(self.MaxHeroLevel))
    else
        print("Engine does not support SetCustomXPRequiredToReachNextLevel; skipping custom XP table")
    end

    -- 如果你想强制设置最大英雄等级或自定义经验表，请在此实现
    -- 例如：mode:SetCustomHeroMaxLevel(self.MaxHeroLevel)

    -- 结束初始化
    print("Game rules initialized:",
          "Radiant=" .. tostring(self.iDesiredRadiant),
          "Dire=" .. tostring(self.iDesiredDire),
          "StartingGold=" .. tostring(self.StartingGold))
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

-- 事件处理示例：实体被击杀时触发的回调
function CAddonPlayerRules:OnEntityKilled(event)
    -- event 通常包含 entindex_killed, entindex_attacker, entindex_inflictor（如果有）等字段
    if event == nil then return end

    local killed_unit = EntIndexToHScript(event.entindex_killed)
    local killer_unit = nil
    if event.entindex_attacker ~= nil then
        killer_unit = EntIndexToHScript(event.entindex_attacker)
    end

    -- 仅在存在被击杀实体时继续
    if killed_unit == nil then return end

    -- 调试信息：打印被击杀和攻击者的名字（如果有）
    local killedName = killed_unit:GetUnitName() or tostring(killed_unit)
    local killerName = "[unknown]"
    if killer_unit ~= nil then killerName = killer_unit:GetUnitName() or tostring(killer_unit) end
    print(string.format("OnEntityKilled: killed=%s killer=%s", killedName, killerName))

    -- 自定义第一滴血处理（示例）：如果首次英雄杀死英雄并且我们启用了自定义处理，则记录并打印
    if not self.bFirstBloodHappened and killed_unit and killer_unit then
        if killed_unit:IsRealHero() and killer_unit:IsRealHero() then
            self.bFirstBloodHappened = true
            print("First blood detected: " .. tostring(killerName) .. " killed " .. tostring(killedName))
            -- 在这里你可以添加自定义第一滴血奖励逻辑（例如额外金钱、公告等）
        end
    end

    -- 你可以在此实现更多逻辑：掉落自定义物品、记录击杀数据、添加分数等
end

-- 游戏状态变化回调示例
function CAddonPlayerRules:OnGameRulesStateChange(event)
    -- 注意：不同环境下，获取具体状态的方式可能不同。
    -- 这里仅做简单的日志记录供调试使用。
    print("GameRules state changed")
    -- 如果你需要更细粒度的处理，可以查询 GameRules:State_Get()（若可用），或使用定时器延迟获取实体
end

-- 玩家断开连接回调示例
function CAddonPlayerRules:OnPlayerDisconnect(event)
    -- event 通常包含 PlayerID / userid 等字段
    print("OnPlayerDisconnect event:")
    -- 如果需要进一步处理，可以使用 event.player_id 或 event.userid（视具体事件结构而定）
    -- PrintTable(event)  -- 开发时可启用以查看完整事件字段
end

-- 示例：如何在类里定义一个其它事件处理函数（取消注释并根据需要实现）
-- function CAddonPlayerRules:OnSomeOtherEvent(event)
--     -- 处理逻辑
-- end
