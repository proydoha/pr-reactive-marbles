class pr_HfReactiveMarble: Actor
{
    bool wasDamaged;
    int firstDamage;
    Name firstDamageType;
    int firstLeakyness;

    Default
    {
        Radius 16;
        Height 48;
        Health 2000;
        +SOLID;
        +SHOOTABLE;
    }

    States
    {
        Spawn:
        COLU A 4 Bright;
        COLU A 4;
        TNT1 A 0 A_JumpIfHealthLower(2000, "Deteriorate");
        Loop;

        Deteriorate:
        COLU A 1 Bright;
        TNT1 A 0 A_ProduceSmoke();
        TNT1 A 0 A_MakeLeakySparks();
        TNT1 A 0 A_DamageSelf(firstDamage, firstDamageType);
        Loop;

        Death:
        TNT1 A 0 A_SpawnItemEx("pr_MarbleSpark");
        TNT1 A 0 A_StartSound("pr_Marble/Crack", CHAN_AUTO, CHANF_NOSTOP);
        COLU A 1 Bright;
        Stop;
    }

    action void A_ProduceSmoke()
    {
        self.A_SpawnItemEx("pr_MarbleSmoke", 0, 0, 0, random(-1, 1), random(-1, 1), random(0, 1));
        self.A_StartSound("pr_Marble/Fuse", CHAN_AUTO, CHANF_LOOPING);
    }

    action void A_MakeLeakySparks()
    {
        //Three times as likely to crackle
        int probabilityModifier = 3;
        int randomValue = random(0, 255);
        pr_HfReactiveMarble thisMarble = pr_HfReactiveMarble(self);
        if (randomValue < thisMarble.firstLeakyness * probabilityModifier)
        {
            self.A_SpawnItemEx("pr_MarbleSpark", 0, 0, 0, FRandom(-0.5, 0.5), FRandom(-0.5, 0.5), FRandom(0, 0.5));
            self.A_StartSound("pr_Marble/Crack", CHAN_AUTO, CHANF_NOSTOP);
        }
    }

    override void PostBeginPlay()
    {
        wasDamaged = false;
        firstDamage = 1;
        firstLeakyness = 0;
        firstDamageType = "None";
    }

    override void Tick()
	{
        Super.Tick();
        ApplyHurtFloorDamage(self.CurSector);
        Apply3DHurtFloorDamage(self.CurSector);
        ApplyTerrainDamage(self.CurSector);
    }

    override int DamageMobj(Actor inflictor, Actor source, int damage, Name mod, int flags, double angle)
    {
        int damage = Super.DamageMobj(inflictor, source, damage, mod, flags, angle);
        if (!wasDamaged)
        {
            wasDamaged = true;
            firstDamage = damage;
            firstDamageType = mod;
        }
        return damage;
    }

    void ApplyHurtFloorDamage(Sector s)
    {
        if (s.damageamount == 0) { return; }
        if (s.damageinterval == 0) { return; }
        if (level.Time % s.damageinterval == 0)
        {
            if (!wasDamaged)
            {
                firstLeakyness = s.leakydamage;
            }
            DamageMobj(self, self, s.damageamount, s.damagetype, 0, 0);
        }
    }

    void Apply3DHurtFloorDamage(Sector s)
    {
        Array<F3DFloor> F3DFloors;
        bool duplicateFound;
        for (int i = 0; i < s.Get3DFloorCount(); i++)
        {
            F3DFloor current3dFloor = s.Get3DFloor(i);
            duplicateFound = false;
            for (int j = 0; j < F3DFloors.Size(); j++)
            {
                if (F3DFloors[j].target.Index() == current3dFloor.target.Index()
                    && F3DFloors[j].model.Index() == current3dFloor.model.Index())
                {
                    duplicateFound = true;
                    break;
                }
            }
            if (duplicateFound) { continue; }
            F3DFloors.Push(current3dFloor);
        }

        for (int i = 0; i < F3DFloors.Size(); i++)
        {
            Sector modelSector = F3DFloors[i].model;
            vector2 actorPosition = (self.pos.x, self.pos.y);
            // Can't assign those to variable for some reason ( ? )
            //double 3dFloorTop = modelSector.ceilingplane.ZatPoint(actorPosition);
            //double 3dFloorBottom = modelSector.floorplane.ZatPoint(actorPosition);
            if (modelSector.floorplane.ZatPoint(actorPosition) <= (self.pos.z + self.height)
                && modelSector.ceilingplane.ZatPoint(actorPosition) >= self.pos.z)
            {
                ApplyHurtFloorDamage(modelSector);
            }
        }
        F3DFloors.Clear();
    }

    void ApplyTerrainDamage(Sector s)
    {
        TerrainDef floorTerrain = s.GetFloorTerrain(s.floor);
        if (floorTerrain.TerrainName == "SOLID") { return; }
        if (floorTerrain.DamageAmount == 0) { return; }
        if (level.Time % (floorTerrain.DamageTimeMask + 1) == 0)
        {
            //I don't think terrain can be leaky ( ? )
            DamageMobj(self, self, floorTerrain.DamageAmount, floorTerrain.DamageMOD, 0, 0);
        }
    }
}
