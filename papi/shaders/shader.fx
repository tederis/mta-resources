#include "mta-helper.fx"

texture gDepthBuffer : DEPTHBUFFER;
matrix gProjectionMainScene : PROJECTION_MAIN_SCENE;
 
sampler SamplerDepth = sampler_state
{
    Texture     = (gDepthBuffer);
    AddressU    = Clamp;
    AddressV    = Clamp;
};

texture ScreenTex;
texture TargetTex;

sampler ScreenSampler = sampler_state
{
    Texture = (ScreenTex);
};
sampler TargetSampler = sampler_state
{
    Texture = (TargetTex);
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
 
//-----------------------------------------------------------------------------
//-- Get value from the depth buffer
//-- Uses define set at compile time to handle RAWZ special case (which will use up a few more slots)
//-----------------------------------------------------------------------------
float FetchDepthBufferValue( float2 uv )
{
    float4 texel = tex2D(SamplerDepth, uv);
#if IS_DEPTHBUFFER_RAWZ
    float3 rawval = floor(255.0 * texel.arg + 0.5);
    float3 valueScaler = float3(0.996093809371817670572857294849, 0.0038909914428586627756752238080039, 1.5199185323666651467481343000015e-5);
    return dot(rawval, valueScaler / 255.0);
#else
    return texel.r;
#endif
}
 
//-----------------------------------------------------------------------------
//-- Use the last scene projecion matrix to linearize the depth value a bit more
//-----------------------------------------------------------------------------
float Linearize(float posZ)
{
    return gProjectionMainScene[3][2] / (posZ - gProjectionMainScene[2][2]);
}

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
	float BufferValue = FetchDepthBufferValue( PS.TexCoord );
    float Depth = Linearize( BufferValue );
 
    //-- Multiply Depth to get the spread you want
    Depth /= 12.0f;

	float4 target = tex2D(TargetSampler, PS.TexCoord);
	float2 offset = target.xy*0.5f;
    float4 screen = tex2D(ScreenSampler, PS.TexCoord+offset);
	
	float4 finalColor = screen;
 
 
	return finalColor;
} 

technique complercated
{
    pass P0
    {
        VertexShader = compile vs_2_0 VertexShaderExample();
        PixelShader  = compile ps_2_0 PixelShaderExample();
    }
}