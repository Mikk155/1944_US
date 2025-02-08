/*
    Author: Mikk
*/

enum CAmbience_e
{
    FileName = 0,
    FileDuration,
};

class CAmbienceInstance
{
    float time = -1;
}

class CAmbience
{
    private bool active = false;
    private CScheduledFunction@ schedule = null;
    private array<CAmbienceInstance@> ambiences = {};
    protected array<array<TValue@>> sounds = {};

    void push_sound( array<TValue@> TValues )
    {
        g_Ambience.sounds.insertLast( TValues );
    }

    protected array<int> positions = {};

    void push_position( int iValue )
    {
        g_Ambience.positions.insertLast( iValue );
    }

    void MapInit()
    {
        if( !active )
        {
            g_CustomEntityFuncs.RegisterCustomEntity( "env_ambience", "env_ambience" );
            g_CustomEntityFuncs.RegisterCustomEntity( "env_ambience_position", "env_ambience_position" );
        }
    }

    void MapActivate()
    {
        if( !active )
        {
            g_CustomEntityFuncs.UnRegisterCustomEntity( "env_ambience" );

            if( this.sounds.length() > 0 )
            {
                @schedule = g_Scheduler.SetInterval( @this, "Think", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES );
            }
        }
    }

    CAmbience( int instances )
    {
        for( int i = 0; i < instances; i++ )
        {
            CAmbienceInstance@ new_instance = CAmbienceInstance();

            if( new_instance !is null )
            {
                ambiences.insertLast( new_instance );
            }
        }
    }

    private void Think()
    {
        for( uint ui = 0; ui < ambiences.length(); ui++ )
        {
            CAmbienceInstance@ ambience_instance = ambiences[ui];

            if( ambience_instance is null )
            {
                ambiences.removeAt(ui);
                continue;
            }

            if( ambience_instance.time > g_Engine.time )
            {
                continue;
            }

            array<TValue@> lt_values = this.sounds[ Math.RandomLong( 0, this.sounds.length() - 1 ) ];

            string s_filename = lt_values[ CAmbience_e::FileName ].String;

            CBaseEntity@ ambience_position = null;

            array<int> positions_copy = this.positions;

            array<int> null_pointers = {};

            while( ambience_position is null )
            {
                if( positions_copy.length() > 0 )
                {
                    int entity_index = Math.RandomLong( 0, positions_copy.length() - 1 );

                    auto entity = g_EntityFuncs.Instance( positions_copy[ entity_index ] );

                    if( entity is null )
                    {
                        null_pointers.insertLast(entity_index);
                    }
                    else if( entity.ObjectCaps() == 1 )
                    {
                        @ambience_position = entity;
                    }
                    else
                    {
                        positions_copy.removeAt( entity_index );
                    }
                }
                else
                {
                    break;
                }
#if DISCARDED
                else if( null_pointers.length() == this.positions.length() ) // Only if entities were null
                {
                    @ambience_position = g_EntityFuncs.Instance(g_EntityFuncs.IndexEnt(0)); // Worldspawn.
                    break;
                }
#endif
            }

            // Remove any null pointers
            for( uint uiptr = 0; ui < null_pointers.length(); uiptr++ )
            {
                auto size_a = this.positions.find( null_pointers[uiptr] );

                if( size_a > 0 ) {
                    this.positions.removeAt( size_a );
                }
            }

            if( ambience_position !is null )
            {
//                g_Game.AlertMessage( at_console, "Playsound " + s_filename + '\n' );
                g_SoundSystem.PlaySound(
                    ambience_position.edict(),/* edict_t@ entity */
                    CHAN_AUTO, /* SOUND_CHANNEL channe */
                    s_filename, /* const string& in sample */
                    Math.RandomFloat( 0.5f, 1.0f ), /* float volume */
                    ATTN_NONE, /* float attenuation */
                    0, /* int flags */
                    PITCH_NORM, /* int pitch */
                    0, /* int target_ent_unreliable */
                    true, /* bool setOrigin */
                    ambience_position.pev.origin /* const Vector& in vecOrigin */
                );
            }

            ambience_instance.time = g_Engine.time + lt_values[ CAmbience_e::FileDuration ].Float;
        }
    }
}

CAmbience@ g_Ambience = null;

class TValue
{
    string String;
    float Float;
    int Int;

    TValue( string value )
    {
        String = value;
        Int = atoi( value );
        Float = atof( value );
    }
}

class env_ambience : ScriptBaseEntity
{
    private array<TValue@> sound_setting = {
        null, /* FileName */
        null /* FileDuration */
    };

    void Spawn()
    {
#if SERVER
        string log;
#endif
        if( sound_setting[ CAmbience_e::FileName ] !is null )
        {
            if( sound_setting[ CAmbience_e::FileDuration ] !is null )
            {
#if SERVER
                snprintf( log, "[CAmbience] [INFO] Inserting config for sound \"%1\"\n", sound_setting[ CAmbience_e::FileName ].String );
#endif
                g_SoundSystem.PrecacheSound( sound_setting[ CAmbience_e::FileName ].String );

                g_Ambience.push_sound( sound_setting );
            }
            else
            {
#if SERVER
                snprintf( log, "[CAmbience] [ERROR] No key-value \"duration\" for env_ambience at %1", self.pev.origin.ToString() );
#endif
            }
        }
        else
        {
#if SERVER
            snprintf( log, "[CAmbience] [ERROR] No key-value \"filename\" for env_ambience at %1", self.pev.origin.ToString() );
#endif
        }
#if SERVER
        g_Game.AlertMessage( at_console, log );
#endif
        g_EntityFuncs.Remove( self ); // Free the slot inmediatelly.
    }

    bool KeyValue( const string& in szKeyName, const string& in szValue )
    {
        if( szKeyName == "filename" )
        {
            @sound_setting[ CAmbience_e::FileName ] = TValue( szValue );
        }
        else if( szKeyName == "duration" )
        {
            @sound_setting[ CAmbience_e::FileDuration ] = TValue( szValue );
        }
        else { return false; }
        return true;
    }
}

class env_ambience_position : ScriptBaseEntity
{
    private bool active = true;

    void Spawn()
    {
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
        self.pev.effects |= EF_NODRAW;

        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( ( self.pev.spawnflags & 1 ) != 0 )
        {
            active = false;
        }

        g_Ambience.push_position( self.entindex() );
    }

    int ObjectCaps()
    {
        return ( active ? 1 : 0 );
    }

    void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
    {
        switch( useType )
        {
            case USE_TOGGLE:
            {
                active = !active;
                break;
            }
            case USE_ON:
            {
                active = true;
                break;
            }
            case USE_OFF:
            {
                active = false;
                break;
            }
            default:
            {
                return;
            }
        }
#if SERVER
        string log;
        snprintf( log, "[CAmbience] [INFO] entity %1 at %2 turn %3\n", self.pev.targetname, self.pev.origin.ToString(), ( active ? "ON" : "OFF" ) );
        g_Game.AlertMessage( at_console, log );
#endif
    }
}
