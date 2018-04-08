#include "mta-helper.fx"

texture Tex;
float2 UVScale;

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
	float3 Position : POSITION0;
	float3 Diffuse : COLOR0;
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
	float4 texel = tex2D(TexSampler, PS.TexCoord*UVScale);
	
	texel.rgb *= PS.Diffuse;
	
	return texel;// * PS.Diffuse;
}

technique tec0
{
	pass P0
	{
		//VertexShader = compile vs_2_0 VertexShaderFunction();
        PixelShader = compile ps_2_0 PixelShaderFunction();
	}
}

technique fallback
{
    pass P0
    {
        
    }
}