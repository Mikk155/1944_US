/*
*/

#include "misc/CAmbience"

void MapInit()
{
    @g_Ambience = CAmbience( 3 ); // Number of ambience instances.
    g_Ambience.MapInit();
}

void MapStart()
{
}

void MapActivate()
{
    g_Ambience.MapActivate();
}
