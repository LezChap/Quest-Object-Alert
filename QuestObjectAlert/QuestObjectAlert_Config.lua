local _, QOA = ...

local originalConfig = nil

SLASH_QOAConfig1 = "/QOAConfig"

local function SanitizeFloat(value, default, min, max, precision)
    value = tonumber(value) or default
    value = math.max(min, math.min(max, value))
    if precision then
        local factor = 10 ^ precision
        value = math.floor(value * factor + 0.5) / factor
    end
    return value
end

local function copyTable(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = copyTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function CreateConfigFrame()
	for _, f in ipairs({EnumerateFrames()}) do
		if f:GetObjectType() == "EditBox" and not f:GetParent() then
			f:Hide()
		end
	end
	
    if QOAConfigFrame then
        QOAConfigFrame:Show()
        return
    end

    local frame = CreateFrame("Frame", "QOAConfigFrame", UIParent, "UIPanelDialogTemplate")
	
	originalConfig = copyTable(QOAConfig)

    frame:SetSize(650, 400)
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

	-- SOUND ENABLE CHECKBOX + INPUT
	QOAConfig.playSound = (QOAConfig.playSound == nil) and true or QOAConfig.playSound
	
	-- Create container frame to center both elements together
	local soundContainer = CreateFrame("Frame", "soundFrameContainer", frame)
	soundContainer:SetSize(650, 20) -- Wide enough to hold checkbox + edit box
	soundContainer:SetPoint("TOP", frame, "TOP", 0, -50)
	
	-- Checkbox
	local playSoundCB = CreateFrame("CheckButton", "soundCheckboxFrame", soundContainer, "UICheckButtonTemplate")
	playSoundCB:SetPoint("LEFT", soundContainer, "LEFT", 10, 0)
	playSoundCB:SetChecked(QOAConfig.playSound)
	playSoundCB.text = playSoundCB:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	playSoundCB.text:SetPoint("LEFT", playSoundCB, "RIGHT", 2, 0)
	playSoundCB.text:SetText("Play Sound")
	
    -- SOUND TEXT INPUT
    local soundEdit = CreateFrame("EditBox", "soundFileFrame", soundContainer, "InputBoxTemplate")
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
    soundEdit:SetScript("OnTextChanged", function(self)
        QOAConfig.sound = self:GetText()
    end)

	local soundLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	soundLabel:SetPoint("CENTER", soundContainer, "TOP", 0, 5)
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
		soundEdit:SetAlpha(enabled and 1 or 0.5)
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
        value = SanitizeFloat(value, QOAConfig.cooldown, 0.1, 5.0, 1)
        QOAConfig.cooldown = value
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
	    value = SanitizeFloat(value, QOAConfig.duration, 0.1, 2.0, 1)
        QOAConfig.duration = value
        self.text:SetText("Pulse Duration: " .. string.format("%.1f", value))
    end)

    -- COLOR PICKER BUTTON
    local colorButton = CreateFrame("Button", "ColorButtonFrame", frame, "UIPanelButtonTemplate")
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
	    value = SanitizeFloat(value, QOAConfig.size, 0.25, 4.0, 2)
        QOAConfig.size = value
		self.text:SetText("Pulse Size: " .. string.format("%.2fx", value))
	end)

    -- SAVE BUTTON
    local save = CreateFrame("Button", "saveButtonFrame", frame, "UIPanelButtonTemplate")
    save:SetSize(100, 24)
    save:SetPoint("BOTTOM", frame, "BOTTOM", 0, 20)
    save:SetText("Save & Close")
    save:SetScript("OnClick", function()
        frame:Hide()
		originalConfig = nil 
    end)
	
	-- TEST BUTTON
	local test = CreateFrame("Button", "testButtonFrame", frame, "UIPanelButtonTemplate")
	test:SetSize(80, 24)
	test:SetPoint("RIGHT", save, "LEFT", -10, 0)
	test:SetText("Test")
	test:SetScript("OnClick", function()
		if QOA and QOA.doAlert then
			local x, y = GetCursorPosition()
			QOA.doAlert(x-50, y-50)
		else
			print("QuestObjectAlert ERROR: QOA.doAlert() is not available.")
		end				
	end)
	
	local function RestoreConfigToUI()
        playSoundCB:SetChecked(QOAConfig.playSound)
        soundEdit:SetText(QOAConfig.sound or "")
        soundEdit:EnableMouse(QOAConfig.playSound)
        soundEdit:SetTextColor(QOAConfig.playSound and 1 or 0.5, QOAConfig.playSound and 1 or 0.5, QOAConfig.playSound and 1 or 0.5)
        soundEdit:SetAlpha(QOAConfig.playSound and 1 or 0.5)

        cooldownSlider:SetValue(QOAConfig.cooldown)
        cooldownSlider.text:SetText("Cooldown: " .. string.format("%.1f", QOAConfig.cooldown))

        durationSlider:SetValue(QOAConfig.duration)
        durationSlider.text:SetText("Pulse Duration: " .. string.format("%.1f", QOAConfig.duration))

        sizeSlider:SetValue(QOAConfig.size)
        sizeSlider.text:SetText("Pulse Size: " .. string.format("%.2fx", QOAConfig.size))
    end
		
	-- CANCEL BUTTON
	local cancel = CreateFrame("Button", "cancelButtonFrame", frame, "UIPanelButtonTemplate")
	cancel:SetSize(80, 24)
	cancel:SetPoint("LEFT", save, "RIGHT", 10, 0)
	cancel:SetText("Cancel")
	cancel:SetScript("OnClick", function()
	    if originalConfig then
            QOAConfig = {}
			QOAConfig = copyTable(originalConfig)
            RestoreConfigToUI()
        end
		frame:Hide()
	end)
	
	-- At the end, initialize UI controls from current config
    RestoreConfigToUI()
	
end

SlashCmdList["QOAConfig"] = CreateConfigFrame