-- 在这里修改输入到输出之间的逻辑；默认保留按下状态和独立行程。
local function process_button(state)
    return {
        pressed = state.pressed,
        value = state.value,
    }
end

-- 直接返回摇杆增量；示例默认保持原位置。
local function process_stick(state)
    return { position = { 0, 0 } }
end

local config

local function process_trigger(state, strength)
    return { delta = state.value * (strength / 100 - 1) }
end

return {
    init = function(manifest, host)
        -- 全局配置在初始化时按字段 ID 传入。
        config = host.config
    end,

    reset = function(baseline, host)
        -- 示例没有锁存状态；添加有状态逻辑后，在这里按新基线复位。
    end,

    process = function(input, now_ms)
        local output = { buttons = {}, sticks = {}, triggers = {} }
        if not config.enabled then
            return output
        end
        if config.use_activation_button then
            local control = config.activation_button
            if type(control) ~= "table" then
                return output
            end
            local state
            if control.button then
                state = input.raw.buttons[control.button]
            elseif control.axis then
                local axis = input.raw.axes[control.axis]
                if axis and axis.kind == "trigger" then
                    state = axis
                end
            end
            if not state or not state.pressed then
                return output
            end
        end
        -- 使用本插件的抽象按钮 ID，适用于主程序传入的任意手柄按钮。
        -- input.raw 同时提供品牌无关的完整原始快照，可供新增逻辑读取。
        for id, state in pairs(input.controls.buttons) do
            output.buttons[id] = process_button(state)
        end
        for id, state in pairs(input.controls.sticks) do
            output.sticks[id] = process_stick(state)
        end
        for id, state in pairs(input.controls.triggers) do
            if state.config then
                output.triggers[id] = process_trigger(state, state.config.trigger_strength)
            end
        end
        return output
    end,

    shutdown = function()
        -- 示例没有需要释放的资源。
    end,
}
