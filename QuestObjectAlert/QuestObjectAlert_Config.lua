SLASH_QOAConfig1 = "/qoaconfig"

local function SanitizeFloat(value, default, min, max, precision)
    value = tonumber(value) or default
    value = math.max(min, math.min(max, value))
    if precision then
        local factor = 10 ^ precision
        value = math.floor(value * factor + 0.5) / factor
    end
    return value
end

local function CreateConfigFrame()
    if QOAConfigFrame then
        QOAConfigFrame:Show()
        return
    end

    local frame = CreateFrame("Frame", "QOAConfigFrame", UIParent, "UIPanelDialogTemplate")
    frame:SetSize(600, 400)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:Show()

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", 0, -5)
    frame.title:SetText("Quest Object Alert Config")

    -- Load defaults
    QOAConfig = QOAConfig or {}
	QOAConfig.playSound = (QOAConfig.playSound == nil) and true or QOAConfig.playSound
    QOAConfig.sound = QOAConfig.sound or "Interface\\AddOns\\QuestObjectAlert\\Resources\\ding.mp3"
    QOAConfig.cooldown = SanitizeFloat(QOAConfig.cooldown, 0.6, 0.1, 5.0, 2)
    QOAConfig.duration = SanitizeFloat(QOAConfig.duration, 0.6, 0.1, 2.0, 2)
    QOAConfig.color = QOAConfig.color or { r = 1, g = 1, b = 1, a = 1 }
	QOAConfig.size = SanitizeFloat(QOAConfig.size, 1.0, 0.25, 4.0, 2)

	-- SOUND ENABLE CHECKBOX + INPUT
	QOAConfig.playSound = (QOAConfig.playSound == nil) and true or QOAConfig.playSound
	
	-- Create container frame to center both elements together
	local soundContainer = CreateFrame("Frame", nil, frame)
	soundContainer:SetSize(520, 20) -- Wide enough to hold checkbox + edit box
	soundContainer:SetPoint("TOP", frame, "TOP", 0, -50)
	
	-- Checkbox
	local playSoundCB = CreateFrame("CheckButton", nil, soundContainer, "UICheckButtonTemplate")
	playSoundCB:SetPoint("LEFT", soundContainer, "LEFT", 0, 0)
	playSoundCB:SetChecked(QOAConfig.playSound)
	playSoundCB.text = playSoundCB:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	playSoundCB.text:SetPoint("LEFT", playSoundCB, "RIGHT", 2, 0)
	playSoundCB.text:SetText("Play Sound")
	
    -- SOUND TEXT INPUT
    local soundEdit = CreateFrame("EditBox", nil, soundContainer, "InputBoxTemplate")
    soundEdit:SetSize(500, 20)
    soundEdit:SetPoint("LEFT", playSoundCB.text, "RIGHT", 10, 0)
    soundEdit:SetAutoFocus(false)
    soundEdit:SetText(QOAConfig.sound)
	soundEdit:EnableMouse(QOAConfig.playSound)
	soundEdit:SetTextColor(1, 1, 1)  -- white
	if not QOAConfig.playSound then
		soundEdit:ClearFocus()
		soundEdit:SetTextColor(0.5, 0.5, 0.5)  -- gray
	end
	soundEdit:SetAlpha(QOAConfig.playSound and 1 or 0.5)

	local soundLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	soundLabel:SetPoint("BOTTOMLEFT", soundContainer, "TOPLEFT", 0, 5)
	soundLabel:SetText("Sound File Path")
	
	-- Checkbox logic
	playSoundCB:SetScript("OnClick", function(self)
		local enabled = self:GetChecked()
		QOAConfig.playSound = enabled

		soundEdit:EnableMouse(enabled)
		if enabled then
			soundEdit:SetTextColor(1, 1, 1)
		else
			soundEdit:ClearFocus()
			soundEdit:SetTextColor(0.5, 0.5, 0.5)
		end
	end)

    -- COOLDOWN SLIDER
    local cooldownSlider = CreateFrame("Slider", "QOAConfigCooldownSlider", frame, "OptionsSliderTemplate")
    cooldownSlider:SetWidth(400)
    cooldownSlider:SetPoint("TOP", soundContainer, "BOTTOM", 0, -40)
    cooldownSlider:SetMinMaxValues(0.1, 5.0)
    cooldownSlider:SetValueStep(0.1)
    cooldownSlider:SetValue(QOAConfig.cooldown)
    cooldownSlider.text = _G[cooldownSlider:GetName().."Text"]
    cooldownSlider.text:SetText("Cooldown: " .. QOAConfig.cooldown)
    cooldownSlider:SetScript("OnValueChanged", function(self, value)
        self.text:SetText("Cooldown: " .. string.format("%.1f", value))
    end)

    -- DURATION SLIDER
    local durationSlider = CreateFrame("Slider", "QOAConfigDurationSlider", frame, "OptionsSliderTemplate")
    durationSlider:SetWidth(400)
    durationSlider:SetPoint("TOP", cooldownSlider, "BOTTOM", 0, -40)
    durationSlider:SetMinMaxValues(0.1, 2.0)
    durationSlider:SetValueStep(0.1)
    durationSlider:SetValue(QOAConfig.duration)
    durationSlider.text = _G[durationSlider:GetName().."Text"]
    durationSlider.text:SetText("Pulse Duration: " .. QOAConfig.duration)
    durationSlider:SetScript("OnValueChanged", function(self, value)
        self.text:SetText("Pulse Duration: " .. string.format("%.1f", value))
    end)

    -- COLOR PICKER BUTTON
    local colorButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    colorButton:SetSize(120, 24)
    colorButton:SetPoint("TOP", durationSlider, "BOTTOM", 0, -30)
    colorButton:SetText("Set Pulse Color")
    colorButton:SetScript("OnClick", function()
        local r, g, b, a = QOAConfig.color.r, QOAConfig.color.g, QOAConfig.color.b, QOAConfig.color.a
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame.opacity = 1 - a
        ColorPickerFrame.hasOpacity = true
        ColorPickerFrame.previousValues = {r=r,g=g,b=b,opacity=1-a}
        ColorPickerFrame.func = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            local a = 1 - OpacitySliderFrame:GetValue()
            QOAConfig.color = { r = r, g = g, b = b, a = a }
        end
        ColorPickerFrame.cancelFunc = function(previous)
            QOAConfig.color = {
                r = previous.r,
                g = previous.g,
                b = previous.b,
                a = 1 - previous.opacity
            }
        end
        ColorPickerFrame:Show()
    end)
	
	-- SIZE SLIDER
	local sizeSlider = CreateFrame("Slider", "QOAConfigSizeSlider", frame, "OptionsSliderTemplate")
	sizeSlider:SetWidth(400)
	sizeSlider:SetPoint("TOP", colorButton, "BOTTOM", 0, -40)
	sizeSlider:SetMinMaxValues(0.25, 4.0)
	sizeSlider:SetValueStep(0.05)
	sizeSlider:SetValue(QOAConfig.size)
	sizeSlider.text = _G[sizeSlider:GetName().."Text"]
	sizeSlider.text:SetText("Pulse Size: " .. string.format("%.2fx", QOAConfig.size))
	sizeSlider:SetScript("OnValueChanged", function(self, value)
		self.text:SetText("Pulse Size: " .. string.format("%.2fx", value))
	end)
	
    -- SAVE BUTTON
    local save = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    save:SetSize(100, 24)
    save:SetPoint("BOTTOM", frame, "BOTTOM", 0, 20)
    save:SetText("Save & Close")
    save:SetScript("OnClick", function()
		QOAConfig.playSound = playSoundCB:GetChecked()
        QOAConfig.sound = soundEdit:GetText()
        QOAConfig.cooldown = cooldownSlider:GetValue()
        QOAConfig.duration = durationSlider:GetValue()
		QOAConfig.size = sizeSlider:GetValue()
		
        frame:Hide()
    end)
	
	-- CANCEL BUTTON
	local cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	cancel:SetSize(80, 24)
	cancel:SetPoint("LEFT", save, "RIGHT", 10, 0)
	cancel:SetText("Cancel")
	cancel:SetScript("OnClick", function()
		frame:Hide()
	end)
end

SlashCmdList["QOACONFIG"] = CreateConfigFrame