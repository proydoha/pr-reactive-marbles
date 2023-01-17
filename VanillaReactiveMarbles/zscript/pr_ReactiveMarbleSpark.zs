class pr_MarbleSpark: Actor
{
    Default
    {
        +NOBLOCKMAP
        +NOGRAVITY
        +ALLOWPARTICLES
        +RANDOMIZE
        +ZDOOMTRANS
        RenderStyle "Translucent";
        Alpha 0.5;
        VSpeed 1;
        Mass 5;
    }
    States
    {
    Spawn:
        PUFF A 4 Bright;
        PUFF BCD 4;
        Stop;
    }
}
