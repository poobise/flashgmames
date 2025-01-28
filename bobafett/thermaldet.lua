-----------------------------------------------------------------
----- LOCALIZED FUNCTIONS ---------------------------------------
-----------------------------------------------------------------
local sins, coss, network_player_from_global_index, obj_mark_for_deletion, obj_spawn_loot_yellow_coins, mmx_play_sound,
 nearest_mario_state_to_object, obj_get_nearest_object_with_behavior_id, obj_check_hitbox_overlap, cur_obj_scale, obj_scale, network_send_object,
 atan2s, calculate_yaw, network_init_object =
  sins, coss, network_player_from_global_index, obj_mark_for_deletion, obj_spawn_loot_yellow_coins, mmx_play_sound,
  nearest_mario_state_to_object, obj_get_nearest_object_with_behavior_id, obj_check_hitbox_overlap, cur_obj_scale, obj_scale, network_send_object,
  atan2s, calculate_yaw, network_init_object


function assign_id_to_explosion(m)
    local mmx = gMmxStates[m.playerIndex]
    local i = 0
    while mmx.active_explosion_hitboxes[i] do
      i = i + 1
    end
    mmx.active_explosion_hitboxes[i] = {}
    network_send(true, { type = 'explosion_id_sync', id = i, m = gNetworkPlayers[m.playerIndex].globalIndex, remove = 0})
    return i
end

-----------------------------------------------------------------
-----------------------------------------------------------------
----- INTERACTIONS ----------------------------------------------
-----------------------------------------------------------------
-----------------------------------------------------------------

function spawn_shot_fx(o, shot_pos, clank)
    if (clank == 1) then
        mmx_play_sound(SOUND_CLANK_HIT, {x = o.oPosX, y = o.oPosY, z = o.oPosZ}, 0.4)  
    else
        mmx_play_sound(SOUND_SHOT_HIT, {x = o.oPosX, y = o.oPosY, z = o.oPosZ}, 0.5)
    end
    local posx = shot_pos.x - (shot_pos.x - o.oPosX) / 2
    local posy = shot_pos.y - (shot_pos.y - o.oPosY) / 2
    local posz = shot_pos.z - (shot_pos.z - o.oPosZ) / 2
    spawn_non_sync_object(id_bhvWallspark, E_model_shot_dmg, posx , posy , posz , function (obj)
        obj.oMoveAngleYaw = calculate_yaw(shot_pos, {x = o.oPosX, y = o.oPosY, z = o.oPosZ})
    end)
end

function spawn_destroy_explosion(o, size)
    spawn_non_sync_object(id_bhvWhitePuffSmoke2, E_MODEL_EXPLOSION, o.oPosX , o.oPosY + 20 * size, o.oPosZ , function(obj)
        obj_scale(obj, size)
    end)
    mmx_play_sound(SOUND_SHOT_DESTROY, {x = o.oPosX, y = o.oPosY, z = o.oPosZ}, 0.6)
end

--------
--NPCs--
--------

function leg_bomb_interact_bobomb_buddy(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    spawn_non_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, o.oPosX, o.oPosY, o.oPosZ, nil)
    obj_mark_for_deletion(o)
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
end

