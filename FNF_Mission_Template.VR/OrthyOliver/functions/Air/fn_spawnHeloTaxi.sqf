/*
    OO_fnc_spawnHeloTaxi
    [_heliClass, _side, _posStart, _posMid, _posEnd, _waitSec, _alt] call OO_fnc_spawnHeloTaxi;
*/

if (!canSuspend) exitWith { _this spawn OO_fnc_spawnHeloTaxi; };

params [
    ["_heliClass","B_Heli_Transport_01_F"],
    ["_side",west],
    ["_posStart",[0,0,0]],
    ["_posMid",[100,100,0]],   // Landing zone
    ["_posEnd",[200,200,0]],   // Final destination
    ["_waitSec",10],
    ["_alt",80]
];

if (!isServer) exitWith {};

// Spawn heli + crew
private _spawn = [_posStart, 0, _heliClass, _side] call BIS_fnc_spawnVehicle;
private _veh   = _spawn select 0;
private _grp   = _spawn select 2;

// AI setup
_veh allowDamage false;
_veh flyInHeight _alt;
{ _x setBehaviour "CARELESS"; _x allowFleeing 0; _x allowDamage false } forEach units _grp;

//_veh removeWeaponTurret["LMG_Minigun_Transport", [1]];
//_veh removeWeaponTurret["LMG_Minigun_Transport2", [2]];

// Create fake heli-pad
private _pad = createVehicle ["Land_HelipadEmpty_F", _posMid, [], 0, "CAN_COLLIDE"];

// Move to the Landing Location
(driver _veh) doMove _posMid; 
_veh flyInHeight 15;

// precise waypoint onto the pad
private _wp = _grp addWaypoint [getPosATL _pad, 0];
_wp setWaypointType "MOVE";
_wp setWaypointCompletionRadius 3;
_wp setWaypointStatements ["true", "(vehicle this) land 'GET OUT';"];

// wait until it actually touches down on/near pad
waitUntil {
    sleep 0.5;
    !alive _veh || (isTouchingGround _veh && {_veh distance2D _pad < 6})
};

// hold for _waitSec seconds
sleep _waitSec;

// take off and proceed
(vehicle _veh) land "NONE";
_veh flyInHeight _alt;
(driver _veh) doMove _posEnd;

//Cleanup the heli-pad
deleteVehicle _pad;

waitUntil {
    sleep 1;
    !alive _veh || (_veh distance2D _posEnd < 50)
};
deleteVehicle _veh;
