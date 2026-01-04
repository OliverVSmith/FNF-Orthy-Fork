/*
    OO_fnc_attachNamed

    Purpose:
        Server-safe helper to attach a child object to a parent object (or a parent identified
        by a variable name). Intended to be called from the child object's init.

    Behaviour:
        - If called on a non-server machine, the function forwards the attach request to the
          server using the project's existing `remoteExec ['call', 2]` convention and then exits.
        - The server-side code resolves the parent (if a string name is provided it will try
          `missionNamespace getVariable`), waits up to `_timeout` seconds for both objects to exist,
          then performs `attachTo` (optionally to a memory point) and stores a variable on the child
          to indicate attachment.

    Params (all passed as positional params):
        0: OBJECT - Child object (normally `this` when called from the child's init)
        1: OBJECT or STRING - Parent object OR the name of a missionNamespace variable that holds the parent
        2: STRING (optional) - Memory point on the parent to attach to (use empty string to attach to origin)
        3: NUMBER (optional) - Timeout (seconds) to wait for parent/child existence; default 10

    Example usage (in child's init):
        // Preferred: pass the parent object directly
        this spawn { params ["_child"]; [_child, parentObject, "seat_1", 10] call OO_fnc_attachNamed; };

        // Or pass the parent's missionNamespace variable name (server must have that var set):
        this spawn { params ["_child"]; [_child, "myParentVarName", "seat_1", 10] call OO_fnc_attachNamed; };

    Notes:
        - For reliable name resolution on the server, ensure the parent object is stored in
          `missionNamespace` using `missionNamespace setVariable ["myParentVarName", parentObject, true];`
        - The function marks the child with `setVariable ["OO_attachedTo", parent, true]` after attach.
        - This helper uses a remoteExec 'call' code-block to avoid requiring CfgFunctions registration.

*/

params ["_child", "_parentRef", "_memoryPoint", "_timeout"];

if (isNil "_memoryPoint") then {_memoryPoint = ""};
if (isNil "_timeout") then {_timeout = 10};

// If parent passed as string, we'll try to resolve via missionNamespace on the caller first
_parentObj = if (typeName _parentRef isEqualTo "STRING") then { missionNamespace getVariable [_parentRef, objNull] } else { _parentRef };

// If we're not on the dedicated server, forward the attach request to the server and exit.
if (not isServer) then {
    // Use the project's established remoteExec 'call' pattern: [paramsArray, codeBlock] remoteExec ['call', 2];
    [ [_child, _parentRef, _memoryPoint, _timeout], {
        params ["_childSrv", "_parentRefSrv", "_memoryPointSrv", "_timeoutSrv"];

        // Resolve parent on server if name was provided
        _parentSrv = if (typeName _parentRefSrv isEqualTo "STRING") then { missionNamespace getVariable [_parentRefSrv, objNull] } else { _parentRefSrv };

        // Wait until both objects exist (or timeout)
        _t = 0;
        while { (_t < _timeoutSrv) && { (isNull _childSrv) || (isNull _parentSrv) } } do {
            sleep 0.2;
            _t = _t + 0.2;
            if (typeName _parentRefSrv isEqualTo "STRING") then { _parentSrv = missionNamespace getVariable [_parentRefSrv, objNull]; };
        };

        if (isNull _childSrv) then {
            diag_log format ["OO_fnc_attachNamed (server): child is null, aborting attach for parent '%1'", _parentRefSrv];
            exitWith {};
        };

        if (isNull _parentSrv) then {
            diag_log format ["OO_fnc_attachNamed (server): parent '%1' not found on server, aborting attach", _parentRefSrv];
            exitWith {};
        };

        // Perform attach
        if (_memoryPointSrv isEqualTo "") then {
            _childSrv attachTo _parentSrv;
        } else {
            _childSrv attachTo [_parentSrv, _memoryPointSrv];
        };

        // Mark the child for other scripts if needed
        _childSrv setVariable ["OO_attachedTo", _parentSrv, true];
        diag_log format ["OO_fnc_attachNamed (server): Attached %1 to %2 (mp:%3)", _childSrv, _parentSrv, _memoryPointSrv];

    } ] remoteExec ['call', 2];

    // Local caller should exit after forwarding the request
    exitWith {};
};

// If we reach here, we are running on the server already — perform attach directly.

// If parent ref was a string, try to resolve it on server
if (typeName _parentRef isEqualTo "STRING") then { _parentObj = missionNamespace getVariable [_parentRef, objNull]; };

// Wait for both objects to exist up to timeout
_t = 0;
while { (_t < _timeout) && { (isNull _child) || (isNull _parentObj) } } do {
    sleep 0.2;
    _t = _t + 0.2;
    if (typeName _parentRef isEqualTo "STRING") then { _parentObj = missionNamespace getVariable [_parentRef, objNull]; };
};

if (isNull _child) exitWith { diag_log format ["OO_fnc_attachNamed: child is null, abort"]; };
if (isNull _parentObj) then { diag_log format ["OO_fnc_attachNamed: parent '%1' not found on server, abort", _parentRef]; exitWith {}; };

if (_memoryPoint isEqualTo "") then {
    _child attachTo _parentObj;
} else {
    _child attachTo [_parentObj, _memoryPoint];
};

_child setVariable ["OO_attachedTo", _parentObj, true];
diag_log format ["OO_fnc_attachNamed: Attached %1 to %2 (mp:%3)", _child, _parentObj, _memoryPoint];
