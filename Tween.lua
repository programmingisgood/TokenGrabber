
--[[

    t Current time (in frames or seconds).
    b Starting value.
    c Change needed in value.
    d Expected easing duration (in frames or seconds).

--]]

local Tween = { }

function Tween.InQuad(t, b, c, d)
    return c * math.pow(t / d, 2) + b
end

function Tween.OutQuad(t, b, c, d)

    t = t / d
    return -c * t * (t - 2) + b
    
end

function Tween.InOutQuad(t, b, c, d)

    t = t / d * 2
    if t < 1 then
        return c / 2 * math.pow(t, 2) + b
    end
    
    return -c / 2 * ((t - 1) * (t - 3) - 1) + b
    
end

function Tween.OutInQuad(t, b, c, d)

    if t < d / 2 then
        return Tween.OutQuad(t * 2, b, c / 2, d)
    end
    
    return Tween.InQuad((t * 2) - d, b + c / 2, c / 2, d)
    
end

function Tween.inCubic (t, b, c, d)
    return c * math.pow(t / d, 3) + b
end

function Tween.outCubic(t, b, c, d) return c * (pow(t / d - 1, 3) + 1) + b end

function Tween.inOutCubic(t, b, c, d)

    t = t / d * 2
    if t < 1 then
        return c / 2 * t * t * t + b
    end
    t = t - 2
    return c / 2 * (t * t * t + 2) + b
    
end

function Tween.outInCubic(t, b, c, d)

    if t < d / 2 then return outCubic(t * 2, b, c / 2, d) end
    return inCubic((t * 2) - d, b + c / 2, c / 2, d)
    
end

function Tween.inQuart(t, b, c, d)
    return c * pow(t / d, 4) + b
end

function Tween.outQuart(t, b, c, d)
    return -c * (pow(t / d - 1, 4) - 1) + b
end

function Tween.inOutQuart(t, b, c, d)

    t = t / d * 2
    if t < 1 then
        return c / 2 * pow(t, 4) + b
    end
    return -c / 2 * (pow(t - 2, 4) - 2) + b
    
end

function Tween.outInQuart(t, b, c, d)

    if t < d / 2 then
        return outQuart(t * 2, b, c / 2, d)
    end
    
    return inQuart((t * 2) - d, b + c / 2, c / 2, d)
    
end

function Tween.inQuint(t, b, c, d)
    return c * pow(t / d, 5) + b
end

function Tween.outQuint(t, b, c, d)
    return c * (pow(t / d - 1, 5) + 1) + b
end

function Tween.inOutQuint(t, b, c, d)

    t = t / d * 2
    if t < 1 then
        return c / 2 * pow(t, 5) + b
    end
    
    return c / 2 * (pow(t - 2, 5) + 2) + b
    
end

function Tween.outInQuint(t, b, c, d)

    if t < d / 2 then
        return outQuint(t * 2, b, c / 2, d)
    end
    
    return inQuint((t * 2) - d, b + c / 2, c / 2, d)
    
end

function Tween.inSine(t, b, c, d)
    return -c * cos(t / d * (pi / 2)) + c + b
end

function Tween.outSine(t, b, c, d)
    return c * sin(t / d * (pi / 2)) + b
end

function Tween.inOutSine(t, b, c, d)
    return -c / 2 * (cos(pi * t / d) - 1) + b
end

function Tween.outInSine(t, b, c, d)

    if t < d / 2 then
        return outSine(t * 2, b, c / 2, d)
    end
    
    return inSine((t * 2) -d, b + c / 2, c / 2, d)
    
end

function Tween.inExpo(t, b, c, d)

    if t == 0 then
        return b
    end
    
    return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001
    
end

function Tween.outExpo(t, b, c, d)

    if t == d then
        return b + c
    end
    
    return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b
    
end

function Tween.inOutExpo(t, b, c, d)

    if t == 0 then
        return b
    end
    
    if t == d then
        return b + c
    end
    
    t = t / d * 2
    if t < 1 then
        return c / 2 * pow(2, 10 * (t - 1)) + b - c * 0.0005
    end
    
    return c / 2 * 1.0005 * (-pow(2, -10 * (t - 1)) + 2) + b
    
end

function Tween.outInExpo(t, b, c, d)

    if t < d / 2 then
        return outExpo(t * 2, b, c / 2, d)
    end
    
    return inExpo((t * 2) - d, b + c / 2, c / 2, d)
    
