class pr_MarbleInventory : CustomInventory
{
    Default
    {
        Inventory.PickupMessage "Picked up reactive marble";
        Inventory.PickupSound "misc/grenadepkup";
        Inventory.UseSound "misc/grenadethrow";
        Inventory.MaxAmount 999;
        +INVENTORY.INVBAR;
    }
   States
   {
        Use:
            PSBG A 1 A_FireProjectile("pr_ReactiveMarble", 0, 0, 0, 12);
            stop;
   }

}
