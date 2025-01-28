-- name: Boba Fett 
-- description: from lego star wars the complete saga

E_MODEL_BOBAFETT_PLAYER = smlua_model_util_get_id('bobafett_geo')
E_MODEL_LASER = smlua_model_util_get_id('laser_geo')

local TEX_BOBAFETT_ICON = get_texture_info('bobafettIcon')

SAMPLE_FIRE_BLASTER =        audio_sample_load("bobaFire.ogg")

function on_character_select_load()
    if charSelectExists then
        CS_BOBAFETT = charSelect.character_add("Boba Fett",{"from lego star wars the complete saga","spacebar while jumping to hover","X to throw bomb","Y to blaster"},"Poobis__", {r=100,g=100,b=100},E_MODEL_BOBAFETT_PLAYER, CT_MARIO, TEX_BOBAFETT_ICON)
    else
        hook_chat_command("bobafett", "toggle boba feet", function()
            
            gSync.isBobaFett = not gSync.isBobaFett
            djui_chat_message_create("boba fett toggled")

            return true
        end)
    end
end

function convert_s16(num)
    local min = -2^15
    local max = 2^15 - 1
    while (num < min) do
        num = max + (num - min)
    end
    while (num > max) do
        num = min + (num - max)
    end
    return num
end

_G.gBobaStates = {}
for i = 0, (MAX_PLAYERS - 1) do
    gBobaStates[i] = {
        hoverTimer = 0
    }
end

function mario_update(m)
    local player = m.playerIndex
    local gSync = gPlayerSyncTable[m.playerIndex]
    local b = gBobaStates[m.playerIndex]

    if player == 0 then
        if charSelectExists then
            gSync.isBobaFett = false
            if charSelect.character_get_current_number() == CS_BOBAFETT then
                gSync.isBobaFett = true
            end
        end

        if gSync.isBobaFett then
            if  m.pos.y == m.floorHeight then
                b.hoverTimer = 0
            end

            if m.action == ACT_WALKING then
                m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x1000, 0x1000)
            end

            if (m.controller.buttonDown & Y_BUTTON) ~= 0 then
                mario_set_forward_vel(m, 200)
            elseif m.action == ACT_GROUND_POUND then
                mario_set_forward_vel(m, 200)
            end
            
            if (m.action == ACT_WALKING or m.action == ACT_IDLE) and (m.controller.buttonPressed & X_BUTTON) ~= 0 and m.action ~= ACT_BOBA_BLAST then
                set_mario_action(m, ACT_BOBA_BLAST, 0)
            end

            local canHover =  (m.action == ACT_JUMP or m.action == ACT_DOUBLE_JUMP or m.action == ACT_TRIPLE_JUMP or m.action == ACT_LONG_JUMP or m.action == ACT_FREEFALL or m.action == ACT_SIDE_FLIP or m.action == ACT_BACKFLIP)
            if canHover and b.hoverTimer == 0 and m.action ~= ACT_BOBA_HOVER and m.action ~= ACT_BOBA_HOVER_MOVE then
                if m.actionTimer > 0 and (m.input & INPUT_A_PRESSED) ~= 0 then
                    set_mario_action(m, ACT_BOBA_HOVER, 0)
                end
                m.actionTimer = m.actionTimer + 1
            end
            
        end
    end
end

---@param obj Object
local function bhvblastershot_init(obj)
    obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE

    obj.oGravity            = 0.05
    obj.oFriction           = 1.0

    obj.hitboxRadius        = 120
    obj.hitboxHeight        = 250
    obj.hurtboxRadius       = 120
    obj.hurtboxHeight       = 250

    obj.oInteractType       = INTERACT_BULLY

    obj.oDamageOrCoinValue  = 4

    obj.oTimer = 0
end

local function bhvblastershot_loop(obj)
    local step = object_step_without_floor_orient()

    obj.oForwardVel = 200
    obj.oTimer = obj.oTimer + 1

    if obj.oTimer > 100 or step & (OBJ_COL_FLAG_HIT_WALL) ~= 0 then
        spawn_mist_particles_with_sound(SOUND_OBJ_DEFAULT_DEATH)
        obj_mark_for_deletion(obj)
    end
    
end

id_bhvblastershot = hook_behavior(nil, OBJ_LIST_GENACTOR, false, bhvblastershot_init, bhvblastershot_loop)

ACT_BOBA_BLAST = allocate_mario_action(ACT_FLAG_STATIONARY)

