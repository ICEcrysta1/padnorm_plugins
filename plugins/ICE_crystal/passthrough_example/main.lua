-- 在这里修改输入到输出之间的逻辑；默认保留按下状态和独立行程。
local function process_button(state)
    return {
        pressed = state.pressed,
        value = state.value,
    }
end

local function process_stick(state)
    return { position = { state.position[1], state.position[2] } }
end

local function process_trigger(state)
    return { pressed = state.pressed, value = state.value }
end

return {
    init = function(manifest, host)
        -- 示例没有需要初始化的资源。
    end,

    reset = function(baseline, host)
        -- 示例没有锁存状态；添加有状态逻辑后，在这里按新基线复位。
    end,

    process = function(input, now_ms)
        local output = { buttons = {}, sticks = {}, triggers = {} }
        -- 使用本插件的抽象按钮 ID，适用于主程序传入的任意手柄按钮。
        -- input.raw 同时提供品牌无关的完整原始快照，可供新增逻辑读取。
        for id, state in pairs(input.controls.buttons) do
            output.buttons[id] = process_button(state)
        end
        for id, state in pairs(input.controls.sticks) do
            local processed = process_stick(state)
            -- 宿主会叠加摇杆贡献；只返回变化量，直通时为零，保留原生精度。
            output.sticks[id] = {
                position = {
                    processed.position[1] - state.position[1],
                    processed.position[2] - state.position[2],
                },
            }
        end
        for id, state in pairs(input.controls.triggers) do
            local processed = process_trigger(state)
            output.triggers[id] = {
                pressed = processed.pressed,
                value = processed.value,
                delta = 0,
            }
        end
        return output
    end,

    shutdown = function()
        -- 示例没有需要释放的资源。
    end,
}
