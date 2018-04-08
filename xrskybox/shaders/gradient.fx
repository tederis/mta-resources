/************************************************
** by XRAY
** Все права сохранены за автором
************************************************/

float4 startColor;
float4 endColor;

float4 PixelShaderFunction(float2 TexCoord : TEXCOORD0) : COLOR
{
	return startColor* (1.0f - TexCoord.x)+endColor * TexCoord.x;
}

technique tec0
{
	pass P0
	{
        PixelShader = compile ps_2_0 PixelShaderFunction();
	}
}

technique fallback
{
    pass P0
    {
        
    }
}