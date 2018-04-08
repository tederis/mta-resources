#include "mta-helper.fx"

texture Tex;
texture Tex2;
float2 UVScale = float2(1,4);

sampler TexSampler = sampler_state
{
    Texture = (gTexture0);
};
sampler TexSampler2 = sampler_state
{
    Texture = (Tex);
};
sampler TexSampler3 = sampler_state
{
    Texture = (Tex2);
};

struct VSInput
{
	float3 Position : POSITION0;
	float4 Diffuse : COLOR0;
	float3 Normal : NORMAL;
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
	
	MTAFixUpNormal( VS.Normal );
	
	PS.Position = MTACalcScreenPosition ( VS.Position );
	PS.TexCoord = VS.TexCoord;
	PS.Diffuse = MTACalcGTABuildingDiffuse( VS.Diffuse );
	//PS.WorldNormal = MTACalcWorldNormal( VS.Normal );
    //PS.WorldPos = MTACalcWorldPosition( VS.Position );
	
    return PS;
}

float4 blend(float4 overlying, float4 underlying)
{
 float3 blended = overlying.rgb + 
        ((1-overlying.a)*underlying.rgb); 
 float alpha = underlying.a + 
         (1-underlying.a)*overlying.a;
 return float4(blended, alpha);
}

float4 PixelShaderFunction(PSInput PS) : COLOR0
{	
	float4 texel = tex2D(TexSampler2, PS.TexCoord*UVScale);
	float4 texel2 = tex2D(TexSampler3, PS.TexCoord*UVScale);
	
	//float4 texel = 0;
	
	//texel.rgb * PS.Diffuse;
	
	texel *= texel2.a;
	
	return texel;
}

technique tec0
{	
	pass P0
	{	

		//ZEnable          = TRUE; 
		//ZWriteEnable    = FALSE; 
		//CullMode        = NONE;
		//AlphaBlendEnable = TRUE; 
		//DestBlend = INVSRCALPHA;
		
		ZEnable = false;  
        ZWriteEnable = false;  
        AlphaBlendEnable = true;  
       SrcBlend = SrcAlpha;
        DestBlend = InvSrcAlpha;
		
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