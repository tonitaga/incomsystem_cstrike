#if defined _parse_color_included
	#endinput
#endif

#define _parse_color_included

stock ParseColor_RGB(const colorStr[], Float:color[3])
{
	new tempStr[4];
	
	copy(tempStr, 3, colorStr);
	color[0] = floatstr(tempStr);
	
	copy(tempStr, 3, colorStr[3]);
	color[1] = floatstr(tempStr);
	
	copy(tempStr, 3, colorStr[6]);
	color[2] = floatstr(tempStr);

	for (new i = 0; i < 3; i++)
	{
		if (color[i] > 255.0) color[i] = 255.0;
		if (color[i] < 0.0) color[i] = 0.0;
	}
}