/*
    OO_fnc_markerExplodeSequence
    Triggers explosions at a list of marker positions, in order, with optional delay.

    Params (server-side):
      0: ARRAY of STRINGs - marker names, e.g. ["MX_1","MX_2","MX_3"]
      1: STRING            - ammo/explosion class (default "Bo_GBU12_LGB")
      2: NUMBER            - delay between blasts in seconds (default 0)
      3: NUMBER            - altitude offset added to z (ATL) (default 0)

    Examples:
      [ ["MX_1","MX_2","MX_3"], "Bo_GBU12_LGB", 0.2, 0 ] call OO_fnc_markerExplodeSequence;
      [ ["BLAST_A","BLAST_B"], "DemoCharge_Remote_Ammo", 0, 0 ] call OO_fnc_markerExplodeSequence;

    Notes:
      - Use on the server (vehicles/ammo should be created server-side).
      - If called unscheduled (e.g., via remoteExecCall), this function re-spawns itself scheduled.
*/

if (!isServer) exitWith {};
if (!canSuspend) exitWith { _this spawn OO_fnc_markerExplodeSequence; };

// ---- parameter handling (plain selects for maximum compatibility) ----
private _markerNames = if (count _this > 0) then { _this select 0 } else { [] };
private _ammoClass   = if (count _this > 1) then { _this select 1 } else { "Bo_GBU12_LGB" };
private _delay       = if (count _this > 2) then { _this select 2 } else { 0 };
private _altOffset   = if (count _this > 3) then { _this select 3 } else { 0 };

// ---- build list of valid markers (getMarkerColor returns "" if marker doesn't exist) ----
private _valid = [];
private _i = 0;
private _n = count _markerNames;

while { _i < _n } do {
    private _name = _markerNames select _i;
    if ((getMarkerColor _name) != "") then {
        _valid set [count _valid, _name];
    };
    _i = _i + 1;
};

if ((count _valid) == 0) exitWith {
    diag_log "OO_fnc_markerExplodeSequence: No valid markers found.";
};

// ---- detonate along the valid markers ----
_i = 0;
_n = count _valid;

while { _i < _n } do {
    private _m   = _valid select _i;
    private _pos = getMarkerPos _m;   // ATL (z often 0)

    // Ensure z is non-negative and apply optional airburst offset (e.g., 5 for 5m airburst)
    private _z = 0;
    if ((count _pos) > 2) then { _z = _pos select 2; };
    _pos set [2, (_z max 0) + _altOffset];

    // Create ammo; many ammo classes detonate immediately when spawned
    private _bang = createVehicle [_ammoClass, _pos, [], 0, "CAN_COLLIDE"];

    // Give a tiny downward velocity to ensure consistent detonation/fall behavior
    _bang setVelocity [0, 0, -3];

    // Inter-blast delay (skip after the last one)
    if (_delay > 0 && _i < (_n - 1)) then { sleep _delay; };

    _i = _i + 1;
};
