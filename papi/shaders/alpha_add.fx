#include "mta-helper.fx"

texture Tex0;
sampler Sampler0 = sampler_state
{
    Texture = (Tex0);
};

struct VSInput
{
    float3 Position : POSITION;
    float4 Diffuse  : COLOR0;
    float2 TexCoord : TEXCOORD0;
};
 
struct PSInput
{
  float4 Position : POSITION0;
  float4 Diffuse  : COLOR0;
  float2 TexCoord : TEXCOORD0;
};
 
PSInput VertexShaderExample(VSInput VS)
{
    PSInput PS = (PSInput)0;
 
    PS.Position = MTACalcScreenPosition ( VS.Position );
	
    PS.Diffuse = VS.Diffuse;
	
	PS.TexCoord = VS.TexCoord;
 
    return PS;
}
 
float4 PixelShaderExample(PSInput PS) : COLOR0
{
    float4 texel = tex2D(Sampler0, PS.TexCoord);
	
	float4 finalColor = texel * PS.Diffuse;
 
	return finalColor;
} 

technique complercated
{
    pass P0
    {
		//SrcBlend = One; 
		//DestBlend = One;
		
		ALPHAREF = 0;
		
        VertexShader = compile vs_2_0 VertexShaderExample();
        PixelShader  = compile ps_2_0 PixelShaderExample();
    }
}