---@param m MarioState
function act_boba_blast(m)
    set_mario_animation(m, CHAR_ANIM_BREAKDANCE)

    perform_ground_step(m)

    m.actionTimer = m.actionTimer + 1

    if m.actionTimer == 4 then
        m.forwardVel = m.forwardVel-5

        audio_sample_play(SAMPLE_FIRE_BLASTER, m.pos, 1)
        spawn_sync_object(id_bhvblastershot, E_MODEL_LASER, m.pos.x , m.pos.y+80, m.pos.z,
                ---@param o Object
                function (o)
                    o.oFaceAngleYaw = m.faceAngle.y
                    o.oMoveAngleYaw = o.oFaceAngleYaw
                    o.globalPlayerIndex = network_global_index_from_local(m.playerIndex)
            end)
    end

    if m.actionTimer >= 8 then
        if (m.controller.buttonPressed & X_BUTTON) ~= 0 then
            set_mario_action(m, ACT_BOBA_BLAST, 0)
        elseif m.input & INPUT_NONZERO_ANALOG ~= 0 then
            set_mario_action(m, ACT_WALKING, 0)
        elseif m.input & INPUT_A_PRESSED ~= 0 then
            set_mario_action(m, ACT_JUMP, 0)
        elseif m.input & INPUT_B_PRESSED ~= 0 and m.actionTimer >= 10 then
            set_mario_action(m, ACT_PUNCHING, 0)
        end
    end
    if m.actionTimer >= 14 then
        return set_mario_action(m, ACT_IDLE, 0)
    end

    return 0
end


ACT_BOBA_HOVER      = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_MOVING | ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_BOBA_HOVER_MOVE = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_MOVING | ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)

local function hover(m,idle)
    local b = gBobaStates[m.playerIndex]

    common_air_action_step(m,ACT_DOUBLE_JUMP_LAND,MARIO_ANIM_RUNNING_UNUSED,AIR_STEP_CHECK_LEDGE_GRAB)
    m.particleFlags = m.particleFlags | PARTICLE_FIRE

    m.faceAngle.y = m.intendedYaw - approach_s32(convert_s16(m.intendedYaw - m.faceAngle.y), 0, 0x1000, 0x1000)

    if m.pos.y <= m.floorHeight+70 then
        m.vel.y = m.vel.y+10
    elseif m.pos.y <= m.floorHeight+100 then
        m.vel.y = 5
    elseif m.pos.y <= m.floorHeight+140 then
        m.vel.y = 0
    else
        m.vel.y = -0.8
    end

    if b.hoverTimer >= 100 then
        set_mario_action(m,ACT_FREEFALL,0)
    end

    if idle == true then
        b.hoverTimer = b.hoverTimer + .5
    else
        b.hoverTimer = b.hoverTimer + 1
    end
end

function act_boba_hover(m)
    smlua_anim_util_set_animation(m.marioObj, 'hoveridle')
    
    hover(m,true)

    if (m.input & INPUT_NONZERO_ANALOG) ~= 0 then
        set_mario_action(m,ACT_BOBA_HOVER_MOVE,0)
    end

    if (m.input & INPUT_A_PRESSED) ~= 0 then
        set_mario_action(m,ACT_FREEFALL,0)
    elseif (m.input & INPUT_Z_PRESSED) ~= 0 then
        set_mario_action(m,ACT_GROUND_POUND,0)
    end
end

function act_boba_hover_move(m)
    smlua_anim_util_set_animation(m.marioObj, 'hovermove')

    hover(m,false)

    if (m.input & INPUT_NONZERO_ANALOG) ~= 0 then
        if m.forwardVel < 40 then
            m.forwardVel = m.forwardVel +4
        elseif m.forwardVel > 70 then
            m.forwardVel = 70
        end
    end

    if (m.input & INPUT_NONZERO_ANALOG) == 0 and m.vel.x <= 10 and m.vel.z <= 10 then
        set_mario_action(m,ACT_BOBA_HOVER,0)
    end

    if (m.input & INPUT_A_PRESSED) ~= 0 then
        set_mario_action(m,ACT_FREEFALL,0)
    elseif (m.input & INPUT_Z_PRESSED) ~= 0 then
        set_mario_action(m,ACT_GROUND_POUND,0)
    end
end

hook_mario_action(ACT_BOBA_BLAST, act_boba_blast)

hook_mario_action(ACT_BOBA_HOVER, act_boba_hover)
hook_mario_action(ACT_BOBA_HOVER_MOVE, act_boba_hover_move)

hook_event(HOOK_MARIO_UPDATE, mario_update)

hook_event(HOOK_ON_MODS_LOADED, on_character_select_load)