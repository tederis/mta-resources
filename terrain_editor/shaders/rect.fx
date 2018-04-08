#include "mta-helper.fx"

struct VSInput
{
	float3 Position : POSITION0;
	float4 Diffuse : COLOR0;
	float2 TexCoord : TEXCOORD0;
};

struct PSInput
{
	float3 Position : POSITION0;
	float3 Diffuse : COLOR0;
	float2 TexCoord : TEXCOORD0;
};

PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;
	
	//MTAFixUpNormal( VS.Normal );
	
	PS.Position = MTACalcScreenPosition ( VS.Position );
	PS.TexCoord = VS.TexCoord;
	//PS.Diffuse = MTACalcGTABuildingDiffuse( VS.Diffuse );
	PS.Diffuse = VS.Diffuse;
	//PS.WorldNormal = MTACalcWorldNormal( VS.Normal );
    //PS.WorldPos = MTACalcWorldPosition( VS.Position );
	
    return PS;
}

float4 PixelShaderFunction(PSInput PS) : COLOR0
{	
	return float4(PS.Diffuse, 1);
}

technique tec0
{
	pass P0
	{
		ZEnable=false;
	
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