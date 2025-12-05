-- Localization system for multi-language support
local Localization = {}

-- Current language (default: English)
Localization.currentLanguage = "en"

-- Available languages
Localization.languages = {
    en = "English",
    zh = "中文",  -- Chinese
    ar = "العربية"  -- Arabic
}

-- Text direction for each language
Localization.textDirection = {
    en = "ltr",  -- Left-to-right
    zh = "ltr",  -- Left-to-right
    ar = "rtl"   -- Right-to-left (Arabic)
}

-- Initialize fonts with Unicode support
function Localization:initFont()
    -- LÖVE automatically loads all glyphs from TrueType/OpenType fonts
    -- The issue with squares is usually because the font file doesn't contain those glyphs
    -- or the font isn't being applied when rendering
    
    -- Try loading Arabic font
    local arabicSuccess, arabicFontOrError = pcall(love.graphics.newFont, "assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf", 16)
    if arabicSuccess and arabicFontOrError then
        self.arabicFont = arabicFontOrError
        print("Arabic font (NotoSansArabic) loaded successfully")
    else
        print("Warning: Arabic font failed to load. Error: " .. tostring(arabicFontOrError))
        -- Try the other Arabic font
        local fallbackSuccess, fallbackFont = pcall(love.graphics.newFont, "assets/fonts/KFGQPC Uthmanic Script HAFS Regular.otf", 16)
        if fallbackSuccess then
            self.arabicFont = fallbackFont
            print("Arabic KFGQPC font loaded successfully")
        else
            self.arabicFont = love.graphics.newFont(16)
            print("Both Arabic fonts failed. Using default font.")
        end
    end
    
    -- Try loading Chinese (Simplified) font
    local chineseSuccess, chineseFontOrError = pcall(love.graphics.newFont, "assets/fonts/NotoSansSC-VariableFont_wght.ttf", 16)
    if chineseSuccess and chineseFontOrError then
        self.chineseFont = chineseFontOrError
        print("Chinese font (NotoSansSC) loaded successfully")
    else
        print("Warning: Chinese font failed to load. Error: " .. tostring(chineseFontOrError))
        self.chineseFont = love.graphics.newFont(16)
    end
    
    -- Set default font (English can use any of them)
    self.englishFont = love.graphics.newFont(16)
    
    love.graphics.setFont(self:getFont())
    print("Font initialization complete")
    print("Current language: " .. self.currentLanguage)
end

-- Get the appropriate font for the current language
function Localization:getFont()
    if self.currentLanguage == "ar" then
        return self.arabicFont or love.graphics.getFont()
    elseif self.currentLanguage == "zh" then
        return self.chineseFont or love.graphics.getFont()
    else
        return self.englishFont or love.graphics.getFont()
    end
end

