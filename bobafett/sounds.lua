local bobaVoiceTable = {
    [CHAR_SOUND_ATTACKED] = 'bobaGrunt.wav',
    [CHAR_SOUND_DOH] = 'bobaGrunt.wav',
    [CHAR_SOUND_DROWNING] = 'bobaDeath.wav',
    [CHAR_SOUND_DYING] = 'bobaDeath.wav',
--    [CHAR_SOUND_EEUH] = 'bw_jump0.ogg',
    [CHAR_SOUND_GROUND_POUND_WAH] = 'bobaGrunt.wav',
--    [CHAR_SOUND_HAHA] = 'bw_haha.ogg',
--    [CHAR_SOUND_HAHA_2] = 'bw_haha.ogg',
--    [CHAR_SOUND_HERE_WE_GO] = 'bw_herewego.ogg',
--    [CHAR_SOUND_HOOHOO] = 'bw_doublejump.ogg',
    [CHAR_SOUND_HRMM] = 'bobaGrunt.wav',
--    [CHAR_SOUND_MAMA_MIA] = 'bw_mamamia.ogg',
    [CHAR_SOUND_LETS_A_GO] = 'thermDetExplosion.wav',
--    [CHAR_SOUND_ON_FIRE] = 'bw_hothot.ogg',
    [CHAR_SOUND_OOOF] = 'bobaGrunt.wav',
    [CHAR_SOUND_OOOF2] = 'bobaGrunt.wav',
--    [CHAR_SOUND_PUNCH_HOO] = 'bw_attack2.ogg',
--    [CHAR_SOUND_PUNCH_WAH] = 'bw_jump1.ogg',
--    [CHAR_SOUND_PUNCH_YAH] = 'bw_attack1.ogg',
--    [CHAR_SOUND_SO_LONGA_BOWSER] = 'bw_haha.ogg',
--    [CHAR_SOUND_TWIRL_BOUNCE] = 'bw_wahoo1.ogg',
    [CHAR_SOUND_UH2] = 'bobaGrunt.wav',
--    [CHAR_SOUND_WAAAOOOW] = 'bw_falling.ogg',
--    [CHAR_SOUND_WAH2] = 'bw_attack2.ogg',
    [CHAR_SOUND_WHOA] = 'bobaGrunt.wav',
--    [CHAR_SOUND_YAHOO] = 'bw_wahoo1.ogg',
--    [CHAR_SOUND_YAHOO_WAHA_YIPPEE] = {'bw_wahoo0.ogg', 'bw_wahoo1.ogg'},
--    [CHAR_SOUND_YAH_WAH_HOO] = {'bw_jump0.ogg', 'bw_jump1.ogg'},

}

if _G.charSelectExists then

    _G.charSelect.character_add_voice(E_MODEL_BOBAFETT_PLAYER, bobaVoiceTable)
    hook_event(HOOK_CHARACTER_SOUND, function (m, sound)
        if _G.charSelect.character_get_voice(m) == bobaVoiceTable then return _G.charSelect.voice.sound(m, sound) end
    end)
    hook_event(HOOK_MARIO_UPDATE, function (m)
        if _G.charSelect.character_get_voice(m) == bobaVoiceTable then return _G.charSelect.voice.snore(m) end
    end)
end
