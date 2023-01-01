script_name('MP3Player')
script_properties('work-in-pause')
--req
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local action = require('moonloader').audiostream_state
local imgui = require 'imgui'
local fa = require 'fAwesome5'
local effil = require 'effil'
local VK = require "vkeys"
--req

--peremen
local fa_font = nil
local fa_font2 = nil
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
--bool
local menu = imgui.ImBool(false)
local menu_helo = imgui.ImBool(false)
local menu_helo_active = imgui.ImBool(false)

local Vidjet = imgui.ImBool(false)
local Vidjet_buttons = imgui.ImBool(false)
local Vidjet_music_name = imgui.ImBool(false)
local Vidjet_alpha = imgui.ImBool(false)
local Vidjet_Size = imgui.ImBool(false)
local Vidjet_Drop = imgui.ImBool(false)

local Radio_Edit = imgui.ImBool(false)
local Playlist_Create = imgui.ImBool(false)
local mute = imgui.ImBool(false)
local pause = imgui.ImBool(false)
local sync = imgui.ImBool(false)
local random = imgui.ImBool(false)
--buffer
local radio_name = imgui.ImBuffer(128)
local radio_link = imgui.ImBuffer(2048)
local mus_Path = imgui.ImBuffer(1024)
local PlayName = imgui.ImBuffer(128)
local FindMusic = imgui.ImBuffer(128)
local FindMyMusic = imgui.ImBuffer(128)
--float
local volume = imgui.ImFloat(0.5)
local Vidjet_Alpha_float = imgui.ImFloat(0.5)
local Vidjet_Size_float = imgui.ImFloat(75)
local Vidjet_Drop_Width = imgui.ImFloat(330)
--other
local fontsize = nil
local menu_selected = 0
local AudioHandle
local Playlist = ''
local Sel = ''
local Musics = {}
local PlaySelect = ''
local Type = ''
local tracks = {}
local link = ''
local MusicName = ''
local SizeY = 75
local next = 0
local Playing = '' -- какой плейлист сейчас играет

--peremen

--config 
local Config = {
    ['Settings'] = {
        ['Path'] = 'moonloader/resource/MP3Player',
        ['Vidjet'] = {['Active'] = false, ['Drop'] = false, ['Buttons'] = false, ['MusicName'] = false, ['AlphaEnable'] = false, ['Alpha'] = 0.5, ['Size'] = false, ['SizeY'] = 75, ['RandomMusic'] = false},
        ['HelloMenu'] = true,
        ['Volume'] = 0.5,
    },
    ['Radio'] = {
        {'Europa top 40','http://eptop128.streamr.ru'},
        {'Rezidence','http://mp3128.residance.streamr.ru'},
        {'New','http://mp3128.new.streamr.ru'},
        {'Light','http://mp3128.light.streamr.ru'},
        {'Millennium Radio','http://s0.radioheart.ru:8000/RH62990'},
        {'Радио SP12','https://myradio24.org/5894'},
        {'Радио Cassiopeia Station (Наука)','https://stream.cassiopeia-station.ru:1095/stream'},
        {'Kids FM','http://prmstrm.1.fm:8000/kidsfm'},
        {'Absolute TOP 40 Radio','http://prmstrm.1.fm:8000/top40'},
        {'Absolute 90s','http://prmstrm.1.fm:8000/90s'},
        {'Absolute Country Hits','http://prmstrm.1.fm:8000/acountry'},
        {'Absolute Trance','http://prmstrm.1.fm:8000/trance'},
        {'All Euro 80s','http://prmstrm.1.fm:8000/80s_90s'},
        {'Fun Radio','http://stream.funradio.sk:8000/fun192.mp3'},
        {'A List 80s','http://prmstrm.1.fm:8000/back280s'},
        {'Deep House','http://prmstrm.1.fm:8000/deephouse'},
    },
}
local ConfigPlaylist = {
    ['Songs'] = {
        {'Europa top 40','http://eptop128.streamr.ru'}
    }
}
local ConfigPlaylistDefault = {
    ['Songs'] = {
        {'Europa top 40','http://eptop128.streamr.ru'}
    }
}
if not doesDirectoryExist('moonloader/resource/MP3Player') then createDirectory('moonloader/resource/MP3Player') end
if not doesDirectoryExist('moonloader/resource/MP3Player/Playlists/') then createDirectory('moonloader/resource/MP3Player/Playlists/') end
if not doesFileExist("moonloader/resource/MP3Player/" .. thisScript().name .. ".json") then
    local f = io.open("moonloader/resource/MP3Player/" .. thisScript().name .. ".json", "w")
    f:write(encodeJson(Config))
    f:close()   
    local f = io.open("moonloader/resource/MP3Player/" .. thisScript().name .. ".json", 'r')
    if f then
        Config = decodeJson(f:read('*a'))
    end
else
    local f = io.open("moonloader/resource/MP3Player/" .. thisScript().name .. ".json", 'r')
    if f then
       Config = decodeJson(f:read('*a'))
    end
    f:close()