-- Translation strings
Localization.strings = {
    -- Menu strings
    menu_title = {
        en = "Escape the Haunted House!!!",
        zh = "逃离鬼屋！",
        ar = "!اهرب من البيت المسكون"
    },
    menu_continue = {
        en = "Continue",
        zh = "继续游戏",
        ar = "استمرار"
    },
    menu_new_game = {
        en = "New Game",
        zh = "新游戏",
        ar = "لعبة جديدة"
    },
    menu_quit = {
        en = "Quit",
        zh = "退出",
        ar = "خروج"
    },
    menu_language = {
        en = "Language",
        zh = "语言",
        ar = "اللغة"
    },
    save_location = {
        en = "Save Location: ",
        zh = "存档位置：",
        ar = ":موقع الحفظ"
    },
    
    -- Auto-save notification
    autosave_notification = {
        en = "Game Auto-Saved",
        zh = "游戏已自动保存",
        ar = "تم حفظ اللعبة تلقائيًا"
    },
    
    -- Manual save notification
    manual_save_notification = {
        en = "Game Manually Saved",
        zh = "游戏已手动保存",
        ar = "تم حفظ اللعبة يدويًا"
    },
    
    -- Tutorial popup text
    tutorial_welcome = {
        en = "Welcome to Escape the Haunted House!",
        zh = "欢迎来到逃离鬼屋！",
        ar = "!مرحبًا بك في الهروب من البيت المسكون"
    },
    tutorial_controls = {
        en = "Controls:",
        zh = "控制：",
        ar = ":التحكم"
    },
    tutorial_move = {
        en = "- Point and click to move around",
        zh = "- 点击移动",
        ar = "انقر للتحرك -"
    },
    tutorial_interact = {
        en = "- Click objects to interact with them",
        zh = "- 点击物体进行互动",
        ar = "انقر على الأشياء للتفاعل معها -"
    },
    tutorial_drag = {
        en = "- Drag items from your inventory",
        zh = "- 从物品栏拖动物品",
        ar = "اسحب العناصر من المخزون الخاص بك -"
    },
    tutorial_use = {
        en = "  to use them on objects",
        zh = "  来使用它们",
        ar = "  لاستخدامها على الأشياء"
    },
    tutorial_manual_save = {
        en = "- Press S to manually save your game",
        zh = "- 按 S 手动保存游戏",
        ar = "S اضغط على لحفظ اللعبة يدويًا -"
    },
    tutorial_esc = {
        en = "- Press ESC to return to main menu",
        zh = "- 按 ESC 返回主菜单",
        ar = "ESC اضغط على للعودة إلى القائمة الرئيسية -"
    },
    tutorial_autosave = {
        en = "The game also auto-saves regularly.",
        zh = "游戏也会定期自动保存。",
        ar = ".تحفظ اللعبة أيضًا تلقائيًا بانتظام"
    },
    tutorial_continue = {
        en = "Click anywhere to continue...",
        zh = "点击任意位置继续...",
        ar = "...انقر في أي مكان للمتابعة"
    },
    
    -- Inventory strings
    inventory_title = {
        en = "INVENTORY",
        zh = "物品栏",
        ar = "المخزون"
    },
    inventory_hint = {
        en = "Inventory (I)",
        zh = "物品栏 (I)",
        ar = "(I) المخزون"
    },
    inventory_drag_hint = {
        en = "(Drag items onto objects to use)",
        zh = "（将物品拖到物体上使用）",
        ar = "(اسحب العناصر إلى الأشياء لاستخدامها)"
    },
    inventory_close = {
        en = "Press I to close",
        zh = "按 I 关闭",
        ar = "I اضغط على"
    },
    
    -- Room 1 strings
    room1_title = {
        en = "Room 1: The Cannon",
        zh = "房间1：大炮",
        ar = "الغرفة 1: المدفع"
    },
    obj_leave_room = {
        en = "Objective: LEAVE THE ROOM!",
        zh = "目标：离开房间！",
        ar = "!الهدف: اترك الغرفة"
    },
    obj_find_cannonball = {
        en = "Objective: Find the Cannonball",
        zh = "目标：找到炮弹",
        ar = "الهدف: ابحث عن كرة المدفع"
    },
    obj_load_cannon = {
        en = "Objective: Load the Cannonball into the Cannon",
        zh = "目标：将炮弹装入大炮",
        ar = "الهدف: حمّل كرة المدفع في المدفع"
    },
    obj_blast_door = {
        en = "Objective: BLAST THE DOOR!",
        zh = "目标：炸开门！",
        ar = "!الهدف: فجّر الباب"
    },
    obj_try_again = {
        en = "Objective: TRY AGAIN - Pick up the cannonball",
        zh = "目标：再试一次 - 捡起炮弹",
        ar = "الهدف: حاول مرة أخرى - التقط كرة المدفع"
    },
    door_destroyed = {
        en = "Door destroyed! Head through the opening!",
        zh = "门被摧毁了！穿过开口！",
        ar = "!تم تدمير الباب! توجه عبر الفتحة"
    },
    load_hint = {
        en = "(Drag the cannonball from inventory to the cannon)",
        zh = "（走近大炮或从物品栏拖动）",
        ar = "(امش بالقرب من المدفع أو اسحب من المخزون)"
    },
    blast_door = {
        en = "BLAST THE DOOR!",
        zh = "炸开门！",
        ar = "!فجّر الباب"
    },
    attempts_remaining = {
        en = "Attempts remaining: ",
        zh = "剩余尝试次数：",
        ar = ":المحاولات المتبقية"
    },
    aiming_mode = {
        en = "AIMING MODE: Click to shoot!",
        zh = "瞄准模式：点击射击！",
        ar = "!وضع التصويب: انقر للإطلاق"
    },
    puzzle_failed = {
        en = "PUZZLE FAILED!",
        zh = "谜题失败！",
        ar = "!فشل اللغز"
    },
    cannonball_shattered = {
        en = "The cannonball shattered after 3 misses.",
        zh = "炮弹在3次未命中后破碎了。",
        ar = ".تحطمت كرة المدفع بعد 3 محاولات فاشلة"
    },
    restart_puzzle = {
        en = "RESTART PUZZLE",
        zh = "重新开始谜题",
        ar = "إعادة تشغيل اللغز"
    },
    
    -- Room 2 strings
    room2_title = {
        en = "Room 2: Pressure Plate Bridge",
        zh = "房间2：压力板桥",
        ar = "الغرفة 2: جسر لوحة الضغط"
    },
    room2_objective = {
        en = "Objective: Place blocks on all pressure plates",
        zh = "目标：将方块放置在所有压力板上",
        ar = "الهدف: ضع كتل على جميع ألواح الضغط"
    },
    plates_activated = {
        en = "Plates activated: ",
        zh = "已激活的压力板：",
        ar = ":الألواح المفعلة"
    },
    drag_blocks_hint = {
        en = "Drag blocks by clicking and holding",
        zh = "点击并按住来拖动方块",
        ar = "اسحب الكتل بالنقر والاستمرار"
    },
    bridge_activated = {
        en = "Bridge activated! Cross to the exit!",
        zh = "桥已激活！穿过到出口！",
        ar = "!تم تفعيل الجسر! اعبر إلى المخرج"
    },
    you_fell = {
        en = "YOU FELL!",
        zh = "你掉下去了！",
        ar = "!لقد سقطت"
    },
    fell_died = {
        en = "You fell into the gap and died.",
        zh = "你掉进了缝隙并死亡了。",
        ar = ".سقطت في الفجوة ومت"
    },
    respawn = {
        en = "RESPAWN",
        zh = "重生",
        ar = "إعادة الظهور"
    },
    
    -- Room 3 strings
    room3_title = {
        en = "Room 3: The Final Chamber",
        zh = "房间3：最终密室",
        ar = "الغرفة 3: الغرفة الأخيرة"
    },
    room3_obj_find_keys = {
        en = "Objective: Find both keys to unlock the exit",
        zh = "目标：找到两把钥匙解锁出口",
        ar = "الهدف: ابحث عن كلا المفتاحين لفتح المخرج"
    },
    room3_obj_exit = {
        en = "Objective: Exit through the door!",
        zh = "目标：从门离开！",
        ar = "!الهدف: اخرج من الباب"
    },
    room3_keys_collected = {
        en = "Keys collected: ",
        zh = "已收集的钥匙：",
        ar = ":المفاتيح المجمعة"
    },
    room3_door_unlocked = {
        en = "Door unlocked! Exit is open!",
        zh = "门已解锁！出口已打开！",
        ar = "!الباب مفتوح! المخرج مفتوح"
    },
    
    -- Ending strings
    victory_message = {
        en = "VICTORY!",
        zh = "胜利！",
        ar = "!النصر"
    },
    you_escaped = {
        en = "You escaped the chambers!",
        zh = "你逃出了房间！",
        ar = "!لقد هربت من الغرف"
    },
    thanks_playing = {
        en = "Thanks for playing!",
        zh = "感谢游玩！",
        ar = "!شكرا للعب"
    },
    press_esc_exit = {
        en = "Press ESC to exit",
        zh = "按 ESC 退出",
        ar = "ESC اضغط على للخروج"
    },
    
    -- Interaction messages
    interact_cannonball = {
        en = "Press E to pick up Cannonball",
        zh = "按 E 拾取炮弹",
        ar = "E اضغط على لالتقاط كرة المدفع"
    },
    interact_load = {
        en = "Press E to load Cannonball",
        zh = "按 E 装载炮弹",
        ar = "E اضغط على لتحميل كرة المدفع"
    },
    interact_aim = {
        en = "Press E to aim",
        zh = "按 E 瞄准",
        ar = "E اضغط على للتصويب"
    },
    interact_door = {
        en = "Press E to enter door",
        zh = "按 E 进入门",
        ar = "E اضغط على لدخول الباب"
    },
    cannonball_collected = {
        en = "Cannonball collected!",
        zh = "炮弹已收集！",
        ar = "!تم جمع كرة المدفع"
    },
    cannon_loaded = {
        en = "Cannon loaded! Click to aim and fire.",
        zh = "大炮已装填！点击瞄准并开火。",
        ar = ".المدفع محمّل! انقر للتصويب والإطلاق"
    },
    puzzle_restarted = {
        en = "Puzzle restarted!",
        zh = "谜题已重新开始！",
        ar = "!تم إعادة تشغيل اللغز"
    },
    walking_to_cannon = {
        en = "Walking to cannon to load...",
        zh = "正在走向大炮装填...",
        ar = "...المشي إلى المدفع للتحميل"
    },
    too_far_cannon = {
        en = "Too far from cannon to load!",
        zh = "离大炮太远无法装填！",
        ar = "!بعيد جدًا عن المدفع للتحميل"
    },
    cannon_already_loaded = {
        en = "Cannon is already loaded!",
        zh = "大炮已经装填了！",
        ar = "!المدفع محمّل بالفعل"
    },
    cant_use_here = {
        en = "Can't use that here.",
        zh = "无法在这里使用。",
        ar = ".لا يمكن استخدام ذلك هنا"
    },
    picked_up_key = {
        en = "You picked up a key!",
        zh = "你拾取了一把钥匙！",
        ar = "!لقد التقطت مفتاحًا"
    },
    fell_into_gap = {
        en = "You fell into the gap!",
        zh = "你掉进了缝隙！",
        ar = "!لقد سقطت في الفجوة"
    },
    respawned = {
        en = "Respawned! Be careful not to fall.",
        zh = "已重生！小心不要掉下去。",
        ar = ".تم إعادة الظهور! كن حذرًا من السقوط"
    },
    item_doesnt_work = {
        en = "That item doesn't work here.",
        zh = "这个物品在这里不起作用。",
        ar = ".هذا العنصر لا يعمل هنا"
    },
    -- Item names
    item_cannonball = {
        en = "Cannonball",
        zh = "炮弹",
        ar = "كرة المدفع"
    },
    item_key = {
        en = "Key",
        zh = "钥匙",
        ar = "مفتاح"
    },
    item_key_room1 = {
        en = "Room 1 Key",
        zh = "房间1钥匙",
        ar = "مفتاح الغرفة 1"
    },
    item_key_room3 = {
        en = "Room 3 Key",
        zh = "房间3钥匙",
        ar = "مفتاح الغرفة 3"
    },
    item_box = {
        en = "Box",
        zh = "箱子",
        ar = "صندوق"
    },
}

