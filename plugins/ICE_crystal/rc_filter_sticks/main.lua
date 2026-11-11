local config
local states = {}
local last_ms
local next_jitter_ms

local function new_state(input)
    return { x = input.position[1], y = input.position[2] }
end

return {
    init = function(manifest, host)
        -- 宿主将声明式配置中的当前值按字段 ID 交给插件。
        config = host.config
        -- 每个设备会话有独立 VM；复位时继续随机序列，避免反复播放同一段抖动。
        math.randomseed(os.time() + math.floor(os.clock() * 1000000))
    end,

    reset = function(baseline, host, reason)
        -- 普通按键边沿保留连续滤波历史；会话或映射基线变化时重新建立状态。
        if reason ~= "input_changed" then
            states = {}
            last_ms = nil
            next_jitter_ms = nil
            for id, input in pairs(baseline.controls.sticks) do
                states[id] = new_state(input)
            end
        end
        if next(states) then
            -- 宿主在复位、停用及断开时取消旧任务；静止时也继续滤波和抖动。
            host.spawn(function()
                while true do
                    host.sleep(config.update_interval_ms)
                    host.request_update()
                end
            end)
        end
    end,

    process = function(input, now_ms)
        local alpha = 1 - math.exp(-((now_ms - (last_ms or now_ms)) / config.rc_ms))
        last_ms = now_ms
        local refresh = not next_jitter_ms or now_ms >= next_jitter_ms
        if refresh then
            next_jitter_ms = now_ms + config.update_interval_ms
        end
        local output = { sticks = {} }
        local current = {}
        for id, stick in pairs(input.controls.sticks) do
            local state = states[id] or new_state(stick)
            state.x = state.x + alpha * (stick.position[1] - state.x)
            state.y = state.y + alpha * (stick.position[2] - state.y)
            if refresh or not state.jx then
                -- 圆周角度均匀分布：向量长度固定，X/Y 期望均为零。
                local angle = math.random() * 2 * math.pi
                local amplitude = config.jitter_percent / 100
                state.jx = amplitude * math.cos(angle)
                state.jy = amplitude * math.sin(angle)
            end
            -- 直接贡献处理后的位置，异步结果不会与更新后的输入错位相加。
            output.sticks[id] = {
                position = { state.x + state.jx, state.y + state.jy },
                mix = "replace",
            }
            current[id] = state
        end
        states = current
        return output
    end,

    shutdown = function()
        states = {}
    end,
}