end
function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end
	wait(100)
    LoadSaves()

	sampRegisterChatCommand("mp3p", function() menu.v = not menu.v end)

	sampAddChatMessage('{FF5656}[MP3 Player 2.0 ]: {FFFFFF}Загружен! Автор: UBP', -1)
	while true do 
		wait(0)
        imgui.Process = menu.v or menu_helo_active.v or Vidjet.v
        if AudioHandle ~= nil then
            state = getAudioStreamState(AudioHandle)
        end
        if random.v == false then
            if state == -1 and Type == 'Music' and sync.v == false then 
                local files = getFilesInPath(Config['Settings']['Path'], '*.mp3')
                if files[select+1] ~= nil then
                    playSound(Config['Settings']['Path']..'/'..files[select+1])
                    MusicName = files[select+1]
                    select=select+1
                elseif files[select+1] == nil then 
                    playSound(Config['Settings']['Path']..'/'..files[1])
                    MusicName = files[1]
                    select=1
                end
            elseif state == -1 and Type == 'PlayList' and sync.v == false then 
                if ConfigPlaylist['Songs'][select+1] ~= nil then 
                    playSound(ConfigPlaylist['Songs'][select+1][2])
                    MusicName = ConfigPlaylist['Songs'][select+1][1]
                    select = select+1
                elseif ConfigPlaylist['Songs'][select+1] == nil  then
                    select = 0 
                    playSound(ConfigPlaylist['Songs'][1][2])
                    MusicName = ConfigPlaylist['Songs'][1][1]
                end              
            elseif state == -1 and Type == 'Search' and sync.v == false then 
                if tracks[select+1] ~= nil and tracks[select+1]..'.mp3' ~= nil then
                    print(tracks[select+1]..'.mp3')
                    playSound(tracks[select+1]..'.mp3')   
                    MusicName = tracks[select+1]..'.mp3'
                    select=select+1    
                end       
            end
        else 
            if state == -1 and Type == 'Music' and sync.v == false then 
                local files = getFilesInPath(Config['Settings']['Path'], '*.mp3')
                local randseed = math.random(1,#files)
                if files[randseed] ~= nil then
                    playSound(Config['Settings']['Path']..'/'..files[randseed])
                    MusicName = files[randseed]
                    select=randseed
                elseif files[randseed1] == nil then 
                    playSound(Config['Settings']['Path']..'/'..files[1])
                    MusicName = files[1]
                    select=1
                end
            elseif state == -1 and Type == 'PlayList' and sync.v == false then 
                local randseed = math.random(1,#ConfigPlaylist['Songs'])
                if ConfigPlaylist['Songs'][randseed] ~= nil then 
                    playSound(ConfigPlaylist['Songs'][randseed][2])
                    MusicName = ConfigPlaylist['Songs'][randseed][1]
                elseif ConfigPlaylist['Songs'][randseed] == nil  then
                    select = 0 
                    playSound(ConfigPlaylist['Songs'][1][2])
                    MusicName = ConfigPlaylist['Songs'][1][1]
                end              
            elseif state == -1 and Type == 'Search' and sync.v == false then 
                local randseed = math.random(1,#tracks)
                playSound(tracks[randseed]..'.mp3')   
                select=select+1 
                MusicName = tracks[randseed]..'.mp3'           
            end            
        end
	end
end
function getFilesInPath(path, ftype)
    local Files, SearchHandle, File = {}, findFirstFile(path.."\\"..ftype)
    table.insert(Files, File)
    while File do File = findNextFile(SearchHandle) table.insert(Files, File) end
    return Files
end
local files = getFilesInPath(Config['Settings']['Path'], '*.mp3')
function imgui.BeforeDrawFrame()
    if isKeyDown(VK_MENU) then imgui.ShowCursor = true else imgui.ShowCursor = menu.v or menu_helo_active.v end
    if fa_font == nil then
        local font_config = imgui.ImFontConfig()
        font_config.MergeMode = true
        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fa-solid-900.ttf', 13.0, font_config, fa_glyph_ranges)
    end
    if fa_font2 == nil then
        local font_config = imgui.ImFontConfig()
        font_config.MergeMode = false
        fa_font2 = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fa-solid-900.ttf', 100.0, font_config, fa_glyph_ranges)
    end
    if fontsize == nil then
        fontsize = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 25.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic()) -- вместо 30 любой нужный размер
    end
end
function imgui.OnDrawFrame()
    local sw, sh = getScreenResolution()
    if Vidjet.v and AudioHandle ~= nil and Vidjet_Drop.v == true then 
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 1.064), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(Vidjet_Drop_Width.v, 30))
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.11, 0.15, 0.17, 0))
        imgui.Begin(u8' Виджет2 ', Vidjet,imgui.WindowFlags.NoCollapse+imgui.WindowFlags.NoResize+imgui.WindowFlags.NoTitleBar) 
        if Vidjet_music_name.v then 
            if Type == 'Radio' then
                imgui.CenterText(fa.ICON_FA_MUSIC..u8(' Играет: ')..MusicName)
            else 
                imgui.PushItemWidth(100)
                imgui.Text(fa.ICON_FA_MUSIC..u8(' Играет: ')..MusicName)
            end
            Hovered(MusicName)
        end
        imgui.End()
        imgui.PopStyleColor()
    end
    if Vidjet.v and AudioHandle ~= nil then 
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 1.064), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(330, Vidjet_Size_float.v))
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.11, 0.15, 0.17, Vidjet_Alpha_float.v))
        imgui.Begin(u8' Виджет ', Vidjet,imgui.WindowFlags.NoCollapse+imgui.WindowFlags.NoResize+imgui.WindowFlags.NoTitleBar) 
        if Vidjet_music_name.v and Vidjet_Drop.v == false then 
            if Type == 'Radio' then
                imgui.CenterText(fa.ICON_FA_MUSIC..u8(' Играет: ')..MusicName)
            else 
                imgui.PushItemWidth(100)
                imgui.Text(fa.ICON_FA_MUSIC..u8(' Играет: ')..MusicName)
            end
            Hovered(MusicName)
        end
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.11, 0.15, 0.17, Vidjet_Alpha_float.v))
        if Vidjet_buttons.v == true then 
            SizeY = 75
            if sync.v == false then 
                if imgui.Button(fa.ICON_FA_SYNC,imgui.ImVec2(40, 30)) then sync.v = true if AudioHandle ~= nil then  setAudioStreamLooped(AudioHandle, sync.v) end  end
                Hovered('Зациклить')
            else 
                if imgui.Button(fa.ICON_FA_SYNC_ALT,imgui.ImVec2(40, 30)) then sync.v = false if AudioHandle ~= nil then  setAudioStreamLooped(AudioHandle, sync.v) end  end
                Hovered('Без зацикливания')
            end
            imgui.SameLine()
            if imgui.Button(fa.ICON_FA_BACKWARD,imgui.ImVec2(65, 30)) then 
                if random.v == false then
                    if Type == 'Music' and sync.v == false then 
                        local files = getFilesInPath(Config['Settings']['Path'], '*.mp3')
                        if files[select-1] ~= nil then
                            playSound(Config['Settings']['Path']..'/'..files[select-1])
                            MusicName = files[select-1]
                            select=select-1
                        elseif files[select-1] == nil then 
                            playSound(Config['Settings']['Path']..'/'..files[1])
                            MusicName = files[1]
                            select=1
                        end
                    elseif Type == 'PlayList' and sync.v == false then 
                        if ConfigPlaylist['Songs'][select-1] ~= nil then 
                            playSound(ConfigPlaylist['Songs'][select-1][2])
                            MusicName = ConfigPlaylist['Songs'][select-1][2]
                            select=select-1
                        elseif ConfigPlaylist['Songs'][select-1] == nil  then
                            select = 0 
                            playSound(ConfigPlaylist['Songs'][1][2])
                            MusicName = ConfigPlaylist['Songs'][1][2]
                        end              
                    elseif Type == 'Search' and sync.v == false then 
                        playSound(tracks[select-1]..'.mp3')   
                        MusicName = tracks[select-1]..'.mp3'
                        select=select-1           
                    elseif Type == 'Radio' and sync.v == false then 
                        if Config['Radio'][select-1] ~= nil then 
                            playSound(Config['Radio'][select-1][2])
                            MusicName = Config['Radio'][select-1][1]
                            select=select-1
                        elseif Config['Radio'][select-1] == nil  then
                            select = 0 
                            playSound(Config['Radio'][1][2])
                            MusicName = Config['Radio'][1][1]
                        end 
                    end
                else 
                    if Type == 'Music' and sync.v == false then 
                        local files = getFilesInPath(Config['Settings']['Path'], '*.mp3')
                        local randseed = math.random(#files,0)
                        if files[randseed] ~= nil then
                            playSound(Config['Settings']['Path']..'/'..files[randseed])
                            MusicName = files[randseed]
                            select=randseed
                        elseif files[select-randseed] == nil then 
                            playSound(Config['Settings']['Path']..'/'..files[1])
                            MusicName = files[1]
                            select=1
                        end
                    elseif Type == 'PlayList' and sync.v == false then 
                        local randseed = math.random(#ConfigPlaylist['Songs'],0)
                        if ConfigPlaylist['Songs'][randseed] ~= nil then 
                            playSound(ConfigPlaylist['Songs'][randseed][2])
                            MusicName = ConfigPlaylist['Songs'][randseed][2]
                            select=randseed
                        elseif ConfigPlaylist['Songs'][randseed] == nil  then
                            select = 0 
                            playSound(ConfigPlaylist['Songs'][1][2])
                            MusicName = ConfigPlaylist['Songs'][1][2]
                        end              
                    elseif Type == 'Search' and sync.v == false then 
                        local randseed = math.random(0,select)
                        playSound(tracks[randseed]..'.mp3')   
                        MusicName = tracks[randseed]..'.mp3'
                        select=randseed           
                    elseif Type == 'Radio' and sync.v == false then 
                        local randseed = math.random(0,#Config['Radio'])
                        if Config['Radio'][randseed] ~= nil then 
                            playSound(Config['Radio'][randseed][2])
                            MusicName = Config['Radio'][randseed][1]
                            select=select-randseed
                        elseif Config['Radio'][randseed] == nil  then
                            select = 0 
                            playSound(Config['Radio'][1][2])
                            MusicName = Config['Radio'][1][1]
                        end 
                    end                    
                end
            end 
            imgui.SameLine()
            if pause.v == false then  
                if imgui.Button(fa.ICON_FA_PAUSE,imgui.ImVec2(40, 30)) then if playsound ~= nil then setAudioStreamState(playsound, action.PAUSE) pause.v = true end end
                Hovered('Приостановить')
            else 
                if imgui.Button(fa.ICON_FA_PLAY,imgui.ImVec2(40, 30)) then if playsound ~= nil then setAudioStreamState(playsound, action.RESUME) pause.v = false end end
                Hovered('Продолжить')
            end
            imgui.SameLine()
            if imgui.Button(fa.ICON_FA_FORWARD,imgui.ImVec2(65, 30)) then 
                if random.v == false then 
                    if Type == 'Music' and sync.v == false then 
                        local files = getFilesInPath(Config['Settings']['Path'], '*.mp3')
                        if files[select+1] ~= nil then
                            playSound(Config['Settings']['Path']..'/'..files[select+1])
                            MusicName = files[select+1]
                            select=select+1
                        elseif files[select+1] == nil then 
                            playSound(Config['Settings']['Path']..'/'..files[1])
                            MusicName = files[1]
                            select=1
                        end
                    elseif Type == 'PlayList' and sync.v == false then 
                        if ConfigPlaylist['Songs'][select+1] ~= nil then 
                            playSound(ConfigPlaylist['Songs'][select+1][2])
                            MusicName = ConfigPlaylist['Songs'][select+1][1]
                            select=select+1
                        elseif ConfigPlaylist['Songs'][select+1] == nil  then
                            select = 0 
                            playSound(ConfigPlaylist['Songs'][1][2])
                            MusicName = ConfigPlaylist['Songs'][1][1]
                        end              
                    elseif Type == 'Search' and sync.v == false then 
                        playSound(tracks[select+1]..'.mp3')   
                        MusicName = tracks[select+1]..'.mp3'
                        select=select+1           
                    elseif Type == 'Radio' and sync.v == false then 
                        if Config['Radio'][select+1] ~= nil then 
                            playSound(Config['Radio'][select+1][2])
                            MusicName = Config['Radio'][select+1][1]
                            select=select+1
                        elseif Config['Radio'][select+1] == nil  then
                            select = 0 
                            playSound(Config['Radio'][1][2])
                            MusicName = Config['Radio'][1][1]
                        end 
                    end
                else 
                    if Type == 'Music' and sync.v == false then 
                        local randseed = math.random(0,#files)
                        if files[randseed] ~= nil then
                            playSound(Config['Settings']['Path']..'/'..files[randseed])
                            MusicName = files[randseed]
                            select=randseed
                        elseif files[randseed] == nil then 
                            playSound(Config['Settings']['Path']..'/'..files[1])
                            MusicName = files[1]
                            select=1
                        end
                    elseif Type == 'PlayList' and sync.v == false then
                        local randseed = math.random(0,#ConfigPlaylist['Songs']) 
                        if ConfigPlaylist['Songs'][randseed] ~= nil then 
                            playSound(ConfigPlaylist['Songs'][randseed][2])
                            MusicName = ConfigPlaylist['Songs'][randseed][1]
                            select=randseed
                        elseif ConfigPlaylist['Songs'][randseed] == nil then
                            select = 0 
                            playSound(ConfigPlaylist['Songs'][1][2])
                            MusicName = ConfigPlaylist['Songs'][1][1]
                        end              
                    elseif Type == 'Search' and sync.v == false then 
                        local randseed = math.random(0,#tracks) 
                        playSound(tracks[randseed]..'.mp3')   
                        MusicName = tracks[randseed]..'.mp3'
                        select=randseed           
                    elseif Type == 'Radio' and sync.v == false then 
                        local randseed = math.random(0,#Config['Radio'])
                        if Config['Radio'][randseed] ~= nil and select ~= #Config['Radio'] then 
                            playSound(Config['Radio'][randseed][2])
                            MusicName = Config['Radio'][randseed][1]
                            select=randseed
                        elseif Config['Radio'][randseed] == nil  then
                            select = 0 
                            playSound(Config['Radio'][1][2])
                            MusicName = Config['Radio'][1][1]
                        end 
                    end                    
                end
            end 
            imgui.SameLine()
            if random.v == false then 
                if imgui.Button(fa.ICON_FA_RANDOM,imgui.ImVec2(40, 30)) then random.v = true Config['Settings']['Vidjet']['RandomMusic'] = random.v end 
                Hovered('Случайно')
            else 
                if imgui.Button(fa.ICON_FA_EJECT,imgui.ImVec2(40, 30)) then random.v = false Config['Settings']['Vidjet']['RandomMusic'] = random.v end 
                Hovered('По порядку')
            end
        else 
            SizeY = 25 
        end
        imgui.PopStyleColor()
        imgui.End()
        imgui.PopStyleColor()
    end
    if menu_helo_active.v  == true then 
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(750, 130), imgui.Cond.FirstUseEver)
        imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
        imgui.Begin(u8' МП3P ', menu_helo_active,imgui.WindowFlags.NoCollapse+imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove +imgui.WindowFlags.NoTitleBar) 
            imgui.PushFont(fontsize)
                imgui.CenterText(u8'MP3 PLAYER 2.0 Загружен!')
                imgui.CenterText(u8'Что включаем?')
                Hovered('Данное меню можно отключить в настройках')
            imgui.PopFont()    
            if imgui.Button(u8'Радио',imgui.ImVec2(200, 40)) then Type = 'Radio' playSound(Config['Radio'][1][2])  select = 0 MusicName = Config['Radio'][1][1] menu_helo_active.v = false imgui.ShowCursor = false end   
            imgui.SameLine()  
            local files = getFilesInPath(Config['Settings']['Path'], '*.mp3')
            if #files > 0 then
                if imgui.Button(u8'Мою музыку',imgui.ImVec2(200, 40)) then 
                    Type = 'Music'
                    select = 0
                    playSound(Config['Settings']['Path']..'/'..files[1])
                    menu_helo_active.v = false
                    imgui.ShowCursor = false
                    MusicName = files[1]
                end 
            end  
            imgui.SameLine() 
            if imgui.Button(u8'Подборку из интернета',imgui.ImVec2(200, 40)) then 
                tracks = {}
                asyncHttpRequest('GET', 'https://eu.hitmotop.com/songs/top-today', nil,
                    function(response)
                        for link in string.gmatch(u8:decode(response.text), 'href="(.-)" class=') do
                            if link:find('https://eu.hitmotop.com/get/music/') then
                                track = link:match('(.+).mp3')
                                tracks[#tracks+1] = track
                            end
                        end
                        Type = 'Search'
                        select = 0
                        playSound(tracks[1]..'.mp3')
                        MusicName = tracks[1]..'.mp3'
                        menu_helo_active.v = false
                        imgui.ShowCursor = false
                    end,
                    function(err)
                        print(err)
                    end)                
            end   
            imgui.SameLine()  
            if imgui.Button(u8'Закрыть',imgui.ImVec2(85, 40)) then menu_helo_active.v = false imgui.ShowCursor = false end   
            imgui.SameLine()  
        imgui.End()  
    end
	if menu.v then 
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(750, 405), imgui.Cond.FirstUseEver)
        imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
        imgui.Begin(u8' МП3 ', menu,imgui.WindowFlags.NoCollapse+imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove +imgui.WindowFlags.NoTitleBar)	
        if menu_selected > 0 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.11, 0.15, 0.17, 0.5))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.18, 0.22, 1.00))
            if imgui.Button(fa.ICON_FA_ARROW_LEFT..u8'    MP3 PLAYER 2.0',imgui.ImVec2(130, 45)) then menu_selected = 0 end 
            imgui.PopStyleColor()
            imgui.PopStyleColor()
            imgui.Separator()
        else 
            imgui.PushFont(fontsize)
                imgui.Text(u8' MP3 PLAYER 2.0')
                Hovered('Наслаждайся!')
            imgui.PopFont()
            if AudioHandle ~= nil then
                imgui.SameLine()
                imgui.PushItemWidth(105)
                if imgui.SliderFloat(u8'Громкость', volume, 0, 1) then 
                    if playsound ~= nil then setAudioStreamVolume(playsound, volume.v) end
                end
            end
            imgui.SetCursorPos(imgui.ImVec2(700,10))
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.11, 0.15, 0.17, 0.5))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.18, 0.22, 1.00))
            if imgui.Button(fa.ICON_FA_POWER_OFF,imgui.ImVec2(30, 30)) then menu.v = false end
            imgui.PopStyleColor()
            imgui.PopStyleColor()
        end
        if menu_selected == 0 then
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.11, 0.15, 0.17, 0.5))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.18, 0.22, 1.00))
            imgui.PushFont(fa_font2) 
            if imgui.Button(fa.ICON_FA_PODCAST,imgui.ImVec2(231, 300)) then menu_selected = 1 end
            imgui.PopFont()
            Hovered('Радио')
            imgui.SameLine()
            imgui.PushFont(fa_font2)
            if imgui.Button(fa.ICON_FA_MUSIC,imgui.ImVec2(231, 300)) then menu_selected = 2 end
            imgui.PopFont()
            Hovered('Музыка')
            imgui.SameLine()
            imgui.PushFont(fa_font2)
            if imgui.Button(fa.ICON_FA_TH_LIST,imgui.ImVec2(231, 300)) then menu_selected = 3 end
            imgui.PopFont()
            Hovered('Плейлисты')
            imgui.PopStyleColor()
            imgui.PopStyleColor()
            imgui.PushStyleColor(imgui.Col.ChildWindowBg, imgui.ImVec4(0.11, 0.15, 0.17, 0))
            imgui.BeginChild('#1', imgui.ImVec2(720, 40),false)
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.11, 0.15, 0.17, 0.5))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.18, 0.22, 1.00))
                if imgui.Button(fa.ICON_FA_COG,imgui.ImVec2(40, 40)) then menu_selected = 4 end
                Hovered('Настройки')
                imgui.SameLine()
                if AudioHandle ~= nil then
                    if mute.v == false then
                        if imgui.Button(fa.ICON_FA_VOLUME_MUTE,imgui.ImVec2(40, 40)) then setAudioStreamVolume(playsound, 0) mute.v = true end
                        Hovered('Замутить')
                    else 
                        if imgui.Button(fa.ICON_FA_VOLUME_UP,imgui.ImVec2(40, 40)) then setAudioStreamVolume(playsound, volume.v) mute.v = false end
                        Hovered('Размутить')
                    end
                    imgui.SameLine()
                    if pause.v == false then  
                        if imgui.Button(fa.ICON_FA_PAUSE,imgui.ImVec2(40, 40)) then if playsound ~= nil then setAudioStreamState(playsound, action.PAUSE) pause.v = true end end
                        Hovered('Приостановить')
                    else 
                        if imgui.Button(fa.ICON_FA_PLAY,imgui.ImVec2(40, 40)) then if playsound ~= nil then setAudioStreamState(playsound, action.RESUME) pause.v = false end end
                        Hovered('Продолжить')
                    end
                end
                imgui.SameLine()
                if imgui.Button(fa.ICON_FA_WIFI,imgui.ImVec2(40, 40)) then menu_selected = 7 end
                Hovered('Поиск музыки онлайн')
                imgui.SameLine()
                if imgui.Button(fa.ICON_FA_INFO_CIRCLE,imgui.ImVec2(40, 40)) then menu_selected = 9 end
                Hovered('Как интегрировать свои песни в "Свое радио" в машине ?')
            imgui.PopStyleColor()
            imgui.PopStyleColor()
            imgui.EndChild()
            imgui.PopStyleColor()
            imgui.SetCursorPos(imgui.ImVec2(700,10))
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.11, 0.15, 0.17, 0.5))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.18, 0.22, 1.00))
            if imgui.Button(fa.ICON_FA_POWER_OFF,imgui.ImVec2(30, 30)) then menu.v = false end
            imgui.PopStyleColor()
            imgui.PopStyleColor()
            imgui.SetCursorPos(imgui.ImVec2(500,370))
            imgui.Text(u8'Автор: UBP | blast.hk/members/392402')
            if imgui.IsItemClicked() then os.execute('start https://www.blast.hk/members/392402') end
            Hovered('Нажми, чтобы перейти в профиль.')
        end
        if menu_selected == 1 then 
            for i, v in ipairs(Config['Radio']) do
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.11, 0.15, 0.17, 0.5))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.18, 0.22, 1.00))
                if imgui.Button(fa.ICON_FA_TRASH..'     '..i,imgui.ImVec2(25, 25)) then
                    table.remove(Config['Radio'], i) 
                end
                imgui.PopStyleColor()
                imgui.PopStyleColor()
                Hovered('Нажми, чтобы удалить')
                imgui.SameLine()
                if imgui.Selectable(u8(v[1]),select == i)
                    then select = i 
                    playSound(v[2])
                    MusicName = v[1]
                    Type = "Radio"
                end
            end  
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.11, 0.15, 0.17, 0.5))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.18, 0.22, 1.00))
            if imgui.Button(fa.ICON_FA_PLUS,imgui.ImVec2(720, 25)) then Radio_Edit.v = not Radio_Edit.v end  
            imgui.PopStyleColor()
            imgui.PopStyleColor()      
            if Radio_Edit.v then 
                imgui.PushItemWidth(150)
                imgui.InputText(u8'Название',radio_name)
                imgui.PushItemWidth(400)
                imgui.InputText(u8'Ссылка',radio_link)
                Hovered('Ссылка должна быть на прямой аудиопоток')
                if imgui.Button(fa.ICON_FA_SAVE,imgui.ImVec2(25, 25)) then 
                    local Last = 0  
                    for i,v in ipairs(Config['Radio']) do 
                        Last = i 
                        if i > Last then Last = i end
                    end
                    Config['Radio'][Last+1] = {radio_name.v, radio_link.v}
                    radio_link.v = ''
                    radio_name.v = ''
                    Radio_Edit.v = false                    
                end   
                Hovered('Сохранить')
            end
        end
        if menu_selected == 2 then 
            local files = getFilesInPath(Config['Settings']['Path'], '*.mp3')
            imgui.PushItemWidth(550)
            imgui.InputText(u8'Поиск по названию',FindMyMusic)
            for i, file  in ipairs(files) do
                if FindMyMusic.v == '' then
                    if imgui.Selectable(u8(i..'. '..file),select == i) then 
                        select = i 
                        playSound(Config['Settings']['Path']..'/'..file)
                        Type = 'Music'
                        MusicName = file
                    end 
                elseif string.lower(file):find(FindMyMusic.v) or string.upper(file):find(FindMyMusic.v) then
                    if imgui.Selectable(u8(i..'. '..file),select == i) then 
                        select = i 
                        playSound(Config['Settings']['Path']..'/'..file)
                        Type = 'Music'
                        MusicName = file
                    end            
                end  
            end       
        end
        if menu_selected == 3 then 
            imgui.PushFont(fontsize)
            imgui.Text(u8('Создать плейлист'))
            imgui.SameLine()
            imgui.PopFont()
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.11, 0.15, 0.17, 0.5))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.18, 0.22, 1.00))
            if imgui.Button(fa.ICON_FA_PLUS,imgui.ImVec2(28, 28)) then Playlist_Create.v = not Playlist_Create.v end
            if Playlist_Create.v then 
                imgui.PushFont(fontsize)
                imgui.CenterText(u8('Новый плейлист'))
                imgui.PopFont()
                imgui.PushItemWidth(632)
                imgui.InputText('',PlayName)  
                imgui.SameLine()  
                if imgui.Button(u8'Создать',imgui.ImVec2(75, 25)) then 
                    if not doesFileExist("moonloader/resource/MP3Player/Playlists/" .. u8:decode(PlayName.v) .. ".json") then
                        local f = io.open("moonloader/resource/MP3Player/Playlists/" .. u8:decode(PlayName.v) .. ".json", "w")
                        f:write(encodeJson(ConfigPlaylistDefault))
                        f:close()   
                        local f = io.open("moonloader/resource/MP3Player/Playlists/" .. u8:decode(PlayName.v) .. ".json", 'r')
                        if f then
                            ConfigPlaylist = decodeJson(f:read('*a'))
                            f:close() 
                            print('Config reads'.."moonloader/resource/MP3Player/Playlists/" .. u8:decode(PlayName.v) .. ".json")
                        end
                    else
                        local f = io.open("moonloader/resource/MP3Player/Playlists/" .. u8:decode(PlayName.v) .. ".json", 'r')
                        if f then
                           ConfigPlaylist = decodeJson(f:read('*a'))
                        end
                        f:close()
                    end
                    Playlist_Create.v = false   
                    PlayName.v = ''                 
                end             
            end 
            imgui.PopStyleColor()
            imgui.PopStyleColor()  
            local files = getFilesInPath(Config['Settings']['Path']..'/'..'Playlists', '*.json')
            if files == nil then  
            else 
                for i, file  in ipairs(files) do
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.11, 0.15, 0.17, 0.5))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.18, 0.22, 1.00))
                    if imgui.Button(u8(file),imgui.ImVec2(600, 25)) then 
                        local f = io.open("moonloader/resource/MP3Player/Playlists/" .. file, 'r')
                        if f then
                            ConfigPlaylist = decodeJson(f:read('*a'))
                            f:close() 
                        end
                        Type = 'PlayList'
                        select = 1
                        if ConfigPlaylist['Songs'][1] ~= nil then 
                            playSound(ConfigPlaylist['Songs'][1][2])
                            MusicName = ConfigPlaylist['Songs'][1][2]
                        end
                    end
                    imgui.SameLine()
                    if imgui.Button(fa.ICON_FA_EDIT,imgui.ImVec2(49, 25)) then 
                        menu_selected = 6 
                        Playlist = file 
                        local f = io.open("moonloader/resource/MP3Player/Playlists/" .. file, 'r')
                        if f then
                            ConfigPlaylist = decodeJson(f:read('*a'))
                            f:close() 
                        end
                        PlaySelect = file
                    end
                    Hovered('Редактировать')
                    imgui.SameLine()
                    if imgui.Button(fa.ICON_FA_PLAY,imgui.ImVec2(49, 25)) then 
                        local f = io.open("moonloader/resource/MP3Player/Playlists/" .. file, 'r')
                        if f then
                            ConfigPlaylist = decodeJson(f:read('*a'))
                            f:close() 
                        end
                        Type = 'PlayList'
                        select = 1
                        if ConfigPlaylist['Songs'][1] ~= nil then 
                            playSound(ConfigPlaylist['Songs'][1][2])
                            MusicName = ConfigPlaylist['Songs'][1][2]
                        end
                    end
                    Hovered('Прослушать')
                    imgui.PopStyleColor()
                    imgui.PopStyleColor()
                end
            end             
        end
        if menu_selected == 4 then 
            imgui.PushItemWidth(550)
            imgui.InputText(u8'',mus_Path)
            Hovered('Где искать музыку')
            imgui.SameLine()
            if imgui.Button(fa.ICON_FA_FOLDER,imgui.ImVec2(71, 25)) then mus_Path.v = 'moonloader/resource/MP3Player' end   
            Hovered('Стандартная папка')   
            imgui.SameLine()
            if imgui.Button(fa.ICON_FA_MUSIC,imgui.ImVec2(72, 25)) then mus_Path.v = 'C:/Users/Public/Music' end   
            Hovered('музыка windows')    
            imgui.Checkbox(u8'Приветственное меню при входе',menu_helo)
            imgui.SameLine()
            imgui.Checkbox(u8'Виджет',Vidjet)
            if Vidjet.v then 
                imgui.BeginChild('ChildSetVidjet',imgui.ImVec2(720,25),false)
                    imgui.Checkbox(u8'Отображать кнопки',Vidjet_buttons)
                    imgui.SameLine()
                    imgui.Checkbox(u8'Отображать название песни',Vidjet_music_name)
                    imgui.SameLine()
                    imgui.Checkbox(u8'Прозрачность',Vidjet_alpha)
                    imgui.SameLine()
                    imgui.Checkbox(u8'Размер',Vidjet_Size)
                    imgui.SameLine()
                    imgui.Checkbox(u8'Разделить',Vidjet_Drop)
                    Hovered('Разделяет виджет на 2 части: текст и кнопки')
                imgui.EndChild()
                imgui.BeginChild('ChildSetVidjet2',imgui.ImVec2(720,80),false)
                    imgui.CenterText(u8'Раздел с кнопками')
                    if Vidjet_alpha.v then
                        imgui.PushItemWidth(600)
                        imgui.SliderFloat(u8'Прозрачность', Vidjet_Alpha_float, 0, 1) 
                    end
                    if Vidjet_Size.v then
                        imgui.PushItemWidth(600)
                        imgui.SliderFloat(u8'Высота', Vidjet_Size_float, 60, 75) 
                    end
                imgui.EndChild()   
                if Vidjet_Drop.v then
                    imgui.BeginChild('ChildSetVidjet3',imgui.ImVec2(720,60),false)
                        imgui.CenterText(u8'Раздел с текстом')
                        imgui.PushItemWidth(600)
                        imgui.SliderFloat(u8'Ширина', Vidjet_Drop_Width, 100, 330) 
                    imgui.EndChild()                       
                end
            end
            if imgui.Button(u8'Сохранить',imgui.ImVec2(720, 25)) then
                Config['Settings']['Path'] = mus_Path.v
                Config['Settings']['HelloMenu'] = menu_helo.v
                Config['Settings']['Vidjet']['Active'] = Vidjet.v
                Config['Settings']['Vidjet']['Buttons'] = Vidjet_buttons.v
                Config['Settings']['Vidjet']['Alpha'] = Vidjet_Alpha_float.v
                Config['Settings']['Vidjet']['MusicName'] = Vidjet_music_name.v
                Config['Settings']['Vidjet']['AlphaEnable'] = Vidjet_alpha.v
                Config['Settings']['Vidjet']['Size'] = Vidjet_Size.v
                Config['Settings']['Vidjet']['SizeY'] = Vidjet_Size_float.v
                Config['Settings']['Vidjet']['Drop'] = Vidjet_Drop.v
            end

        end
        if menu_selected == 6 then 
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.11, 0.15, 0.17, 0.5))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.18, 0.22, 1.00))
            if imgui.Button(fa.ICON_FA_TRASH,imgui.ImVec2(720, 25)) then  menu_selected = 3 os.remove(Config['Settings']['Path']..'/Playlists/'..Playlist) end
            imgui.PopStyleColor()   
            imgui.PopStyleColor()  
            Hovered('Удалить плейлист')
            for i, v in ipairs(ConfigPlaylist['Songs']) do
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.11, 0.15, 0.17, 0.5))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.18, 0.22, 1.00))
                if imgui.Button(fa.ICON_FA_TRASH..'     '..i,imgui.ImVec2(25, 25)) then
                    table.remove(ConfigPlaylist['Songs'], i) 
                    local f = io.open("moonloader/resource/MP3Player/Playlists/" ..PlaySelect, "w")
                    if f then
                        f:write(encodeJson(ConfigPlaylist))
                        f:close()
                    end
                end
                imgui.PopStyleColor()
                imgui.PopStyleColor()
                Hovered('Нажмите, чтобы удалить')
                imgui.SameLine()
                if imgui.Selectable(u8(v[1]),select == i) then
                    select = i 
                    playSound(v[2])
                    MusicName = v[2]
                    Type = 'PlayList'
                end
            end 
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.11, 0.15, 0.17, 0.5))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.18, 0.22, 1.00))
            if imgui.Button(fa.ICON_FA_PLUS,imgui.ImVec2(720, 25)) then Radio_Edit.v = not Radio_Edit.v end 
            Hovered('Добавить песни в плейлист')
            imgui.PopStyleColor()   
            imgui.PopStyleColor()     
            if Radio_Edit.v then 
                if imgui.Button(u8'Музыка',imgui.ImVec2(50, 25)) then 
                    Sel = 'Mus'  
                    local files = getFilesInPath(Config['Settings']['Path'], '*.mp3')
                    Musics = files
                end
                imgui.SameLine()
                if imgui.Button(u8'Ссылка',imgui.ImVec2(50, 25)) then Sel = 'Link' end  
                if Sel == 'Mus' then 
                    for i, file  in ipairs(Musics) do
                        if imgui.Selectable(u8(i..'. '..u8(file)),select == i) then 
                            local Last = 0  
                            for i,v in ipairs(ConfigPlaylist['Songs']) do 
                                Last = i 
                                if i > Last then Last = i end
                            end
                            ConfigPlaylist['Songs'][Last+1] = {file, Config['Settings']['Path']..'/'..file}
                            table.remove(Musics, i) 
                        end
                    end
                    if imgui.Button(u8'Сохранить',imgui.ImVec2(70, 25)) then 
                        print("moonloader/resource/MP3Player/Playlists/" ..PlaySelect)
                        local f = io.open("moonloader/resource/MP3Player/Playlists/" ..PlaySelect, "w")
                        if f then
                            f:write(encodeJson(ConfigPlaylist))
                            f:close()
                        end
                        Radio_Edit.v = false 
                        Sel = '' end                    
                elseif Sel == 'Link' then 
                    imgui.PushItemWidth(150)
                    imgui.InputText(u8'Название ',radio_name)
                    imgui.PushItemWidth(400)
                    imgui.InputText(u8'Ссылка ',radio_link)
                    Hovered('Ссылка должна быть на прямой аудиопоток')
                    if imgui.Button(u8('Сохранить'),imgui.ImVec2(70, 25)) then 
                        if radio_link.v == '' and radio_name.v == '' then
                            radio_name.v = u8('Заполните это поле!')
                            radio_link.v = u8('Заполните это поле!')
                        else
                            local Last = 0  
                            for i,v in ipairs(ConfigPlaylist['Songs']) do 
                                Last = i 
                                if i > Last then Last = i end
                            end
                            ConfigPlaylist['Songs'][Last+1] = {radio_name.v, radio_link.v}
                            radio_link.v = ''
                            radio_name.v = ''
                            Sel = ''
                            Radio_Edit.v = false   
                            local f = io.open("moonloader/resource/MP3Player/Playlists/" ..PlaySelect, "w")
                            f:write(encodeJson(ConfigPlaylist))
                            f:close() 
                        end
                    end                  
                end
            end
        end
        if menu_selected == 7 then 
            imgui.PushItemWidth(550)
            imgui.InputText(u8'Название песни',FindMusic)
            imgui.SameLine()
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.11, 0.15, 0.17, 0.5))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.15, 0.18, 0.22, 1.00))
            if imgui.Button(fa.ICON_FA_SEARCH,imgui.ImVec2(60, 25)) then 
                tracks = {}
                asyncHttpRequest('GET', 'https://eu.hitmotop.com/search?q='..urlencode(u8(u8:decode(FindMusic.v))), nil,
                    function(response)
                        for link in string.gmatch(u8:decode(response.text), 'href="(.-)" class=') do
                            if link:find('https://eu.hitmotop.com/get/music/') then
                                track = link:match('(.+).mp3')
                                tracks[#tracks+1] = track
                                print(track)
                            end
                        end
                    end,
                    function(err)
                        print(err)
                    end)               
            end
            if imgui.Button(u8'ТОП 2022',imgui.ImVec2(100, 25)) then 
                tracks = {}
                asyncHttpRequest('GET', 'https://eu.hitmotop.com/songs/top-today', nil,
                    function(response)
                        for link in string.gmatch(u8:decode(response.text), 'href="(.-)" class=') do
                            if link:find('https://eu.hitmotop.com/get/music/') then
                                track = link:match('(.+).mp3')
                                tracks[#tracks+1] = track
                            end
                        end
                    end,
                    function(err)
                        print(err)
                    end)
            end
            imgui.SameLine()
            if imgui.Button(u8'Популярная музыка ВК',imgui.ImVec2(200, 25)) then 
                tracks = {}
                asyncHttpRequest('GET', 'https://eu.hitmotop.com/songs/top-today', nil,
                    function(response)
                        for link in string.gmatch(u8:decode(response.text), 'href="(.-)" class=') do
                            if link:find('https://eu.hitmotop.com/get/music/') then
                                track = link:match('(.+).mp3')
                                tracks[#tracks+1] = track
                            end
                        end
                    end,
                    function(err)
                        print(err)
                    end)
            end   
            imgui.SameLine()
            if imgui.Button(u8'Европа плюс',imgui.ImVec2(100, 25)) then 
                tracks = {}
                asyncHttpRequest('GET', 'https://eu.hitmotop.com/collection/10562', nil,
                    function(response)
                        for link in string.gmatch(u8:decode(response.text), 'href="(.-)" class=') do
                            if link:find('https://eu.hitmotop.com/get/music/') then
                                track = link:match('(.+).mp3')
                                tracks[#tracks+1] = track
                            end
                        end
                    end,
                    function(err)
                        print(err)
                    end)
            end  
            imgui.SameLine()
            if imgui.Button(u8'МУЗ ТВ',imgui.ImVec2(100, 25)) then 
                tracks = {}
                asyncHttpRequest('GET', 'https://eu.hitmotop.com/collection/10563', nil,
                    function(response)
                        for link in string.gmatch(u8:decode(response.text), 'href="(.-)" class=') do
                            if link:find('https://eu.hitmotop.com/get/music/') then
                                track = link:match('(.+).mp3')
                                tracks[#tracks+1] = track
                            end
                        end
                    end,
                    function(err)
                        print(err)
                    end)
            end  
            imgui.SameLine()
            if imgui.Button(u8'Топ 100 Радио Рекорд',imgui.ImVec2(175, 25)) then 
                tracks = {}
                asyncHttpRequest('GET', 'https://eu.hitmotop.com/collection/10565', nil,
                    function(response)
                        for link in string.gmatch(u8:decode(response.text), 'href="(.-)" class=') do
                            if link:find('https://eu.hitmotop.com/get/music/') then
                                track = link:match('(.+).mp3')
                                tracks[#tracks+1] = track
                            end
                        end
                    end,
                    function(err)
                        print(err)
                    end)
            end           
            for i,v in ipairs(tracks) do 
                if imgui.Button(fa.ICON_FA_PLUS..'         '..i,imgui.ImVec2(25, 25)) then link = v..'.mp3' menu_selected = 8 end
                Hovered('Добавить в плейлист')
                imgui.SameLine()
                if imgui.Selectable(u8(i..'. '..u8(v)),select == i) then 
                    select = i
                    playSound(v..'.mp3')
                    MusicName = v..'.mp3'
                    Type = 'Search'
                end
            end
            imgui.PopStyleColor()
            imgui.PopStyleColor()
        end
        if menu_selected == 8 then 
            local files = getFilesInPath(Config['Settings']['Path']..'/'..'Playlists', '*.json')
            if files == nil then  
            else 
                for i, file  in ipairs(files) do
                    imgui.BeginChild('#1'..i, imgui.ImVec2(110, 60),false)
                    imgui.Button(u8(file),imgui.ImVec2(110, 25))
                    if imgui.Button(fa.ICON_FA_PLUS,imgui.ImVec2(110, 25)) then 
                        local Last = 0  
                        for i,v in ipairs(ConfigPlaylist['Songs']) do 
                            Last = i 
                            if i > Last then Last = i end
                        end
                        ConfigPlaylist['Songs'][Last+1] = {link, link}   
                        PlaySelect = file
                        local f = io.open("moonloader/resource/MP3Player/Playlists/" ..PlaySelect, "w")
                        if f then
                            f:write(encodeJson(ConfigPlaylist))
                            f:close()
                        end 
                        menu_selected = 7                    
                    end
                    Hovered('Добавить сюда')
                    imgui.EndChild() 
                    if i <= 5 then 
                        imgui.SameLine()
                    elseif i == 6 then 

                    elseif i > 6 and i < 12 then 
                        imgui.SameLine()
                    elseif i == 12 then

                    elseif i > 12 and i < 18 then
                        imgui.SameLine()
                    elseif i == 18 then 

                    elseif i > 18 and i < 24 then 
                        imgui.SameLine()
                    elseif i == 24 then 

                    elseif i > 24 then 
                        imgui.SameLine()
                    end
                end
            end             
        end
        if menu_selected == 9 then 
            imgui.PushFont(fontsize)
            imgui.CenterText(u8'Интеграция в радио')
            imgui.PopFont()
            imgui.Separator()
            imgui.Text(u8([[
            Чтобы интегрировать ваши песни, перейдите по пути где они лежат
            Затем выделите их все и скопируйте нажав ctrl+C. Далее перейдите по пути
            c:/users/documents/gta san andreas user files/user tracks и нажмите ctrl+V
            Вернитесь в игру. Зайдите в настройки > настройки звука > свое радио 
            Нажмите сканирование. Выйдите из настроек. Теперь вы можете слушать песни в радио.]]))
        end
        imgui.End()	
	end
end
function LoadSaves()
    mus_Path.v = Config['Settings']['Path']
    menu_helo.v = Config['Settings']['HelloMenu']
    menu_helo_active.v = menu_helo.v
    Vidjet.v = Config['Settings']['Vidjet']['Active']
    Vidjet_buttons.v = Config['Settings']['Vidjet']['Buttons']
    Vidjet_music_name.v = Config['Settings']['Vidjet']['MusicName']
    Vidjet_alpha.v = Config['Settings']['Vidjet']['AlphaEnable']
    Vidjet_Alpha_float.v = Config['Settings']['Vidjet']['Alpha']
    Vidjet_Size.v = Config['Settings']['Vidjet']['Size']
    Vidjet_Size_float.v = Config['Settings']['Vidjet']['SizeY']
    Vidjet_Drop.v = Config['Settings']['Vidjet']['Drop']
    random.v = Config['Settings']['Vidjet']['RandomMusic']
    volume.v = Config['Settings']['Volume']
end
function onScriptTerminate(script, quitGame)
    if script == thisScript() then
        Config['Settings']['Volume'] = volume.v
        local f = io.open("moonloader/resource/MP3Player/" .. thisScript().name .. ".json", "w")
        if f then
            f:write(encodeJson(Config))
            f:close()
        end
    end
end
function urlencode(str)
   if (str) then
      str = string.gsub (str, "\n", "\r\n")
      str = string.gsub (str, "([^%w ])",
         function (c) return string.format ("%%%02X", string.byte(c)) end)
      str = string.gsub (str, " ", "+")
   end
   return str
end
function asyncHttpRequest(method, url, args, resolve, reject)
   local request_thread = effil.thread(function (method, url, args)
      local requests = require 'requests'
      local result, response = pcall(requests.request, method, url, args)
      if result then
         response.json, response.xml = nil, nil
         return true, response
      else
         return false, response
      end
   end)(method, url, args)
   -- Если запрос без функций обработки ответа и ошибок.
   if not resolve then resolve = function() end end
   if not reject then reject = function() end end
   -- Проверка выполнения потока
   lua_thread.create(function()
      local runner = request_thread
      while true do
         local status, err = runner:status()
         if not err then
            if status == 'completed' then
               local result, response = runner:get()
               if result then
                  resolve(response)
               else
                  reject(response)
               end
               return
            elseif status == 'canceled' then
               return reject(status)
            end
         else
            return reject(err)
         end
         wait(0)
      end
   end)
end
function playSound(pathmus) 
    if playsound ~= nil then setAudioStreamState(playsound, action.STOP) playsound = nil end
        playsound = loadAudioStream(pathmus)
        if playSound ~= nil then
            setAudioStreamVolume(playsound, volume.v)
            setAudioStreamState(playsound, action.PLAY)
            AudioHandle = playsound
        end
end
function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX( width / 2 - calc.x / 2 )
    imgui.Text(text)
end
function Hovered(text)
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
            imgui.PushTextWrapPos(600)
                imgui.TextUnformatted(u8(text))
            imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end
function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end

    render_text(text)
end

function apply_custom_style()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2

    style.WindowPadding = ImVec2(15, 15)
    style.WindowRounding = 15.0
    style.FramePadding = ImVec2(5, 5)
    style.ItemSpacing = ImVec2(12, 8)
    style.ItemInnerSpacing = ImVec2(8, 6)
    style.IndentSpacing = 25.0
    style.ScrollbarSize = 18.0
    style.ScrollbarRounding = 10.0
    style.GrabMinSize = 15.0
    style.GrabRounding = 7.0
    style.ChildWindowRounding = 6.0
    style.FrameRounding = 6.0


    colors[clr.Text] = ImVec4(0.95, 0.96, 0.98, 1.00)
    colors[clr.TextDisabled] = ImVec4(0.36, 0.42, 0.47, 1.00)
    colors[clr.WindowBg] = ImVec4(0.11, 0.15, 0.17, 1.00)
    colors[clr.ChildWindowBg] = ImVec4(0.15, 0.18, 0.22, 1.00)
    colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.Border] = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors[clr.BorderShadow] = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg] = ImVec4(0.20, 0.25, 0.29, 1.00)
    colors[clr.FrameBgHovered] = ImVec4(0.12, 0.20, 0.28, 1.00)
    colors[clr.FrameBgActive] = ImVec4(0.09, 0.12, 0.14, 1.00)
    colors[clr.TitleBg] = ImVec4(0.09, 0.12, 0.14, 0.65)
    colors[clr.TitleBgCollapsed] = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.TitleBgActive] = ImVec4(0.08, 0.10, 0.12, 1.00)
    colors[clr.MenuBarBg] = ImVec4(0.15, 0.18, 0.22, 1.00)
    colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.39)
    colors[clr.ScrollbarGrab] = ImVec4(0.20, 0.25, 0.29, 1.00)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1.00)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.09, 0.21, 0.31, 1.00)
    colors[clr.ComboBg] = ImVec4(0.20, 0.25, 0.29, 1.00)
    colors[clr.CheckMark] = ImVec4(0.28, 0.56, 1.00, 1.00)
    colors[clr.SliderGrab] = ImVec4(0.28, 0.56, 1.00, 1.00)
    colors[clr.SliderGrabActive] = ImVec4(0.37, 0.61, 1.00, 1.00)
    colors[clr.Button] = ImVec4(0.20, 0.25, 0.29, 1.00)
    colors[clr.ButtonHovered] = ImVec4(0.28, 0.56, 1.00, 1.00)
    colors[clr.ButtonActive] = ImVec4(0.06, 0.53, 0.98, 1.00)
    colors[clr.Header] = ImVec4(0.20, 0.25, 0.29, 0.55)
    colors[clr.HeaderHovered] = ImVec4(0.26, 0.59, 0.98, 0.80)
    colors[clr.HeaderActive] = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.ResizeGrip] = ImVec4(0.26, 0.59, 0.98, 0.25)
    colors[clr.ResizeGripHovered] = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.CloseButton] = ImVec4(0.40, 0.39, 0.38, 0.16)
    colors[clr.CloseButtonHovered] = ImVec4(0.40, 0.39, 0.38, 0.39)
    colors[clr.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)
    colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered] = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.PlotHistogram] = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.TextSelectedBg] = ImVec4(0.25, 1.00, 0.00, 0.43)
    colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
end
apply_custom_style()