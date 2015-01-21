//XEH_postInit.sqf
//#define DEBUG_MODE_FULL
#include "script_component.hpp"
"ACE_WIND_PARAMS" addPublicVariableEventHandler { GVAR(wind_period_start_time) = time; };
"ACE_RAIN_PARAMS" addPublicVariableEventHandler { GVAR(rain_period_start_time) = time; };
"ACE_MISC_PARAMS" addPublicVariableEventHandler {
    if !(isServer) then {
        30 setLightnings (ACE_MISC_PARAMS select 0);
        30 setRainbow    (ACE_MISC_PARAMS select 1);
        30 setFog        (ACE_MISC_PARAMS select 2);
    };
};


// Update Wind
simulWeatherSync;
_fnc_updateWind = {
    ACE_wind = [] call FUNC(getWind);
    setWind [ACE_wind select 0, ACE_wind select 1, true];
    2 setGusts 0;

    // Set waves: 0 when no wind, 1 when wind >= 16 m/s
    1 setWaves (((vectorMagnitude ACE_wind) / 16.0) min 1.0);

    //systemChat format ["w:%1 %2,ACE_w:%1 %2, w", [wind select 0, wind select 1, ACE_wind select 0, ACE_wind select 1]];
};
[_fnc_updateWind, 1, []] call CBA_fnc_addPerFrameHandler;


// Update Rain
_fnc_updateRain = {
    if(GVAR(enableRain)) then {
        if(!isNil "ACE_RAIN_PARAMS" && {!isNil QGVAR(rain_period_start_time)}) then {
            _oldStrength = ACE_RAIN_PARAMS select 0;
            _rainStrength = ACE_RAIN_PARAMS select 1;
            _transitionTime = ACE_RAIN_PARAMS select 2;
            _periodPosition = (time - GVAR(rain_period_start_time)) min _transitionTime;
            _periodPercent = (_periodPosition/_transitionTime) min 1;

            0 setRain ((_periodPercent*(_rainStrength-_oldStrength))+_oldStrength);
        };
    };
};
[_fnc_updateRain, 2, []] call CBA_fnc_addPerFrameHandler;


// Update Temperature
_fnc_updateTemperature = {
    _annualCoef = 0.5 - 0.5 * cos(360 * dateToNumber date);
    _dailyTempMean =      GVAR(TempMeanJan)      * (1 - _annualCoef) + GVAR(TempMeanJul)      * _annualCoef;
    _dailyTempAmplitude = GVAR(TempAmplitudeJan) * (1 - _annualCoef) + GVAR(TempAmplitudeJul) * _annualCoef;

    _hourlyCoef = -0.5 * sin(360 * ((3 + (date select 3))/24 + (date select 4)/1440));

    GVAR(currentTemperature) = _dailyTempMean + _hourlyCoef * _dailyTempAmplitude - 2 * humidity - 4 * overcast;
    GVAR(currentRelativeDensity) = (273.15 + 20) / (273.15 + GVAR(currentTemperature));
};
[_fnc_updateTemperature, 20, []] call CBA_fnc_addPerFrameHandler;