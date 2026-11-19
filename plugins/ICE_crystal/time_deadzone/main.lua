-- 基于时间的反死区：输入低于最低幅度时按该幅度脉冲输出，高于时直接直通。
-- 占空比 = 强度 / 实际幅度，周期 = 脉宽 / 占空比；下游死区之前的平均强度与原输入一致。
-- 开启 rescale_model 时改为静态反死区映射，适配会重新缩放死区以上输入的下游。

local stick_timers = {}
local last_ms
local last_dt_ms = 0

local function reset_timing()
    stick_timers = {}
    last_ms = nil
    last_dt_ms = 0
end

local function process_stick(state, timer, now_ms)
    local binding = state.config
    local x, y = state.position[1], state.position[2]
    local length = math.sqrt(x * x + y * y)

    if length <= 0 or length < binding.deadzone / 100 then
        -- 低于阈值时归零，并让恢复输入后的第一帧立刻出脉冲
        timer.start_ms = nil
        return { position = { -x, -y } }
    end

    -- 缩放型下游：静态反死区映射，抵消下游对死区以上输入的重新缩放
    if binding.rescale_model then
        timer.start_ms = nil
        local downstream = math.min(math.max((binding.downstream_deadzone or 0) / 100, 0), 0.99)
        if downstream <= 0 then
            return { position = { 0, 0 } }
        end
        -- 下游输出 = (a - 死区) / (1 - 死区)，反解 a 使下游输出等于输入强度
        local target = math.min(downstream + length * (1 - downstream), 1)
        local scale = target / length
        return { position = { x * scale - x, y * scale - y } }
    end

    -- 最低脉冲幅度：输入越高，实际幅度自动抬到输入值；达到它就不再补偿
    local min_amplitude = math.min(math.max(binding.min_amplitude / 100, 0), 1)
    if min_amplitude <= 0 or length >= min_amplitude then
        -- 离开补偿区后重新进入时同样立刻出脉冲，避免低强度下等待一个完整周期
        timer.start_ms = nil
        return { position = { 0, 0 } }
    end

    -- 一帧之内无法再切分；脉宽至少覆盖一帧，否则低强度会被帧量化放大
    local pulse_ms = math.max(binding.pulse_width_ms, last_dt_ms)
    local duty = length / min_amplitude
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
        -- 沿原方向输出最低幅度；宿主按增量叠加
        local scale = min_amplitude / length
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