end

function Tween.inCirc(t, b, c, d)
    return(-c * (sqrt(1 - pow(t / d, 2)) - 1) + b)
end

function Tween.outCirc(t, b, c, d)
    return(c * sqrt(1 - pow(t / d - 1, 2)) + b)
end

function Tween.inOutCirc(t, b, c, d)

    t = t / d * 2
    if t < 1 then
        return -c / 2 * (sqrt(1 - t * t) - 1) + b
    end
    
    t = t - 2
    return c / 2 * (sqrt(1 - t * t) + 1) + b
    
end

function Tween.outInCirc(t, b, c, d)

    if t < d / 2 then
        return outCirc(t * 2, b, c / 2, d)
    end
    
    return inCirc((t * 2) - d, b + c / 2, c / 2, d)
    
end

local function CalculatePAS(p,a,c,d)

    p, a = p or d * 0.3, a or 0
    if a < abs(c) then
        return p, c, p / 4
    end
    
    return p, a, p / (2 * pi) * asin(c/a)
    
end

function Tween.inElastic(t, b, c, d, a, p)

    local s
    if t == 0 then
        return b
    end
    t = t / d
    if t == 1 then
        return b + c
    end
    p, a, s = CalculatePAS(p, a, c, d)
    t = t - 1
    return -(a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
end

function Tween.outElastic(t, b, c, d, a, p)

    local s
    if t == 0 then
        return b
    end
    
    t = t / d
    if t == 1 then
        return b + c
    end
    
    p,a,s = CalculatePAS(p,a,c,d)
    return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p) + c + b
    
end

function Tween.inOutElastic(t, b, c, d, a, p)

    local s
    if t == 0 then
        return b
    end
    
    t = t / d * 2
    if t == 2 then
        return b + c
    end
    
    p,a,s = CalculatePAS(p,a,c,d)
    
    t = t - 1
    if t < 0 then
        return -0.5 * (a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
    end
    
    return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p ) * 0.5 + c + b
    
end

function Tween.outInElastic(t, b, c, d, a, p)

    if t < d / 2 then
        return outElastic(t * 2, b, c / 2, d, a, p)
    end
    
    return inElastic((t * 2) - d, b + c / 2, c / 2, d, a, p)
    
end

function Tween.inBack(t, b, c, d, s)

    s = s or 1.70158
    t = t / d
    return c * t * t * ((s + 1) * t - s) + b
    
end

function Tween.outBack(t, b, c, d, s)

    s = s or 1.70158
    t = t / d - 1
    return c * (t * t * ((s + 1) * t + s) + 1) + b
    
end

function Tween.inOutBack(t, b, c, d, s)

    s = (s or 1.70158) * 1.525
    t = t / d * 2
    
    if t < 1 then
        return c / 2 * (t * t * ((s + 1) * t - s)) + b
    end
    
    t = t - 2
    return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
    
end

function Tween.outInBack(t, b, c, d, s)

    if t < d / 2 then
        return outBack(t * 2, b, c / 2, d, s)
    end
    
    return inBack((t * 2) - d, b + c / 2, c / 2, d, s)
    
end

function Tween.outBounce(t, b, c, d)

    t = t / d
    if t < 1 / 2.75 then
        return c * (7.5625 * t * t) + b
    end
    if t < 2 / 2.75 then
    
        t = t - (1.5 / 2.75)
        return c * (7.5625 * t * t + 0.75) + b
        
    elseif t < 2.5 / 2.75 then
    
        t = t - (2.25 / 2.75)
        return c * (7.5625 * t * t + 0.9375) + b
        
    end
    
    t = t - (2.625 / 2.75)
    return c * (7.5625 * t * t + 0.984375) + b
    
end

function Tween.inBounce(t, b, c, d)
    return c - outBounce(d - t, 0, c, d) + b
end

function Tween.inOutBounce(t, b, c, d)

    if t < d / 2 then
        return inBounce(t * 2, 0, c, d) * 0.5 + b
    end
    
    return outBounce(t * 2 - d, 0, c, d) * 0.5 + c * .5 + b
    
end

function Tween.outInBounce(t, b, c, d)

    if t < d / 2 then
        return outBounce(t * 2, b, c / 2, d)
    end
    
    return inBounce((t * 2) - d, b + c / 2, c / 2, d)
    
end

return Tween