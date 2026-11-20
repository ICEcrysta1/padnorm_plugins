-- 基于时间的反死区：曲线后强度低于游戏死区时按该幅度脉冲输出，高于时直接直通。
-- 占空比 = 曲线后强度 / 脉冲的曲线后幅度；长期平均值与宿主映射曲线后的强度一致。
-- 开启 rescale_model 时改为静态反死区映射，适配会重新缩放死区以上输入的下游。

local stick_timers = {}
local last_ms
local last_dt_ms = 0

local function reset_timing()
    stick_timers = {}
    last_ms = nil
    last_dt_ms = 0
end

local function identity(value)
    return value
end

-- 求最小的输入强度，使宿主曲线后的输出不低于 target。
-- 宿主曲线按单调递增约定；目标不可达时返回 nil。
local function inverse(curve, target)
    if target <= 0 then
        return 0
    end
    if curve(1) < target then
        return nil
    end
    local low, high = 0, 1
    for _ = 1, 20 do
        local mid = (low + high) * 0.5
        if curve(mid) < target then
            low = mid
        else
            high = mid
        end
    end
    return high
end

local function process_stick(state, timer, now_ms)
    local binding = state.config
    local x, y = state.position[1], state.position[2]
    local length = math.sqrt(x * x + y * y)
    -- 旧宿主没有 curve 函数时按恒等映射处理
    local curve = state.curve or identity

    if length <= 0 then
        -- 回中时归零，并让恢复输入后的第一帧立刻出脉冲
        timer.start_ms = nil
        return { position = { -x, -y } }
    end

    -- 游戏死区：脉冲模式下是曲线后的目标幅度，缩放模式下是下游死区
    local game_deadzone = math.min(math.max((binding.game_deadzone or 0) / 100, 0), 0.99)

    -- 宿主曲线后的输入强度；落在宿主输入死区时为 0，不越权补偿
    local target = math.min(math.max(curve(length), 0), 1)
    if target <= 0 then
        timer.start_ms = nil
        return { position = { -x, -y } }
    end

    -- 缩放型反死区：静态映射，抵消下游对死区以上输入的重新缩放
    if binding.rescale_model then
        timer.start_ms = nil
        if game_deadzone <= 0 then
            return { position = { 0, 0 } }
        end
        -- 下游输出 = (a - 死区) / (1 - 死区)，反解 a 使下游输出等于曲线后强度
        local mapped = math.min(game_deadzone + target * (1 - game_deadzone), 1)
        local amplitude = inverse(curve, mapped) or 1
        local scale = amplitude / length
        return { position = { x * scale - x, y * scale - y } }
    end

    -- 曲线后强度达到游戏死区后本身已能通过，不再补偿
    if game_deadzone <= 0 or target >= game_deadzone then
        -- 离开补偿区后重新进入时立刻出脉冲，避免低强度下等待一个完整周期
        timer.start_ms = nil
        return { position = { 0, 0 } }
    end

    -- 反解出刚好越过游戏死区的输入幅度；曲线最大输出仍不够时无法补偿
    local amplitude = inverse(curve, game_deadzone) or 1
    local pulse_output = math.min(math.max(curve(amplitude), 0), 1)
    if pulse_output < game_deadzone then
        timer.start_ms = nil
        return { position = { -x, -y } }
    end

    -- 一帧之内无法再切分；脉宽至少覆盖一帧，否则低强度会被帧量化放大
    local pulse_ms = math.max(binding.pulse_width_ms, last_dt_ms)
    -- 占空比按曲线后的强度计算，保证长期平均值等于 target
    local duty = target / pulse_output
    local period_ms = pulse_ms / duty

    if timer.start_ms == nil then
        timer.start_ms = now_ms
    else
        -- 按整周期推进相位，而不是把起点重置到当前帧。
        -- 否则周期会被向上取整到帧边界，占空比接近 1 时被压成 0.8、0.5 等阶梯。
        local elapsed = now_ms - timer.start_ms
        if elapsed >= period_ms then
            timer.start_ms = timer.start_ms + math.floor(elapsed / period_ms) * period_ms
        end
    end

    if now_ms - timer.start_ms < pulse_ms then
        -- 沿原方向输出反解后的输入幅度；宿主按增量叠加
        local scale = amplitude / length
        return { position = { x * scale - x, y * scale - y } }
    end

    return { position = { -x, -y } }
end

return {
    init = function(manifest, host)
        reset_timing()
    end,

    reset = function(baseline, host)
        reset_timing()
    end,

    process = function(input, now_ms)
        -- 记录真实帧间隔，供脉宽下限使用；异常大间隔（休眠/卡顿）不参与估算
        if last_ms ~= nil then
            local dt = now_ms - last_ms
            if dt > 0 and dt < 50 then
                last_dt_ms = dt
            end
        end
        last_ms = now_ms

        local output = { buttons = {}, sticks = {}, triggers = {} }
        for id, state in pairs(input.controls.sticks) do
            -- 绑定级配置缺失时不提交输出，由宿主按原值直通
            if state.config then
                local timer = stick_timers[id]
                if timer == nil then
                    timer = {}
                    stick_timers[id] = timer
                end
                output.sticks[id] = process_stick(state, timer, now_ms)
            end
        end
        return output
    end,

    shutdown = function()
        reset_timing()
    end,
}
