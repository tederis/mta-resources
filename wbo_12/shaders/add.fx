#include "mta-helper.fx"

sampler2D InputTexture : register(s0);
texture Tex;
sampler TexSampler = sampler_state
{
    Texture = (Tex);
};

struct VSInput
{
	float3 Position : POSITION0;
	float4 Diffuse : COLOR0;
	//float3 Normal : NORMAL;
	float2 TexCoord : TEXCOORD0;
};

struct PSInput
{
	float4 Position : POSITION0;
	float4 Diffuse : COLOR0;
	float2 TexCoord : TEXCOORD0;
	//float3 WorldNormal : TEXCOORD2;
	//float3 WorldPos : TEXCOORD3;
};

PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;
	
	//MTAFixUpNormal( VS.Normal );
	
	PS.Position = MTACalcScreenPosition ( VS.Position );
	PS.TexCoord = VS.TexCoord;
	PS.Diffuse = MTACalcGTABuildingDiffuse( VS.Diffuse );
	//PS.WorldNormal = MTACalcWorldNormal( VS.Normal );
    //PS.WorldPos = MTACalcWorldPosition( VS.Position );
	
    return PS;
}

float4 PixelShaderFunction(PSInput PS) : COLOR0
{	
	float4 texel = tex2D(TexSampler, PS.TexCoord);
	
	return texel * PS.Diffuse;
}

technique tec0
{
	pass P0
	{
		VertexShader = compile vs_2_0 VertexShaderFunction();
        PixelShader = compile ps_2_0 PixelShaderFunction();
	}
}

technique fallback
{
    pass P0
    {
        
    }
}