function leg_bomb_interact_srgeneral_npc(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    spawn_mist_particles()
    play_sound(SOUND_OBJ_DEFAULT_DEATH, o.header.gfx.cameraToObject)
    obj_mark_for_deletion(o)
end

function leg_bomb_interact_general_npc(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    spawn_mist_particles()
    play_sound(SOUND_OBJ_DEFAULT_DEATH, o.header.gfx.cameraToObject)
    obj_mark_for_deletion(o)
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
end

function leg_bomb_interact_mips(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    bhv_spawn_star_no_level_exit(o, o.oBehParams2ndByte + 3, true)
    spawn_mist_particles()
    play_sound(SOUND_OBJ_SWOOP_DEATH, o.header.gfx.cameraToObject)
    obj_mark_for_deletion(o)
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
end

function leg_bomb_interact_ukiki_cage(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if (o.oAction == UKIKI_CAGE_ACT_WAIT_FOR_UKIKI) then
        o.oAction = UKIKI_CAGE_ACT_FALL
        if o.oSyncID ~= 0 then
            network_send_object(o, false)
        end
    end
end

-------------------
--GENERAL ENEMIES--
-------------------

function leg_bomb_interact_srnormal(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if (o.oInteractStatus == ATTACK_FAST_ATTACK | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED) then
        return false
    end
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    o.oInteractStatus = ATTACK_PUNCH | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
    return true
end

function leg_bomb_interact_normal(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if (o.oInteractStatus == ATTACK_FAST_ATTACK | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED) then
        return false
    end
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    o.oInteractStatus = ATTACK_PUNCH | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_goomba(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    spawn_shot_fx(o, leg_bomb_pos, 0)
    if (o.oGoombaSize == GOOMBA_SIZE_HUGE) then
        spawn_non_sync_object(id_bhvMrIBlueCoin, E_MODEL_BLUE_COIN, o.oPosX, o.oPosY, o.oPosZ, nil)
        play_sound(SOUND_OBJ_ENEMY_DEATH_LOW, o.header.gfx.cameraToObject)
    else
        o.oNumLootCoins = 1
        obj_spawn_loot_yellow_coins(o, 1, 20.0)
        play_sound(SOUND_OBJ_ENEMY_DEATH_HIGH, o.header.gfx.cameraToObject)
    end
    spawn_destroy_explosion(o, 1)
    obj_mark_for_deletion(o)
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
end

function leg_bomb_interact_chuckya(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1.2)
        o.usingObj = nil
        obj_mark_for_deletion(o)
        obj_spawn_loot_yellow_coins(o, 5, 20.0)
        spawn_mist_particles_with_sound(SOUND_OBJ_CHUCKYA_DEATH)
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_enemygeneral(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if (o.oMmxHealth <= 0) or (o.oInteractStatus == ATTACK_FAST_ATTACK | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED) then
        return false
    end
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1)
        o.oInteractStatus = ATTACK_GROUND_POUND_OR_TWIRL | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_bigenemygeneral(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if (o.oMmxHealth <= 0) or (o.oInteractStatus == ATTACK_FAST_ATTACK | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED) then
        return false
    end
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1.2)
        o.oMmxHealth = o.oMmxInitialHealth
        o.oInteractStatus = ATTACK_GROUND_POUND_OR_TWIRL | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

-----------------------
--BOB-OMB BATTLEFIELD--
-----------------------

function leg_bomb_interact_bobomb(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if o.oAction == BOBOMB_ACT_EXPLODE then
        return false
    end
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1)
        o.oAction = BOBOMB_ACT_EXPLODE
        o.oMmxHealth = o.oMmxInitialHealth
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_srexplosion(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 2)
        spawn_mist_particles_with_sound(SOUND_GENERAL_WALL_EXPLOSION)
        spawn_triangle_break_particles(20, 138, 3, 4);
        obj_mark_for_deletion(o)
    end
    return true
end

function leg_bomb_interact_chainchomp(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 2)
        spawn_mist_particles_with_sound(SOUND_GENERAL_WALL_EXPLOSION)
        spawn_triangle_break_particles(20, 138, 3, 4);
        obj_mark_for_deletion(o)
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_waterbomb(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1)
        o.oAction = WATER_BOMB_ACT_EXPLODE
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_kingbobomb(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if (o.oFlags & OBJ_FLAG_HOLDABLE) == 0 or o.oAction == 8 or o.oAction == 7 then
        return false
    end
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1.5)
        o.oMoveFlags = OBJ_MOVE_LANDED
        o.oHealth = 0
        o.usingObj = nil
        o.oForwardVel = 0
        o.oVelY = 0
        o.oAction = 7
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_breakablebox(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1.2)
        o.oInteractStatus =  ATTACK_PUNCH | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_breakableboxsmall(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1)
        o.oInteractStatus = ATTACK_KICK_OR_TRIP | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED | INT_STATUS_STOP_RIDING
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_exclamationbox(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if o.oAction == 5 or o.oAction == 6 or o.oAction == 3 or o.oAction == 1 then
        return false
    end
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1)
        o.oInteractStatus = ATTACK_KICK_OR_TRIP | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
        o.oMmxHealth = o.oMmxInitialHealth
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_koopa(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if (o.oKoopaMovementType == KOOPA_BP_NORMAL or o.oKoopaMovementType == KOOPA_BP_UNSHELLED) then
        spawn_non_sync_object(id_bhvMrIBlueCoin, E_MODEL_BLUE_COIN, o.oPosX, o.oPosY, o.oPosZ, nil)
    end
    if (o.oKoopaMovementType ~= KOOPA_BP_UNSHELLED and o.oBehParams2ndByte ~= KOOPA_BP_TINY) then
        spawn_non_sync_object(id_bhvKoopaShell, E_MODEL_KOOPA_SHELL, o.oPosX, o.oPosY, o.oPosZ, nil)
    end
    spawn_mist_particles_with_sound(SOUND_OBJ_KOOPA_DAMAGE)
    obj_mark_for_deletion(o)
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

--------------------
--WHOMP'S FORTRESS--
--------------------

function leg_bomb_interact_breakablewall(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if o.oMmxHealth <= 0 then
        return false
    end
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1.5)
        spawn_mist_particles_with_sound(SOUND_GENERAL_WALL_EXPLOSION)
        --obj_explode_and_spawn_coins(80, 0)
        obj_mark_for_deletion(o)
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_bridge(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if not (o.oFaceAnglePitch > -0x4000) then
        return false
    end
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1.2)
        o.oAction = 2
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_whomp(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1.2)
        o.oNumLootCoins = 5
        obj_spawn_loot_yellow_coins(o, 5, 20.0)
        o.oAction = 8
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_whompking(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if o.oAction == 8 or o.oAction == 0 or o.oAction == 9 then
        return false
    end
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 2)
        play_sound(SOUND_OBJ2_WHOMP_SOUND_SHORT, o.header.gfx.cameraToObject)
        play_sound(SOUND_OBJ_KING_WHOMP_DEATH, o.header.gfx.cameraToObject)
        o.oHealth = 0
        o.oMoveFlags = OBJ_MOVE_ON_GROUND
        o.oForwardVel = 0
        o.oAction = 8
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_piranhaplant(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if o.oAction == PIRANHA_PLANT_ACT_SHRINK_AND_DIE 
    or o.oAction == PIRANHA_PLANT_ACT_ATTACKED or o.oAction == PIRANHA_PLANT_ACT_WAIT_TO_RESPAWN then
        return false
    end
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1)
        stop_secondary_music(50)
        o.oAction = PIRANHA_PLANT_ACT_ATTACKED
        o.oMmxHealth = o.oMmxInitialHealth
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_bulletbill(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if o.oAction == 3 or o.oAction == 4 then
        return false
    end
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1.2)
        o.oAction = 3
        spawn_non_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, o.oPosX, o.oPosY, o.oPosZ, nil)
        o.oMmxHealth = o.oMmxInitialHealth
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

----------------------
--COOL COOL MOUNTAIN--
----------------------

function leg_bomb_interact_mrblizzard(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if o.oAction == MR_BLIZZARD_ACT_DEATH then
        return false
    end
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1)
        o.oAction = MR_BLIZZARD_ACT_DEATH
        o.oMmxHealth = o.oMmxInitialHealth
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

----------------------
--BIG BOO'S HUNT------
----------------------
function leg_bomb_interact_boo(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if (o.oMmxHealth <= 0) or (o.oInteractStatus == ATTACK_FAST_ATTACK | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED) then
        return false
    end
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1)
        if o.oHealth > 1 then
            o.oMmxHealth = o.oMmxInitialHealth
        end
        o.oAction = 3
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

----------------------
--SHIFTING SAND LAND--
----------------------
function leg_bomb_interact_klepto(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if o.oInteractStatus == ATTACK_FROM_ABOVE | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED | INT_STATUS_STOP_RIDING then
        return false
    end
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1)
        o.oInteractStatus = ATTACK_FROM_ABOVE | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED | INT_STATUS_STOP_RIDING
        o.oMmxHealth = o.oMmxInitialHealth
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_jumping_box(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1)
        o.oInteractStatus = INT_STATUS_STOP_RIDING
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_eyerokhand(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if o.oAction == EYEROK_HAND_ACT_DIE or o.oAction == EYEROK_HAND_ACT_DEAD then
        return false
    end
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1)
        o.oInteractStatus = INT_STATUS_STOP_RIDING
        o.parentObj.oEyerokBossNumHands = o.parentObj.oEyerokBossNumHands - 1
        o.oAction = EYEROK_HAND_ACT_DIE
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

--------------------
--LETHAL LAVA LAND--
--------------------
function leg_bomb_interact_mri(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if o.oAction == 3 then
        return false
    end
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1)
        o.oAction = 3
        o.oTimer = 104
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_bully(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    o.oMoveAngleYaw = calculate_yaw(leg_bomb_pos, {x = o.oPosX, y = o.oPosY, z = o.oPosZ})
    spawn_shot_fx(o, leg_bomb_pos, 1)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    o.oInteractStatus = ATTACK_FAST_ATTACK | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
    o.oForwardVel = 50
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

---------------------
---TINY HUGE ISLAND--
---------------------

function leg_bomb_interact_spiny(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1)
        spawn_mist_particles()
        play_sound(SOUND_OBJ_DEFAULT_DEATH, o.header.gfx.cameraToObject)
        o.oNumLootCoins = 1
        obj_spawn_loot_yellow_coins(o, 1, 20.0);
        obj_mark_for_deletion(o)
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_firepiranhaplant(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if o.oAction == FIRE_PIRANHA_PLANT_ACT_HIDE then
        return false
    end
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1)
        o.oInteractStatus = ATTACK_FAST_ATTACK | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
        o.oMmxHealth = o.oMmxInitialHealth
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_wigglerhead(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if o.oIntangibleTimer < 0 then
        return false
    end
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1)
        o.oInteractStatus = ATTACK_FROM_ABOVE | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED | INT_STATUS_STOP_RIDING
        o.oMmxHealth = o.oMmxInitialHealth
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

------------------------
---TALL TALL MOUNTAIN---
------------------------

function leg_bomb_interact_monty_mole(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if o.oAction == MONTY_MOLE_ACT_SELECT_HOLE and 
    o.oInteractStatus == ATTACK_FAST_ATTACK | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED then
        return false
    end
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_destroy_explosion(o, 1)
        o.oInteractStatus = ATTACK_FAST_ATTACK | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
        o.oMmxHealth = o.oMmxInitialHealth
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

----------------------------
--BOWSER IN THE DARK WORLD--
----------------------------

function leg_bomb_interact_bowser(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    if o.oAction == 19 or o.oAction == 5 or o.oAction == 6 or o.oAction == 4 or o.oAction == 1 then
        return false
    end
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        o.oHealth = o.oHealth - 1
        spawn_destroy_explosion(o, 1.8)
        if o.oHealth <= 0 then
            o.oAction = 4
        else
            o.oMmxHealth = o.oMmxInitialHealth
            o.oAction = 12
        end
        o.oMoveFlags = 0
        o.oForwardVel = 0
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end

function leg_bomb_interact_bowser_bomb(o, leg_bomb_id, leg_bomb_dmg, leg_bomb_pos, playerIndex)
    o.oMmxHealth = o.oMmxHealth - leg_bomb_dmg
    spawn_shot_fx(o, leg_bomb_pos, 0)
    local mmx = gMmxStates[playerIndex]
    if mmx.active_explosion_hitboxes[leg_bomb_id] ~= nil and not mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] then
        mmx.active_explosion_hitboxes[leg_bomb_id][o.oSyncID] = true
    end
    if (o.oMmxHealth <= 0) then
        spawn_non_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, o.oPosX, o.oPosY, o.oPosZ, nil)
        obj_mark_for_deletion(o)
    end
    if o.oSyncID ~= 0 then
        network_send_object(o, false)
    end
    return true
end


-----------------------------------------------------------------
-----------------------------------------------------------------
----- INTERACTIONS HANDLING -------------------------------------
-----------------------------------------------------------------
-----------------------------------------------------------------

explosionhurtableenemy = {
    -- NPCs
    [id_bhvBobombBuddy] = leg_bomb_interact_bobomb_buddy,
    [id_bhvBobombBuddyOpensCannon] = leg_bomb_interact_bobomb_buddy,
    [id_bhvToadMessage] = leg_bomb_interact_general_npc,
    [id_bhvYoshi] = leg_bomb_interact_general_npc,
    [id_bhvUkiki] = leg_bomb_interact_general_npc,
    [id_bhvHoot] = leg_bomb_interact_general_npc,
    [id_bhvPenguinBaby] = leg_bomb_interact_general_npc,
    [id_bhvSmallPenguin] = leg_bomb_interact_general_npc,
    [id_bhvSLWalkingPenguin] = leg_bomb_interact_general_npc,
    [id_bhvTuxiesMother] = leg_bomb_interact_general_npc,
    [id_bhvRacingPenguin] = leg_bomb_interact_general_npc,
    [id_bhvMips] = leg_bomb_interact_mips,
    [id_bhvUkikiCage] = leg_bomb_interact_ukiki_cage,
    -- BOB
    [id_bhvGoomba] = leg_bomb_interact_goomba, 
    [id_bhvKoopa] = leg_bomb_interact_koopa,
    [id_bhvBobomb] = leg_bomb_interact_bobomb,
    [id_bhvChainChomp] = leg_bomb_interact_chainchomp,
    [id_bhvChainChompGate] = leg_bomb_interact_chainchomp,
    [id_bhvWaterBomb] = leg_bomb_interact_waterbomb,
    [id_bhvKingBobomb] = leg_bomb_interact_kingbobomb,
    [id_bhvBreakableBox] = leg_bomb_interact_breakablebox,
    [id_bhvBreakableBoxSmall] = leg_bomb_interact_breakableboxsmall,
    [id_bhvExclamationBox] = leg_bomb_interact_exclamationbox,
    [id_bhvBowlingBall] = leg_bomb_interact_chainchomp,
    [id_bhvPitBowlingBall] = leg_bomb_interact_chainchomp,
    [id_bhvFreeBowlingBall] = leg_bomb_interact_chainchomp,
    -- WF
    [id_bhvKickableBoard] = leg_bomb_interact_bridge,
    [id_bhvWfBreakableWallLeft] = leg_bomb_interact_breakablewall,
    [id_bhvWfBreakableWallRight] = leg_bomb_interact_breakablewall,
    [id_bhvSmallWhomp] = leg_bomb_interact_whomp,
    [id_bhvWhompKingBoss] = leg_bomb_interact_whompking,
    [id_bhvPiranhaPlant] = leg_bomb_interact_piranhaplant,
    [id_bhvBulletBill] = leg_bomb_interact_bulletbill,
    -- CM
    [id_bhvSpindrift] = leg_bomb_interact_enemygeneral,
    [id_bhvMrBlizzard] = leg_bomb_interact_mrblizzard,
    -- BBH
    [id_bhvBoo] = leg_bomb_interact_boo,
    [id_bhvGhostHuntBoo] = leg_bomb_interact_boo,
    [id_bhvFlyingBookend] = leg_bomb_interact_enemygeneral,
    [id_bhvHauntedChair] = leg_bomb_interact_enemygeneral,
    [id_bhvBooWithCage] = leg_bomb_interact_boo,
    [id_bhvBookSwitch] = leg_bomb_interact_normal,
    [id_bhvMerryGoRoundBoo] = leg_bomb_interact_boo,
    [id_bhvBalconyBigBoo] = leg_bomb_interact_boo,
    [id_bhvGhostHuntBigBoo] = leg_bomb_interact_boo,
    [id_bhvMerryGoRoundBigBoo] = leg_bomb_interact_boo,
    [id_bhvMadPiano] = leg_bomb_interact_chainchomp,
    -- LLL
    [id_bhvMrI] = leg_bomb_interact_mri,
    [id_bhvSmallBully] = leg_bomb_interact_bully,
    [id_bhvBigBully] = leg_bomb_interact_bully,
    [id_bhvBigBullyWithMinions] = leg_bomb_interact_bully,
    -- SSL
    [id_bhvPokey] = leg_bomb_interact_enemygeneral,
    [id_bhvPokeyBodyPart] = leg_bomb_interact_enemygeneral,
    [id_bhvKlepto] = leg_bomb_interact_klepto,
    [id_bhvFlyGuy] = leg_bomb_interact_enemygeneral,
    [id_bhvEyerokHand] = leg_bomb_interact_eyerokhand,
    [id_bhvJumpingBox] = leg_bomb_interact_jumping_box,
    -- HMC
    [id_bhvScuttlebug] = leg_bomb_interact_enemygeneral,
    [id_bhvSnufit] = leg_bomb_interact_enemygeneral,
    [id_bhvSwoop] = leg_bomb_interact_enemygeneral,
    [id_bhvBigBoulder] = leg_bomb_interact_chainchomp,
    -- THI
    [id_bhvFirePiranhaPlant] = leg_bomb_interact_firepiranhaplant,
    [id_bhvChuckya] = leg_bomb_interact_chuckya,
    [id_bhvEnemyLakitu] = leg_bomb_interact_enemygeneral,
    [id_bhvSpiny] = leg_bomb_interact_spiny,
    [id_bhvWigglerHead] = leg_bomb_interact_wigglerhead,
    -- TTM
    [id_bhvMontyMole] = leg_bomb_interact_monty_mole,
    -- WDW
    [id_bhvSkeeter] = leg_bomb_interact_enemygeneral,
    -- SL
    [id_bhvSmallChillBully] = leg_bomb_interact_bully,
    [id_bhvBigChillBully] = leg_bomb_interact_bully,
    [id_bhvMoneybag] = leg_bomb_interact_enemygeneral,
    -- BOWSER
    [id_bhvBowser] = leg_bomb_interact_bowser,
    [id_bhvBowserBomb] = leg_bomb_interact_bowser_bomb,
}

local displacedhitboxes = {
    [id_bhvSnufit] = true,
    [id_bhvSwoop] = true
}

function explosionattack(obj, playerIndex)
    local hurtenemy = false
    local enemyobj

    local actualtable = explosionhurtableenemy
    -- Detect if SR enemies are present
    if (bhvSMSRShyGuy) then
        actualtable[bhvSMSRSmallBee] = leg_bomb_interact_srnormal
        actualtable[bhvSMSRShyGuy] = leg_bomb_interact_srnormal
        actualtable[bhvSMSRAttractedSpaceBox] = leg_bomb_interact_srexplosion
        actualtable[bhvSMSRYoshi] = leg_bomb_interact_srgeneral_npc
        actualtable[bhvSMSRPeachMessage] = leg_bomb_interact_srgeneral_npc
    end

    local mmx = gMmxStates[playerIndex]
    
    for key,value in pairs(actualtable) do --actualtable is a table of enemies that can be hurt by explosions with each enemy stored by behaviorid
        enemyobj = obj_get_nearest_object_with_behavior_id(obj,key) --get nearest hitable obj
        if enemyobj ~= nil and 
        ((obj_check_hitbox_overlap(obj, enemyobj) and not displacedhitboxes[key]) 
        or (obj_check_overlap_with_hitbox_params(obj, enemyobj.oPosX, enemyobj.oPosY, enemyobj.oPosZ, enemyobj.hitboxHeight, enemyobj.hitboxRadius, 50) and displacedhitboxes[key])) then
            hurtenemy = true --obj hit enemyobj
            if actualtable[key] and (mmx.active_explosion_hitboxes[obj.oUnkC0] ~= nil and not mmx.active_explosion_hitboxes[obj.oUnkC0][enemyobj.oSyncID]) then
                local explosionPos = {x = obj.oPosX, y = obj.oPosY, z = obj.oPosZ}
                set_health_for_overridden(enemyobj, key)
                actualtable[key](enemyobj, obj.oUnkC0, 7, explosionPos, playerIndex)
            end
        end
    end
    return hurtenemy
end

function explosion_check_interact_other_players(obj)
    local np = network_player_from_global_index(obj.oOwner)
    local m = gMarioStates[np.localIndex]
    local player = nearest_mario_state_to_object(obj)
    if player ~= nil and obj_check_hitbox_overlap(obj, player.marioObj) and player.playerIndex ~= m.playerIndex then
        if _G.HideAndSeek then
            if _G.HideAndSeek.is_player_seeker(m.playerIndex) and not _G.HideAndSeek.is_player_seeker(player.playerIndex) then
                _G.HideAndSeek.set_player_seeker(player.playerIndex, true)
            end
        end
    end
end

function spawn_bomb(m, grounded, id)
    mmx_play_sound(SOUND_VILE_NAPALM_SHOT, m.pos, 0.47)
    local mGfx = m.marioObj.header.gfx
    local angl = m.faceAngle.y - 6000
    if (grounded) then
        spawn_non_sync_object(id_bhvLegNapalm, E_model_leg_napalm, mGfx.pos.x + sins(angl) * 50, mGfx.pos.y + 10, mGfx.pos.z + coss(angl) * 50 , function(obj)
            obj.oMoveAngleYaw = m.faceAngle.y
            obj.Owner = network_global_index_from_local(m.playerIndex)
            obj.oForwardVel = 90
            obj.oVelY = 25
        end)
    else
        spawn_non_sync_object(id_bhvLegNapalm, E_model_leg_napalm, mGfx.pos.x + sins(angl) * 50, mGfx.pos.y + 10, mGfx.pos.z + coss(angl) * 50 , function(obj)
            obj.oMoveAngleYaw = m.faceAngle.y
            obj.Owner = network_global_index_from_local(m.playerIndex)
            obj.oForwardVel = 90
            obj.oVelY = 10
        end)
    end
end

-----------------------------------------------------------------
-----------------------------------------------------------------
----- BEHAVIORS -------------------------------------------------
-----------------------------------------------------------------
-----------------------------------------------------------------

--- LEG NAPALM
local leg_napalm_init = function(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oBuoyancy = 3.5
    obj_scale(o, 0.7)
    o.oGraphYOffset = 20
    o.oGravity = 5
    o.oFriction = 0.8
end

local leg_napalm_loop = function(o)
    if o.oTimer < 18 then
        object_step()
    end
    if o.oTimer == 18 then
        cur_obj_hide()
        spawn_non_sync_object(id_bhvWhitePuffSmoke2, E_MODEL_BOWSER_FLAMES, o.oPosX , o.oPosY + 20 , o.oPosZ, function(obj)
            obj.header.gfx.scale.x = 2.5
            obj.header.gfx.scale.y = 6
            obj.header.gfx.scale.z = 2.5
            obj.oOpacity = 200
        end)
    end
    local np = network_player_from_global_index(o.oOwner)
    local m = gMarioStates[np.localIndex]
    
    if o.oTimer >= 20 then
        
        spawn_non_sync_object(id_bhvLegNapalmExplosion, E_MODEL_EXPLOSION, o.oPosX, o.oPosY, o.oPosZ, function(obj)
            obj.oOwner = o.oOwner
            obj.oUnkC0 = o.oUnkC0
        end)
        
        obj_mark_for_deletion(o)
    end
    
end

-- LEG NAPALM EXPLOSION
local leg_napalm_explosion_init = function(o)
    local np = network_player_from_global_index(o.oOwner)
    local m = gMarioStates[np.localIndex]
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.header.gfx.node.flags = o.header.gfx.node.flags | GRAPH_RENDER_BILLBOARD
    --create_sound_spawner(o, SOUND_GENERAL2_BOBOMB_EXPLOSION)
    mmx_play_sound(SOUND_VILE_NAPALM_EXPLODE, {x = o.oPosX, y = o.oPosY, z = o.oPosZ}, 0.75)
    set_environmental_camera_shake(SHAKE_ENV_EXPLOSION)
    for i = 0, 8, 1 do
        local angle = 8192 * i
        spawn_non_sync_object(id_bhvWhitePuffSmoke2, E_MODEL_EXPLOSION, o.oPosX + 150 * sins(angle), o.oPosY + 50, o.oPosZ + 150 * coss(angle), function(obj)
            obj.header.gfx.scale.x = 0.5
            obj.header.gfx.scale.y = 0.5
            obj.header.gfx.scale.z = 0.5
            obj.oOpacity = 200
        end)
    end
    spawn_non_sync_object(id_bhvWhitePuffSmoke2, E_MODEL_EXPLOSION, o.oPosX, o.oPosY, o.oPosZ, function(obj)
        obj.header.gfx.scale.x = 1.3
        obj.header.gfx.scale.y = 1.1
        obj.header.gfx.scale.z = 1.3
        obj.oOpacity = 200
    end)
    o.oOpacity = 255
    o.header.gfx.scale.x = 1.7
    o.header.gfx.scale.y = 2.3
    o.header.gfx.scale.z = 1.7
    if (m.playerIndex ~= 0 and gServerSettings.playerInteractions ~= PLAYER_INTERACTIONS_NONE) then
        -- CHANGE THIS
        o.oIntangibleTimer = 3
        o.oInteractType = INTERACT_DAMAGE
        if gServerSettings.playerInteractions == PLAYER_INTERACTIONS_PVP then
            o.oDamageOrCoinValue = 3
        end
    end
    o.hitboxRadius            = 320
    o.hitboxHeight            = 620
    o.hitboxDownOffset        = 200
    o.oGraphYOffset = 200
end

local leg_napalm_explosion_loop = function(o)
    o.header.gfx.scale.x = 1.1
    o.header.gfx.scale.y = 1.45
    o.header.gfx.scale.z = 1.1

    explosion_check_interact_other_players(o)

    local np = network_player_from_global_index(o.oOwner)
    local m = gMarioStates[np.localIndex]
    local mmx = gMmxStates[m.playerIndex]

    if (o.oTimer > 2) then
        explosionattack(o, m.playerIndex)
    end
    o.oAnimState = o.oAnimState + 1
    if (o.oTimer == 9) then
        if (find_water_level(o.oPosX, o.oPosZ) > o.oPosY) then
            for i = 0, 40, 1 do 
                --spawn_object(o, MODEL_WHITE_PARTICLE_SMALL, bhvBobombExplosionBubble)
                spawn_non_sync_object(id_bhvBobombExplosionBubble, E_MODEL_WHITE_PARTICLE_SMALL, o.oPosX, o.oPosY, o.oPosZ, nil)
            end                
        else
            --spawn_object(o, MODEL_SMOKE, bhvBobombBullyDeathSmoke)
            spawn_non_sync_object(id_bhvBobombBullyDeathSmoke, E_MODEL_SMOKE, o.oPosX, o.oPosY + 200, o.oPosZ, nil)
        end
        o.activeFlags = ACTIVE_FLAG_DEACTIVATED
        if m.playerIndex == 0 then
            mmx.active_explosion_hitboxes[o.oUnkC0] = nil
            network_send(true, { type = 'explosion_id_sync', id = o.oUnkC0, m = o.oOwner, remove = 1})
        end
        obj_mark_for_deletion(o)
    end

    o.oOpacity = o.oOpacity - 14

    cur_obj_scale(o.oTimer / 9.0 + 1.0)

    if mmx.active_explosion_hitboxes[o.oUnkC0] == nil then
        obj_mark_for_deletion(o)
    end
end

----------------------------
--BEHAVIORS REGISTRY--------
----------------------------
id_bhvLegNapalm = hook_behavior(nil, OBJ_LIST_GENACTOR, false, leg_napalm_init, leg_napalm_loop)
id_bhvLegNapalmExplosion = hook_behavior(nil, OBJ_LIST_GENACTOR, false, leg_napalm_explosion_init, leg_napalm_explosion_loop)