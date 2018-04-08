#include "mta-helper.fx"

texture Tex01;
texture Tex02;
texture Tex03;

float2 snowOffset1;
float2 snowOffset2;
float2 snowOffset3;
float snowBright = 0.3;
float snowDepth;

//Depth buffer
texture gDepthBuffer : DEPTHBUFFER;
matrix gProjectionMainScene : PROJECTION_MAIN_SCENE;

sampler SamplerDepth = sampler_state
{
    Texture     = (gDepthBuffer);
    AddressU    = Clamp;
    AddressV    = Clamp;
};

sampler Sampler1 = sampler_state
{
    Texture = (Tex01);
};

sampler Sampler2 = sampler_state
{
    Texture = (Tex02);
};

sampler Sampler3 = sampler_state
{
    Texture = (Tex03);
}; 

//---------------------------------------------------------------------
//-- Structure of data sent to the vertex shader
//---------------------------------------------------------------------
struct VSInput
{
    float3 Position : POSITION;
    float4 Diffuse  : COLOR0;
    float2 TexCoord : TEXCOORD0;
};
 
//---------------------------------------------------------------------
//-- Structure of data sent to the pixel shader ( from the vertex shader )
//---------------------------------------------------------------------
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
    return dot(rawval, ValueScaler / 255.0);
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
 
//-----------------------------------------------------------------------------
//-- VertexShaderExample
//--  1. Read from VS structure
//--  2. Process
//--  3. Write to PS structure
//-----------------------------------------------------------------------------
PSInput VertexShaderExample(VSInput VS)
{
    PSInput PS = (PSInput)0;
 
    PS.Position = MTACalcScreenPosition(VS.Position);
 
    PS.Diffuse = VS.Diffuse;
    PS.TexCoord = VS.TexCoord;
 
    return PS;
} 
 
//-----------------------------------------------------------------------------
//-- PixelShaderExample
//--  1. Read from PS structure
//--  2. Process
//--  3. Return pixel color
//-----------------------------------------------------------------------------
float4 PixelShaderExample(PSInput PS) : COLOR0
{	
	float BufferValue = FetchDepthBufferValue( PS.TexCoord.xy );
    float Depth = Linearize( BufferValue );
	Depth *= snowDepth;//0.008f;

	float4 color1 = tex2D(Sampler1, PS.TexCoord*3 + snowOffset1.xy);
	float4 color2 = tex2D(Sampler2, PS.TexCoord*5 + snowOffset2.xy);
	float4 color3 = tex2D(Sampler3, PS.TexCoord*7 + snowOffset3.xy);
	float4 color4 = float4(0.5f,0.5f,0.5f,1) * 0.25;
 
    float4 finalColor = (color1+color2+color3) * snowBright;
	finalColor += color4;
	
	finalColor.a *= Depth;
	
    return finalColor * PS.Diffuse;
}
 
 
//-----------------------------------------------------------------------------
//-- Techniques
//-----------------------------------------------------------------------------
 
//--
//-- MTA will try this technique first:
//--
technique complercated
{
    pass P0
    {
		AlphaBlendEnable = true; 
		//SrcBlend = One; 
		DestBlend = One;
		
        VertexShader = compile vs_2_0 VertexShaderExample();
        PixelShader  = compile ps_2_0 PixelShaderExample();
    }
}
 
//--
//-- And if the preceding technique will not validate on
//-- the players computer, MTA will try this one:
//--
technique simple
{
  
}