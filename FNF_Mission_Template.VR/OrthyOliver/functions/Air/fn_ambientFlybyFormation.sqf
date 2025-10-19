/*
    OO_fnc_ambientFlybyFormation
    Spawns N aircraft in a side-by-side formation centered on startPos
    and flies them to endPos using BIS_fnc_ambientFlyby.

    Params:
      0: ARRAY  startPos  (ATL)
      1: ARRAY  endPos    (ATL)
      2: NUMBER count     - number of aircraft
      3: NUMBER spacing   - distance between aircraft (meters)
      4: NUMBER altitude  - flight altitude
      5: STRING speedMode - "LIMITED", "NORMAL", or "FULL"
      6: STRING classname - aircraft class
      7: SIDE   side      - WEST, EAST, etc.

    Example:
      [getMarkerPos "START", getMarkerPos "END", 5, 60, 300, "FULL", "B_Plane_Fighter_01_F", WEST]
        call OO_fnc_ambientFlybyFormation;
*/

if (!isServer) exitWith {};
if (!canSuspend) exitWith { _this spawn OO_fnc_ambientFlybyFormation; };

private _startPos  = _this param [0, [0,0,0]];
private _endPos    = _this param [1, [100,0,0]];
private _count     = _this param [2, 1];
private _spacing   = _this param [3, 50];
private _altitude  = _this param [4, 300];
private _speedMode = _this param [5, "NORMAL"];
private _class     = _this param [6, "B_Plane_Fighter_01_F"];
private _side      = _this param [7, west];

_count = _count max 1;
_spacing = _spacing max 0;

// Direction and perpendicular vectors
private _dir = vectorNormalized (_endPos vectorDiff _startPos);
private _right = [ -(_dir select 1), (_dir select 0), 0 ];
private _half = (_count - 1) / 2;

for "_i" from 0 to (_count - 1) do {
    private _k = _i - _half;
    private _offset = _right vectorMultiply (_k * _spacing);
    private _s = _startPos vectorAdd _offset;
    private _e = _endPos vectorAdd _offset;

    _s set [2, (_altitude max 5)];
    _e set [2, (_altitude max 5)];

    [_s, _e, _altitude, _speedMode, _class, _side] call BIS_fnc_ambientFlyby;

    sleep 0.2; // delay between each aircraft spawn
};
