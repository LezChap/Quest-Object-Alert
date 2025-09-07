local QOAFrame = CreateFrame("Frame")

-- Store quest objective text
local questObjectives = {}
local lastPulseTime = 0

-- Update quest objectives
local function UpdateQuestObjectives()
    wipe(questObjectives)
    for i = 1, GetNumQuestLogEntries() do
        local title, _, _, isHeader = GetQuestLogTitle(i)
        if isHeader ~= 1 then
            local numObjectives = GetNumQuestLeaderBoards(i)
            for j = 1, numObjectives do
                local text, type, done = GetQuestLogLeaderBoard(j, i)
				if text and not done and (type == "object" or type == "item") then
                    table.insert(questObjectives, string.lower(text))
                end
            end
        end
    end
end

-- Match tooltip lines to objectives
local function TooltipMatchesQuestObjective()
    for i = 1, GameTooltip:NumLines() do
        local line = _G["GameTooltipTextLeft"..i]
        if line then
            local tooltipText = string.lower(line:GetText() or "")
			
            if tooltipText ~= "" then
				for _, objective in ipairs(questObjectives) do
					if objective:find(tooltipText, 1, true) then
						return true
					end
				end
			end
        end
    end
    return false
end

-- Create pulse effect
local function ShowPulseAtCursor()
    local now = GetTime()
    local cooldown = QOAConfig and QOAConfig.cooldown or 0.6

    if now - lastPulseTime < cooldown then
        return -- still on cooldown
    end
    lastPulseTime = now

    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    x = x / scale
    y = y / scale

    local pulse = CreateFrame("Frame", nil, UIParent)
	local baseSize = 64
	local sizeMult = QOAConfig and QOAConfig.size or 1.0
	local size = baseSize * sizeMult
    pulse:SetSize(size, size)
    pulse:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)

    local tex = pulse:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\Cooldown\\star4") -- built-in circular-ish texture
    tex:SetBlendMode("ADD")
	tex:SetPoint("CENTER")
	tex:SetSize(size, size)
	
	local c = QOAConfig and QOAConfig.color or { r = 1, g = 1, b = 1, a = 1 }
    tex:SetVertexColor(c.r, c.g, c.b, c.a)

	local duration = QOAConfig and QOAConfig.duration or 0.6
    local elapsed = 0
    pulse:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        local progress = elapsed / duration
        local growth = 1 + progress * 1.5
        local alpha = 1 - progress
		
		tex:SetSize(size * growth, size * growth)
        tex:SetAlpha(alpha * c.a)
		
        if progress >= 1 then
            self:SetScript("OnUpdate", nil)
            self:Hide()
            self:SetParent(nil)
        end
    end)
end

-- Main trigger
GameTooltip:HookScript("OnShow", function()
	local owner = GameTooltip:GetOwner()

    if owner and owner:GetName() == "UIParent" and TooltipMatchesQuestObjective() then
		if QOAConfig and QOAConfig.playSound and QOAConfig.sound then
			if QOAConfig.sound ~= "" then
				PlaySoundFile(QOAConfig.sound or "Interface\\AddOns\\QuestObjectAlert\\Resources\\ding.mp3")
			end
		end
		if GetTime() - lastPulseTime >= (QOAConfig and QOAConfig.cooldown or 0.6) then
            ShowPulseAtCursor()
        end
    end
end)

-- Watch for quest updates
QOAFrame:RegisterEvent("QUEST_LOG_UPDATE")
QOAFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
QOAFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "QUEST_LOG_UPDATE" then
		UpdateQuestObjectives()
	elseif event == "PLAYER_ENTERING_WORLD" then
		UpdateQuestObjectives()
    end
end)