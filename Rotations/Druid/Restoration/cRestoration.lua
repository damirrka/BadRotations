--- Restoration Class
-- Inherit from: ../cCharacter.lua and ../cDruid.lua
cRestoration = {}
cRestoration.rotations = {}

-- Creates Restoration Druid
function cRestoration:new()
    local self = cDruid:new("Restoration")

    local player = "player" -- if someone forgets ""

    -- Mandatory !
    self.rotations = cRestoration.rotations

-----------------
--- VARIABLES ---
-----------------

    self.spell.spec                 = {}
    self.spell.spec.abilities       = {
        barkskin                    = 22812,
        cenarionWard                = 102351,
        efflorescence               = 145205,
        essenceOfGhanir             = 208253,
        flourish                    = 197721,
        healingTouch                = 5185,
        incarnationTreeOfLife       = 33891,
        innervate                   = 29166,
        ironbark                    = 102342,
        lifebloom                   = 33763,
        naturesCure                 = 88423,
        rejuvenation                = 774,
        renewal                     = 108238,
        revitalize                  = 212040,
        solarWrath                  = 5176,
        sunfire                     = 93402,
        swiftmend                   = 18562,
        tranquility                 = 740,
        ursolsVortex                = 102793,
        wildGrowth                  = 48438,
        yserasGift                  = 145108,
    }
    self.spell.spec.artifacts       = {
        armorOfTheAncients          = 189754,
        artificialDamage            = 213428,
        blessingOfTheWorldTree      = 189744,
        bloomsOfGhanir              = 186393,
        dreamwalker                 = 189849,
        essenceOfGhanir             = 208253,
        essenceOfNordrassil         = 189760,
        ghanirsBloom                = 214913,
        grovewalker                 = 186320,
        infusionOfNature            = 189757,
        knowledgeOfTheAncients      = 189772,
        markOfShifting              = 186372,
        naturalMending              = 189749,
        naturesEssence              = 189787,
        naturesVigor                = 222644,
        persistence                 = 186396,
        powerOfTheArchdruid         = 189870,
        seedsOfTheWorldTree         = 189768,
        tranquilMind                = 189857,
    }
    self.spell.spec.buffs           = {
        cenarionWard                = 102352,
        clearcasting                = 16870,
        germination                 = 155777,
        lifebloom                   = 33763,
        rejuvenation                = 774,
        regrowth                    = 8936,
        soulOfTheForest             = 114108,
    }
    self.spell.spec.debuffs         = {

    }
    self.spell.spec.glyphs          = {

    }
    self.spell.spec.talents         = {
        abundance                   = 207383,
        balanceAffinity             = 197632,
        cenarionWard                = 102351,
        cultivation                 = 200390,
        feralAffinity               = 189760,
        flourish                    = 197721,
        germination                 = 155675,
        guardianAffinity            = 197491,
        incarnationTreeOfLife       = 33891,
        innerPeace                  = 197073,
        momentOfClarity             = 155577,
        renewal                     = 108238,
        soulOfTheForest             = 158478,
        springBlossoms              = 207385,
        stonebark                   = 197061,
    }
    -- Merge all spell ability tables into self.spell
    self.spell = mergeSpellTables(self.spell, self.characterSpell, self.spell.class.abilities, self.spell.spec.abilities)

------------------
--- OOC UPDATE ---
------------------

    function self.updateOOC()
        -- Call classUpdateOOC()
        self.classUpdateOOC()
    end

--------------
--- UPDATE ---
--------------

    function self.update()

        -- Call Base and Class update
        self.classUpdate()
        -- Updates OOC things
        if not UnitAffectingCombat("player") then self.updateOOC() end
        cFileBuild("spec",self)
        self.getToggleModes()

        -- Start selected rotation
        self:startRotation()
    end

---------------
--- TOGGLES ---
---------------

    function self.getToggleModes()

        self.mode.rotation  = br.data["Rotation"]
        self.mode.cooldown  = br.data["Cooldown"]
        self.mode.defensive = br.data["Defensive"]
        self.mode.interrupt = br.data["Interrupt"]
        self.mode.cleave    = br.data["Cleave"]
        self.mode.prowl     = br.data["Prowl"]
    end

    -- Create the toggle defined within rotation files
    function self.createToggles()
        GarbageButtons()
        if self.rotations[br.selectedProfile] ~= nil then
            self.rotations[br.selectedProfile].toggles()
        else
            return
        end
    end

---------------
--- OPTIONS ---
---------------

    -- Creates the option/profile window
    function self.createOptions()
        br.ui.window.profile = br.ui:createProfileWindow(self.profile)

        -- Get the names of all profiles and create rotation dropdown
        local names = {}
        for i=1,#self.rotations do
            tinsert(names, self.rotations[i].name)
        end
        br.ui:createRotationDropdown(br.ui.window.profile.parent, names)

        -- Create Base and Class option table
        local optionTable = {
            {
                [1] = "Base Options",
                [2] = self.createBaseOptions,
            },
            {
                [1] = "Class Options",
                [2] = self.createClassOptions,
            },
        }

        -- Get profile defined options
        local profileTable = profileTable
        if self.rotations[br.selectedProfile] ~= nil then
            profileTable = self.rotations[br.selectedProfile].options()
        else
            return
        end

        -- Only add profile pages if they are found
        if profileTable then
            insertTableIntoTable(optionTable, profileTable)
        end

        -- Create pages dropdown
        br.ui:createPagesDropdown(br.ui.window.profile, optionTable)
        br:checkProfileWindowStatus()
    end

------------------------
--- CUSTOM FUNCTIONS ---
------------------------
    --Target HP
    function thp(unit)
        return getHP(unit)
    end

    --Target Time to Die
    function ttd(unit)
        return getTimeToDie(unit)
    end

    --Target Distance
    function tarDist(unit)
        return getDistance(unit)
    end

    -- Calculate Ferocious Bite Damage
    function getFbDamage(cp)
        local weaponDPS = (select(2,UnitDamage("player")) - select(1,UnitDamage("player"))) / 2
        local weaponDMG = (weaponDPS + UnitAttackPower("player") / 3.5)
        local cp = cp
        if cp == nil then cp = br.player.comboPoints end
        fbD = 0.749 * cp * UnitAttackPower("player") * (1 + (br.player.power - 25) / 25)
        if br.player.inCombat then
            return fbD
        else
            return 0
        end
    end

    function useCleave()
        if self.mode.cleave==1 and self.mode.rotation < 3 then
            return true
        else
            return false
        end
    end

    function useProwl()
        if self.mode.prowl==1 then
            return true
        else
            return false
        end
    end

    function outOfWater()
        if swimTime == nil then swimTime = 0 end
        if outTime == nil then outTime = 0 end
        if IsSwimming() then
            swimTime = GetTime()
            outTime = 0
        end
        if not IsSwimming() then
            outTime = swimTime
            swimTime = 0
        end
        if outTime ~= 0 and swimTime == 0 then
            return true
        end
        if outTime ~= 0 and IsFlying() then
            outTime = 0
            return false
        end
    end

    function safeToHeal(Unit,spellID)
        local hpDeficit = 100 - getHP(Unit)
        local powerCostPercent = (select(1,getSpellCost(spellID)) / UnitPowerMax("player"))*100
        if hpDeficit > powerCostPercent then
            return true
        else
            return false
        end
    end

-----------------------------
--- CALL CREATE FUNCTIONS ---
-----------------------------

    -- Return
    return self
end-- select Druid
