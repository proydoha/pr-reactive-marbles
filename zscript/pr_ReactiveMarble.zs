class pr_ReactiveMarble: Actor
{
    bool wasDamaged;
    int firstDamage;
    Name firstDamageType;
    int firstLeakyness;

    Default
    {
        Radius 8;
        Height 8;
        Health 2000;
        Scale 0.5;
        Tag "Reactive Marble";
        +SHOOTABLE;
        +NOBLOOD;
    }

    States
    {
        Spawn:
            HFRM A 1;
            goto NotRolling;

        NotRolling:
            HFRM A 1 A_ManageMarbleState();
            TNT1 A 0 A_DeteriorateIfDamaged();
            loop;

        Rolling:
            TNT1 A 0 A_FaceMovementDirection();
            HFRM A 4 A_ManageMarbleState();
            TNT1 A 0 A_DeteriorateIfDamaged();
            HFRM B 4 A_ManageMarbleState();
            TNT1 A 0 A_DeteriorateIfDamaged();
            HFRM C 4 A_ManageMarbleState();
            TNT1 A 0 A_DeteriorateIfDamaged();
            HFRM D 4 A_ManageMarbleState();
            TNT1 A 0 A_DeteriorateIfDamaged();
            HFRM E 4 A_ManageMarbleState();
            TNT1 A 0 A_DeteriorateIfDamaged();
            HFRM F 4 A_ManageMarbleState();
            TNT1 A 0 A_DeteriorateIfDamaged();
            HFRM G 4 A_ManageMarbleState();
            TNT1 A 0 A_DeteriorateIfDamaged();
            HFRM H 4 A_ManageMarbleState();
            TNT1 A 0 A_DeteriorateIfDamaged();
            loop;

        Death:
            TNT1 A 0 A_SpawnItemEx("pr_MarbleSpark");
            TNT1 A 0 A_StartSound("pr_Marble/Crack", CHAN_AUTO);
            HFRM A 1 Bright;
            Stop;
    }

    state A_ManageMarbleState()
    {
        double hSpeed = (Vel.x, Vel.y).Length();
        if (hSpeed == 0)
        {
            A_SetTics(1);
        }
        else
        {
            A_SetTics(clamp(1/hSpeed, 1, 8));
        }
        bool isRolling = InStateSequence(CurState, ResolveState("Rolling"));
        bool isNotRolling = InStateSequence(CurState, ResolveState("NotRolling"));
        if (hSpeed == 0 && isRolling) { return ResolveState("NotRolling"); }
        if (hSpeed > 0 && isNotRolling) { return ResolveState("Rolling"); }
        return ResolveState(null);
    }

    void A_DeteriorateIfDamaged()
    {
        if (!wasDamaged) { return; }
        A_ProduceSmoke();
        A_MakeLeakySparks();
        A_DamageSelf(firstDamage, firstDamageType);
    }

    void A_ProduceSmoke()
    {
        A_SpawnItemEx("pr_MarbleSmoke", 0, 0, 0, random(-1, 1), random(-1, 1), random(0, 1));
        A_StartSound("pr_Marble/Fuse", CHAN_AUTO, CHANF_LOOPING);
    }

    void A_MakeLeakySparks()
    {
        //Four times as likely to crackle
        int probabilityModifier = 4;
        int randomValue = random(1, 255);
        if (randomValue > firstLeakyness * probabilityModifier) { return; }
        if (pos.z != curSector.floorplane.ZatPoint((pos.x, pos.y))) { return; }

        A_SpawnItemEx("pr_MarbleSpark", 0, 0, 0, FRandom(-0.5, 0.5), FRandom(-0.5, 0.5), FRandom(0, 0.5));
        A_StartSound("pr_Marble/Crack", CHAN_AUTO);
        Vel = (random(-3, 3), random(-3, 3), random(3, 10));
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
        ApplyHurtFloorDamage(CurSector);
        Apply3DHurtFloorDamage(CurSector);
        ApplyTerrainDamage(CurSector);
    }

    override int DamageMobj(Actor inflictor, Actor source, int damage, Name mod, int flags, double angle)
    {
        int damage = Super.DamageMobj(inflictor, source, damage, mod, flags, angle);
        if (damage <= 0) { return damage; }
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
        bool isOnFloor = (pos.z == curSector.floorplane.ZatPoint((pos.x, pos.y)));
        if (s.damageamount == 0) { return; }
        if (s.damageinterval == 0) { return; }
        if (level.Time % s.damageinterval == 0
            && (waterlevel > 0 || (waterlevel == 0 && isOnFloor)))
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
            vector2 actorPosition = (pos.x, pos.y);
            // Can't assign those to variable for some reason ( ? )
            //double 3dFloorTop = modelSector.ceilingplane.ZatPoint(actorPosition);
            //double 3dFloorBottom = modelSector.floorplane.ZatPoint(actorPosition);
            if (modelSector.floorplane.ZatPoint(actorPosition) <= (pos.z + height)
                && modelSector.ceilingplane.ZatPoint(actorPosition) >= pos.z)
            {
                ApplyHurtFloorDamage(modelSector);
            }
        }
        F3DFloors.Clear();
    }

    void ApplyTerrainDamage(Sector s)
    {
        bool isOnFloor = (pos.z == curSector.floorplane.ZatPoint((pos.x, pos.y)));
        TerrainDef floorTerrain = s.GetFloorTerrain(s.floor);
        if (floorTerrain.TerrainName == "SOLID") { return; }
        if (floorTerrain.DamageAmount == 0) { return; }
        if (level.Time % (floorTerrain.DamageTimeMask + 1) == 0
            && (waterlevel > 0 || (waterlevel == 0 && isOnFloor)))
        {
            //I don't think terrain can be leaky ( ? )
            DamageMobj(self, self, floorTerrain.DamageAmount, floorTerrain.DamageMOD, 0, 0);
        }
    }
}
