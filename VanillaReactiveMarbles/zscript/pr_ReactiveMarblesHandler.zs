class pr_ReactiveMarblesHandler : EventHandler
{
    override void NetworkProcess (ConsoleEvent e)
    {
        PlayerPawn playerActor = players[e.Player].mo;
        if (!playerActor) { return; }
        if (e.Name != "pr_ReactiveMarbleToss") { return; }
        if (!CVar.GetCVar("pr_rm_noinventory", players[e.Player]).GetBool()) { return; }
        pr_ReactiveMarbleTosser.TossAMarble(playerActor, true);
    }

    override void WorldLoaded(WorldEvent e)
    {
        for (int playerNum = 0; playerNum < players.Size(); playerNum++)
        {
            PlayerInfo player = players[playerNum];
            PlayerPawn playerActor = player.mo;
            if (!playerActor) { return; }
            playerActor.A_TakeInventory("pr_ReactiveMarble", 0);
            if (CVar.GetCVar("pr_rm_noinventory", player).GetBool()) { return; }
            playerActor.A_GiveInventory("pr_ReactiveMarble", CVar.GetCVar("pr_rm_startmapamount", player).GetInt());
        }
    }


}
