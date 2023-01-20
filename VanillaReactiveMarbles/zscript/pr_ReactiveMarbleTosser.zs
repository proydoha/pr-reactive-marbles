class pr_ReactiveMarbleTosser
{
    static play void TossAMarble(Actor tosser, bool destroyOnPickup)
    {
        if (!tosser) { return; }
        vector3 spawnPosition = (tosser.pos.x, tosser.pos.y, tosser.pos.z + tosser.height * 2 / 3);
        Actor a = Actor.Spawn("pr_ReactiveMarble", spawnPosition);
        a.Vel3DFromAngle(a.Speed, tosser.angle, tosser.pitch);
        pr_ReactiveMarble marble = pr_ReactiveMarble(a);
        marble.justTossedTimer = 35;
        marble.destroyOnPickup = destroyOnPickup;
    }
}