-- Get translated string
function Localization:get(key)
    local translations = self.strings[key]
    if not translations then
        return key  -- Return key if translation not found
    end
    return translations[self.currentLanguage] or translations["en"] or key
end

-- Set current language
function Localization:setLanguage(lang)
    if self.languages[lang] then
        self.currentLanguage = lang
        love.graphics.setFont(self:getFont())
        print("Language set to: " .. self.languages[lang])
    else
        print("Language not found: " .. tostring(lang))
    end
end

-- Get current language
function Localization:getLanguage()
    return self.currentLanguage
end

-- Get language name
function Localization:getLanguageName(lang)
    return self.languages[lang or self.currentLanguage] or "Unknown"
end

-- Check if current language is RTL
function Localization:isRTL()
    return self.textDirection[self.currentLanguage] == "rtl"
end

-- Get all available languages
function Localization:getAvailableLanguages()
    local langs = {}
    for code, name in pairs(self.languages) do
        table.insert(langs, {code = code, name = name})
    end
    return langs
end

-- Helper function for right-aligned text (for RTL languages)
function Localization:printAligned(text, x, y, width, align)
    -- Set the appropriate font for the current language
    love.graphics.setFont(self:getFont())
    
    if self:isRTL() and (align == "left" or not align) then
        -- For RTL languages, reverse default left alignment to right
        love.graphics.printf(text, x, y, width or love.graphics.getWidth(), "right")
    elseif align then
        love.graphics.printf(text, x, y, width or love.graphics.getWidth(), align)
    else
        love.graphics.print(text, x, y)
    end
end

return Localization
