/*
*/

#include "misc/CAmbience"
#include "misc/CSpriteBonus"

void MapInit()
{
    @g_Ambience = CAmbience( 3 ); // Number of ambience instances.
    g_Ambience.MapInit();

    // Bonus for gib
    g_SpriteBonus.GibBonus = 20;
    // Offset above the head for the sprite to display
    g_SpriteBonus.SpriteOffset = 32;
    // Base score for unregistered bonus
    g_SpriteBonus.BaseScore = 25;
    // Sprite life time
    g_SpriteBonus.SpriteTime = 1.5;

    g_Hooks.RegisterHook( Hooks::Monster::MonsterKilled, @MonsterKilled );

    SpriteBonus@ pDefault = SpriteBonus(
        // Model to identify the killed entity
        "models/scientist.mdl",
        // Sprite to display
        "sprites/zode/blocker.spr",
        // Number of points provided to the killer
        50
    );
    g_SpriteBonus.push_back( pDefault );

#if SERVER
    g_Game.PrecacheOther( "monster_human_grunt" );
    g_Game.PrecacheOther( "monster_barney" );
    g_Game.PrecacheOther( "monster_scientist" );
#endif

    g_SpriteBonus.push_back( SpriteBonus( "models/barney.mdl", "sprites/zode/rusher.spr", 100 ) );
    g_SpriteBonus.push_back( SpriteBonus( "models/hgrunt.mdl", "sprites/zode/suspect.spr", 150 ) );
}

void MapStart()
{
}

void MapActivate()
{
    g_Ambience.MapActivate();
}

HookReturnCode MonsterKilled( CBaseMonster@ monster, CBaseEntity@ attacker, int gib )
{
    g_SpriteBonus.MonsterKilled( monster, attacker, ( gib != 0 ) );
    return HOOK_HANDLED;
}