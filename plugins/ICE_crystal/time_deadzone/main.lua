-- 基于时间的反死区：输入低于最低幅度时按该幅度脉冲输出，高于时直接直通。
-- 占空比 = 强度 / 实际幅度，周期 = 脉宽 / 占空比，长期平均强度与原输入一致。

local pulse_start_ms
local pulse_until_ms = 0
local last_ms
local last_dt_ms = 0

local function reset_timing()
    pulse_start_ms = nil
    pulse_until_ms = 0
    last_ms = nil
    last_dt_ms = 0
end

local function process_stick(state, now_ms)
    local binding = state.config
    local x, y = state.position[1], state.position[2]
    local length = math.sqrt(x * x + y * y)

    if length <= 0 or length < binding.deadzone / 100 then
        -- 低于阈值时归零，并让恢复输入后的第一帧立刻出脉冲
        pulse_start_ms = nil
        pulse_until_ms = 0
        return { position = { -x, -y } }
    end

    -- 最低脉冲幅度：输入越高，实际幅度自动抬到输入值；达到它就不再补偿
    local min_amplitude = math.min(math.max(binding.min_amplitude / 100, 0), 1)
    if min_amplitude <= 0 or length >= min_amplitude then
        return { position = { 0, 0 } }
    end

    -- 一帧之内无法再切分；脉宽至少覆盖一帧，否则低强度会被帧量化放大
    local pulse_ms = math.max(binding.pulse_width_ms, last_dt_ms)

    if pulse_start_ms == nil then
        pulse_start_ms = now_ms
        pulse_until_ms = now_ms + pulse_ms
    end

    -- 周期随强度实时变化：强度上升时下一次脉冲自动提前
    local duty = length / min_amplitude
    if now_ms >= pulse_start_ms + pulse_ms / duty then
        pulse_start_ms = now_ms
        pulse_until_ms = now_ms + pulse_ms
    end

    if now_ms < pulse_until_ms then
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
                output.sticks[id] = process_stick(state, now_ms)
            end
        end
        return output
    end,

    shutdown = function()
        reset_timing()
    end,
}
