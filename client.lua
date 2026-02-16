local VOICE_DELAY = 8000
local lastVoice = 0
local arrived = false

local distanceSamples = {}

local function Play(sound)
    SendNUIMessage({
        action = "play",
        sound = sound
    })
end

local function AddSample(dist)
    table.insert(distanceSamples, dist)
    if #distanceSamples > 6 then
        table.remove(distanceSamples, 1)
    end
end

local function IsGettingFurther()
    if #distanceSamples < 6 then return false end
    return distanceSamples[#distanceSamples] > distanceSamples[1] + 20
end

local function GetTurn(vehicleHeading, targetHeading)
    local vh = math.rad(vehicleHeading)
    local th = math.rad(targetHeading)

    local vx = math.cos(vh)
    local vy = math.sin(vh)

    local tx = math.cos(th)
    local ty = math.sin(th)

    local cross = vx * ty - vy * tx
    local dot = vx * tx + vy * ty
    local angle = math.deg(math.atan2(cross, dot))

    if angle > 30 then
        return "belok_kanan"
    elseif angle < -30 then
        return "belok_kiri"
    else
        return "lurus"
    end
end

CreateThread(function()
    while true do
        Wait(1200)

        if not IsWaypointActive() then
            arrived = false
            distanceSamples = {}
            goto skip
        end

        local wpBlip = GetFirstBlipInfoId(8)
        if not DoesBlipExist(wpBlip) then goto skip end

        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then goto skip end

        local veh = GetVehiclePedIsIn(ped, false)
        local pedCoords = GetEntityCoords(ped)
        local wpCoords = GetBlipInfoIdCoord(wpBlip)
        local dist = #(pedCoords - wpCoords)

        AddSample(dist)

        if dist < 18 and not arrived then
            Play("sampai_tujuan")
            SetWaypointOff()
            arrived = true
            goto skip
        end

        if GetGameTimer() - lastVoice < VOICE_DELAY then goto skip end

        if dist > 100 and IsGettingFurther() then
            Play("salah_jalur")
            lastVoice = GetGameTimer()
            distanceSamples = {}
            goto skip
        end

        if dist < 600 then
            local vehHeading = GetEntityHeading(veh)
            local targetHeading = GetHeadingFromVector_2d(
                wpCoords.x - pedCoords.x,
                wpCoords.y - pedCoords.y
            )

            local turn = GetTurn(vehHeading, targetHeading)
            Play(turn)
            lastVoice = GetGameTimer()
        end

        ::skip::
    end
end)
