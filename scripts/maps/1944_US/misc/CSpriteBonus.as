class SpriteBonus
{
    string model;
    string sprite;
    int points;

    SpriteBonus( string _model, string _sprite, int _points )
    {
        model = _model;
        sprite = _sprite;
        points = _points;
    }
}

final class CSpriteBonus
{
    CSpriteBonus() {}

    int GibBonus;
    float SpriteOffset;
    int BaseScore;
    float SpriteTime;

    private array<SpriteBonus@> bonus_pointers;

    void push_back( SpriteBonus@ ptr )
    {
        g_Game.PrecacheModel( ptr.sprite );
        g_Game.PrecacheGeneric( ptr.sprite );

        bonus_pointers.insertLast( ptr );
    }

    void MonsterKilled( CBaseMonster@ monster, CBaseEntity@ attacker, bool gib )
    {
        if( monster is null || attacker is null || !attacker.IsPlayer() )
            return;

        int ScoreToPlayer = BaseScore;

        for( uint ui = 0; ui < bonus_pointers.length(); ui++ )
        {
            SpriteBonus@ ptr = bonus_pointers[ui];

            if( ptr is null || ptr.model != monster.pev.model )
                continue;

            Vector position = monster.EyePosition();

            position[2] += SpriteOffset;

            auto sprite = g_EntityFuncs.CreateSprite( ptr.sprite, position, true );

            if( sprite !is null )
            {
                sprite.AnimateAndDie( 10.0f );
                sprite.pev.dmgtime = g_Engine.time + SpriteTime;
                sprite.pev.rendermode = kRenderTransAdd;
                sprite.pev.renderamt = 80;
                sprite.pev.rendercolor = Vector( 255, 0, 0 );

                ScoreToPlayer = ptr.points;
            }
        }

        if( gib && GibBonus > 0 )
        {
            ScoreToPlayer += GibBonus;
        }

        if( ScoreToPlayer > 0 )
        {
            auto player = cast<CBasePlayer>( attacker );

            if( player !is null )
            {
                player.AddPoints( ScoreToPlayer, false );
            }
        }
    }
};

CSpriteBonus g_SpriteBonus;
